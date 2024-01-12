// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (governance/utils/Votes.sol)
pragma solidity ^0.8.20;

import {IERC6372} from '@openzeppelin/contracts/interfaces/IERC6372.sol';
import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {Nonces} from '@openzeppelin/contracts/utils/Nonces.sol';

import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';

import {Time} from '@openzeppelin/contracts/utils/types/Time.sol';

import {DelegateSet} from 'contracts/governance/utils/DelegateSet.sol';
import {IWonderVotes} from 'interfaces/governance/utils/IWonderVotes.sol';

/**
 * @dev This is a base abstract contract that tracks voting units, which are a measure of voting power that can be
 * transferred, and provides a system of vote delegation, where an account can delegate its voting units to a sort of
 * "representative" that will pool delegated voting units from different accounts and can then use it to vote in
 * decisions. In fact, voting units _must_ be delegated in order to count as actual votes, and an account has to
 * delegate those votes to itself if it wishes to participate in decisions and does not have a trusted representative.
 *
 * This contract is often combined with a token contract such that voting units correspond to token units. For an
 * example, see {ERC721Votes}.
 *
 * The full history of delegate votes is tracked on-chain so that governance protocols can consider votes as distributed
 * at a particular block number to protect against flash loans and double voting. The opt-in delegate system makes the
 * cost of this history tracking optional.
 *
 * When using this module the derived contract must implement {_getVotingUnits} (for example, make it return
 * {ERC721-balanceOf}), and can use {_transferVotingUnits} to track a change in the distribution of those units (in the
 * previous example, it would be included in {ERC721-_update}).
 */
abstract contract WonderVotes is Context, EIP712, Nonces, IERC6372, IWonderVotes {
  using DelegateSet for DelegateSet.Set;

  bytes32 private constant DELEGATION_TYPEHASH =
    keccak256('Delegation(uint8 proposalType, Delegate[] delegatees,uint256 nonce,uint256 expiry)');

  mapping(address account => mapping(uint8 proposalType => DelegateSet.Set)) private _delegatees;

  mapping(address delegatee => mapping(uint8 proposalType => uint256)) private _delegateVotingPower;

  mapping(address account => bool) private _nonDelegableAddresses;

  /**
   * @dev The clock was incorrectly modified.
   */
  error ERC6372InconsistentClock();

  /**
   * @dev Lookup to future votes is not available.
   */
  error ERC5805FutureLookup(uint256 timepoint, uint48 clock);

  /**
   * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based
   * checkpoints (and voting), in which case {CLOCK_MODE} should be overridden as well to match.
   */
  function clock() public view virtual returns (uint48) {
    return Time.blockNumber();
  }

  /**
   * @dev Machine-readable description of the clock as specified in EIP-6372.
   */
  // solhint-disable-next-line func-name-mixedcase
  function CLOCK_MODE() public view virtual returns (string memory) {
    // Check that the clock was not modified
    if (clock() != Time.blockNumber()) {
      revert ERC6372InconsistentClock();
    }
    return 'mode=blocknumber&from=default';
  }

  /**
   * @dev Returns the current amount of votes that `account` has for the given `proposalType`.
   */
  function getVotes(address account, uint8 proposalType) public view virtual returns (uint256) {
    return _delegateVotingPower[account][proposalType];
  }

  /**
   * @dev Returns the delegates that `account` has chosen.
   */
  function delegates(address account, uint8 proposalType) public view virtual returns (Delegate[] memory) {
    return _delegatees[account][proposalType].values();
  }

  /**
   * @dev Delegates votes from the sender to `delegatee`.
   */
  function delegate(
    Delegate[] calldata delegatees,
    uint8 proposalType
  ) public virtual validProposalType(proposalType) activeDelegates(delegatees) {
    address account = _msgSender();
    _delegate(account, proposalType, delegatees);
  }

  /**
   * @dev See {IWonderVotes-delegate}.
   */
  function delegate(
    address delegatee,
    uint8 proposalType
  ) public virtual validProposalType(proposalType) activeDelegate(delegatee) {
    address account = _msgSender();
    Delegate[] memory _singleDelegate = new Delegate[](1);
    _singleDelegate[0] = Delegate({account: delegatee, weight: _weightNormalizer()});
    _delegate(account, proposalType, _singleDelegate);
  }

  /**
   * @dev See {IWonderVotes-delegate}.
   */
  function delegate(address delegatee) public virtual activeDelegate(delegatee) {
    address account = _msgSender();
    Delegate[] memory _singleDelegate = new Delegate[](1);
    _singleDelegate[0] = Delegate({account: delegatee, weight: _weightNormalizer()});

    uint8[] memory proposalTypes = _getProposalTypes();

    for (uint256 i = 0; i < proposalTypes.length; i++) {
      _delegate(account, proposalTypes[i], _singleDelegate);
    }
  }

  /**
   * @dev See {IWonderVotes-weightNormalizer}.
   */
  function weightNormalizer() external view virtual returns (uint256) {
    return _weightNormalizer();
  }

  /**
   * @dev See {IWonderVotes-maxDelegates}.
   */
  function maxDelegates() external view returns (uint8) {
    return _maxDelegates();
  }

  /**
   * @dev Delegates votes from signer to `delegatee`.
   */
  function delegateBySig(
    Delegate[] memory delegatees,
    uint8 proposalType,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual validProposalType(proposalType) activeDelegates(delegatees) {
    if (block.timestamp > expiry) {
      revert VotesExpiredSignature(expiry);
    }
    address signer = ECDSA.recover(
      _hashTypedDataV4(keccak256(abi.encode(DELEGATION_TYPEHASH, proposalType, delegatees, nonce, expiry))), v, r, s
    );
    _useCheckedNonce(signer, nonce);
    _delegate(signer, proposalType, delegatees);
  }

  /**
   * @dev See {IWonderVotes-delegateBySig}.
   */
  function delegateBySig(
    address delegatee,
    uint8 proposalType,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual validProposalType(proposalType) activeDelegate(delegatee) {
    Delegate[] memory _singleDelegate = new Delegate[](1);
    _singleDelegate[0] = Delegate({account: delegatee, weight: _weightNormalizer()});
    delegateBySig(_singleDelegate, proposalType, nonce, expiry, v, r, s);
  }

  /**
   * @dev See {IWonderVotes-delegateBySig}.
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual activeDelegate(delegatee) {
    Delegate[] memory _singleDelegate = new Delegate[](1);
    _singleDelegate[0] = Delegate({account: delegatee, weight: _weightNormalizer()});

    uint8[] memory proposalTypes = _getProposalTypes();

    for (uint256 i = 0; i < proposalTypes.length; i++) {
      delegateBySig(_singleDelegate, proposalTypes[i], nonce, expiry, v, r, s);
    }
  }

  /**
   * @dev See {IWonderVotes-isDelegable}.
   */
  function isDelegable(address account) external view returns (bool) {
    return !_nonDelegableAddresses[account];
  }

  /**
   * @dev See {IWonderVotes-suspendDelegation}.
   */
  function suspendDelegation(bool suspend) external {
    _nonDelegableAddresses[msg.sender] = suspend;
    emit DelegateSuspended(msg.sender, suspend);
  }

  /**
   * @dev Delegate all of `account`'s voting units to `delegatee`.
   *
   * Emits events {IVotes-DelegateChanged} and {IVotes-DelegateVotesChanged}.
   */
  function _delegate(address account, uint8 proposalType, Delegate[] memory delegatees) internal virtual {
    if (delegatees.length > _maxDelegates()) revert VotesDelegatesMaxNumberExceeded(delegatees.length);

    uint256 _weightSum;
    for (uint256 i = 0; i < delegatees.length; i++) {
      if (delegatees[i].weight == 0) revert VotesZeroWeight();
      _weightSum += delegatees[i].weight;
    }
    if (_weightSum != _weightNormalizer()) revert VotesInvalidWeightSum(_weightSum);

    Delegate[] memory _oldDelegates = delegates(account, proposalType);

    if (_oldDelegates.length > 0) {
      _delegatees[account][proposalType].flush();
    }

    for (uint256 i = 0; i < delegatees.length; i++) {
      bool _result = _delegatees[account][proposalType].add(delegatees[i]);
      if (!_result) revert VotesDuplicatedDelegate(delegatees[i].account);
    }

    emit DelegateChanged(account, proposalType, _oldDelegates, delegatees);
    _moveDelegateVotes(proposalType, _oldDelegates, delegatees, _getVotingUnits(account));
  }

  /**
   * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
   * should be zero. Total supply of voting units will be adjusted with mints and burns.
   * Loops the proposalTypes implemented and calls the `_moveDelegateVotes` helper method.
   */
  function _transferVotingUnits(address from, address to, uint256 amount) internal virtual {
    uint8[] memory _proposalTypes = _getProposalTypes();

    for (uint256 _i = 0; _i < _proposalTypes.length; _i++) {
      uint8 _proposalType = _proposalTypes[_i];
      _moveDelegateVotes(_proposalType, delegates(from, _proposalType), delegates(to, _proposalType), amount);
    }
  }

  /**
   * @dev Moves delegated votes from one delegate to another.
   */
  function _moveDelegateVotes(uint8 proposalType, Delegate[] memory from, Delegate[] memory to, uint256 amount) private {
    uint256 _weightSum = _weightNormalizer();
    uint256 _weight;

    for (uint256 i = 0; i < from.length; i++) {
      if (from[i].account != address(0)) {
        _weight = from[i].weight;
        uint256 _votingUnits = amount * _weight / _weightSum;
        uint256 oldValue = _delegateVotingPower[from[i].account][proposalType];
        uint256 newValue = oldValue - _votingUnits;
        _delegateVotingPower[from[i].account][proposalType] = newValue;
        emit DelegateVotesChanged(from[i].account, proposalType, oldValue, newValue);
      }
    }

    for (uint256 i = 0; i < to.length; i++) {
      if (to[i].account != address(0)) {
        _weight = to[i].weight;
        uint256 _votingUnits = amount * _weight / _weightSum;
        uint256 oldValue = _delegateVotingPower[to[i].account][proposalType];
        uint256 newValue = oldValue + _votingUnits;
        _delegateVotingPower[to[i].account][proposalType] = newValue;
        emit DelegateVotesChanged(to[i].account, proposalType, oldValue, newValue);
      }
    }
  }

  function _add(uint208 a, uint208 b) private pure returns (uint208) {
    return a + b;
  }

  function _subtract(uint208 a, uint208 b) private pure returns (uint208) {
    return a - b;
  }

  /**
   * @dev Must return the voting units held by an account.
   */
  function _getVotingUnits(address) internal view virtual returns (uint256);

  /**
   * @dev Returns the total weight that each delegation should sum.
   */
  function _weightNormalizer() internal view virtual returns (uint256);

  /**
   * @dev Returns the types of proposals that are supported by the implementation.
   */
  function _getProposalTypes() internal view virtual returns (uint8[] memory);

  /**
   * @dev Returns the maximum number of delegates that `proposalType` can delegate to.
   */
  function _maxDelegates() internal view virtual returns (uint8);

  /**
   * @dev Returns true if the `proposalType` is valid, false otherwise.
   */
  function _validProposalType(uint8 proposalType) internal view virtual returns (bool);

  /**
   * @dev checks the `proposalType` validity
   */
  modifier validProposalType(uint8 proposalType) {
    if (!_validProposalType(proposalType)) revert VotesInvalidProposalType(proposalType);
    _;
  }

  /**
   * @dev checks if the delegation is active for the `delegatee`
   */
  modifier activeDelegate(address delegatee) {
    if (_nonDelegableAddresses[delegatee]) revert VotesDelegationSuspended(delegatee);
    _;
  }

  /**
   * @dev checks if the delegation is active for the `delegatees`
   */
  modifier activeDelegates(Delegate[] memory delegatees) {
    for (uint256 i = 0; i < delegatees.length; i++) {
      if (_nonDelegableAddresses[delegatees[i].account]) revert VotesDelegationSuspended(delegatees[i].account);
    }
    _;
  }
}

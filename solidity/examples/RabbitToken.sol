// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AliceGovernor} from './AliceGovernor.sol';

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {WonderERC20Votes} from 'contracts/governance/contracts/token/ERC20/extensions/WonderERC20Votes.sol';

contract RabbitToken is WonderERC20Votes {
  AliceGovernor public governor;
  address private _owner;

  constructor(AliceGovernor _governor) EIP712('RabbitToken', '1') ERC20('RabbitToken', 'RBT') {
    governor = _governor;
    _owner = msg.sender;
  }

  function _getProposalTypes() internal view virtual override returns (uint8[] memory) {
    return governor.proposalTypes();
  }

  function _maxDelegates() internal view virtual override returns (uint8) {
    return 4;
  }

  function _validProposalType(uint8 _proposalType) internal view virtual override returns (bool) {
    return governor.isValidProposalType(_proposalType);
  }

  function _weightNormalizer() internal view virtual override returns (uint256) {
    return 100;
  }

  function proposalTypes() external view returns (uint8[] memory) {
    return governor.proposalTypes();
  }

  function mint(address _account, uint256 _amount) external {
    _mint(_account, _amount);
  }

  // For testing purposes
  modifier onlyOwner() {
    if (msg.sender != _owner) revert Unauthorized();
    _;
  }

  error Unauthorized();
}

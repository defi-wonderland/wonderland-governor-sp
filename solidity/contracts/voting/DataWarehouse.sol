// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from '../libraries/Errors.sol';
import {IDataWarehouse} from './interfaces/IDataWarehouse.sol';
import {RLPReader} from './libs/RLPReader.sol';
import {StateProofVerifier} from './libs/StateProofVerifier.sol';

/**
 * Copied from AAVE https://github.com/aave/aave-v3-core and modified by Wonderland
 */
/**
 * @title DataWarehouse
 * @author BGD Labs
 * @notice This contract stores account state roots and allows proving against them
 */
contract DataWarehouse is IDataWarehouse {
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;

  // account address => (block hash => Account state root hash)
  mapping(address => mapping(bytes32 => bytes32)) internal _storageRoots;

  // account address => (block hash => (slot => slot value))
  mapping(address => mapping(bytes32 => mapping(bytes32 => uint256))) internal _slotsRegistered;

  function RABBIT() public pure virtual returns (address) {
    return 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9; // TODO: change to rabbit address
  }

  /// @inheritdoc IDataWarehouse
  function getStorageRoots(address account, bytes32 blockHash) public view returns (bytes32) {
    return _storageRoots[account][blockHash];
  }

  /// @inheritdoc IDataWarehouse
  function getRegisteredSlot(bytes32 blockHash, address account, bytes32 slot) external view returns (uint256) {
    return _slotsRegistered[account][blockHash][slot];
  }

  /// @inheritdoc IDataWarehouse
  function processStorageRoot(
    address account,
    bytes32 blockHash,
    bytes memory blockHeaderRLP,
    bytes memory accountStateProofRLP
  ) external returns (bytes32) {
    StateProofVerifier.BlockHeader memory decodedHeader =
      StateProofVerifier.verifyBlockHeader(blockHeaderRLP, blockHash);
    // The path for an account in the state trie is the hash of its address
    bytes32 proofPath = keccak256(abi.encodePacked(account));
    StateProofVerifier.Account memory accountData = StateProofVerifier.extractAccountFromProof(
      proofPath, decodedHeader.stateRootHash, accountStateProofRLP.toRlpItem().toList()
    );

    _storageRoots[account][blockHash] = accountData.storageRoot;

    emit StorageRootProcessed(msg.sender, account, blockHash);

    return accountData.storageRoot;
  }

  /// @inheritdoc IDataWarehouse
  function getStorage(
    address account,
    bytes32 blockHash,
    bytes32 slot,
    bytes memory storageProof
  ) public view returns (StateProofVerifier.SlotValue memory) {
    bytes32 root = _storageRoots[account][blockHash];
    require(root != bytes32(0), Errors.UNPROCESSED_STORAGE_ROOT);

    // The path for a storage value is the hash of its slot
    bytes32 proofPath = keccak256(abi.encodePacked(slot));
    StateProofVerifier.SlotValue memory slotData =
      StateProofVerifier.extractSlotValueFromProof(proofPath, root, storageProof.toRlpItem().toList());

    return slotData;
  }

  /// @inheritdoc IDataWarehouse
  function processStorageSlot(address account, bytes32 blockHash, bytes32 slot, bytes calldata storageProof) external {
    StateProofVerifier.SlotValue memory storageSlot = getStorage(account, blockHash, slot, storageProof);

    _slotsRegistered[account][blockHash][slot] = storageSlot.value;

    emit StorageSlotProcessed(msg.sender, account, blockHash, slot, storageSlot.value);
  }

  // @inheritdoc DataWarehouse
  function hasRequiredRoots(bytes32 blockHash) external view {
    require(getStorageRoots(RABBIT(), blockHash) != bytes32(0), Errors.MISSING_RABBIT_ROOTS);
  }
}

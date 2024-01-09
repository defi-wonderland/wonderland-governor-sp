// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Copied from AAVE https://github.com/aave/aave-v3-core and modified by Wonderland
 */
/**
 * @title IBaseVotingStrategy
 * @author BGD Labs
 * @notice interface containing the objects, events and method definitions of the BaseVotingStrategy contract
 */
interface IBaseVotingStrategy {
  /**
   * @notice object storing the information of the asset used for the voting strategy
   * @param storageSlots list of slots for the balance of the specified token.
   *           From that slot, by adding the address of the user, the correct balance can be taken.
   */
  struct VotingAssetConfig {
    uint128[] storageSlots;
  }

  /**
   * @notice emitted when an asset is added for the voting strategy
   * @param asset address of the token to be added
   * @param storageSlots array of storage positions of the balance mapping
   */
  event VotingAssetAdd(address indexed asset, uint128[] storageSlots);

  /**
   * @notice method to get the Rabbit token address
   * @return Rabbit token contract address
   */
  function RABBIT() external view returns (address);

  /**
   * @notice method to get the slot of the balance of the RABBIT
   * @return RABBIT base balance slot
   */
  function RABBIT_BASE_BALANCE_SLOT() external view returns (uint256);

  /**
   * @notice method to get the slot of the RABBIT token delegation state
   * @return RABBIT token delegation state slot
   */
  function RABBIT_DELEGATED_STATE_SLOT() external view returns (uint128);

  /**
   * @notice method to check if a token and slot combination is accepted
   * @param token address of the token to check
   * @param slot number of the token slot
   * @return flag indicating if the token slot is accepted
   */
  function isTokenSlotAccepted(address token, uint128 slot) external view returns (bool);

  /**
   * @notice method to get the addresses of the assets that can be used for voting
   * @return list of addresses of assets
   */
  function getVotingAssetList() external view returns (address[] memory);

  /**
   * @notice method to get the configuration for voting of an asset
   * @param asset address of the asset to get the configuration from
   * @return object with the asset configuration containing the list of storage slots
   */
  function getVotingAssetConfig(address asset) external view returns (VotingAssetConfig memory);
}

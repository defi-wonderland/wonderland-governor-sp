// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Copied from AAVE https://github.com/aave/aave-v3-core and modified by Wonderland
 */
/**
 * @title IGovernancePowerStrategy
 * @author BGD Labs
 * @notice interface containing the methods definitions of the GovernancePowerStrategy contract
 */
interface IGovernancePowerStrategy {
  /**
   * @notice method to get the full voting power of an user. This method is only use for consulting purposes.
   *            As its not used for voting calculations, it is not needed to force blockNumber - 1 to protect against
   *            FlashLoan attacks.
   * @param user address where we want to get the power from
   * @param proposalType type of the proposal
   * @return full voting power of a user
   */
  function getFullVotingPower(address user, uint8 proposalType) external view returns (uint256);

  /**
   * @notice method to get the full proposal power of an user. It is not needed to protect against FlashLoan
   *            attacks because once user returns the tokens (power) the proposal will get canceled as proposal creator
   *            will loose the proposition power.
   * @param user address where we want to get the power from
   * @param proposalType type of the proposal
   * @return full proposition power of a user
   */
  function getFullPropositionPower(address user, uint8 proposalType) external view returns (uint256);
}

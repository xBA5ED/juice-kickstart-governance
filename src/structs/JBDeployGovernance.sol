// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBToken.sol';

/**
 * @param governanceToken the token which will be used for voting, current project token if you wish to keep the current token or 0 address if you wish to deploy a new token 
 */
struct JBDeployGovernance {
    string governorName;
    uint256 votingDelay;
    uint256 votingPeriod;
    uint256 proposalThreshold;
    uint256 quoromFraction;
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBToken.sol';

/**
 * @param governanceToken the token which will be used for voting, current project token if you wish to keep the current token or 0 address if you wish to deploy a new token 
 * @param governanceTokenName only used if `governanceToken` is address 0, the name for the name token
 * @param governanceTokenSymbol only used if `governanceToken` is address 0, the symbol for the name token
 * @param skipInterfaceCheck should we skip the safety check to make sure the new token supports the needed interfaces (recommended: false)
 */
struct JBGovernanceTokenConfig {
    address governanceToken;

    string governanceTokenName;
    string governanceTokenSymbol;

    bool skipInterfaceCheck;
}
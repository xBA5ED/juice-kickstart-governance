// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./JBVoteToken.sol";
import "./interfaces/IJBVoteTokenDeployer.sol";

/**
 * Kickstarts new Juicebox projects by deploying everything needed for on-chain (token) governance
 */
contract JBVoteTokenDeployer is IJBVoteTokenDeployer {
    /** 
      @notice
      Deploys a ERC20 token that implements IVotes for onchain governance

      @param name the token name
      @param symbol the token symbol
      @param owner the address that receives ownership
      @return newDataSource The address of the newly deployed data source.
    */
    function deployVoteToken(
        string calldata name,
        string calldata symbol,
        address owner
    ) external override returns (address) {
        JBVoteToken _newToken = new JBVoteToken(name, symbol);

        _newToken.transferOwnership(owner);

        return address(_newToken);
    }
}

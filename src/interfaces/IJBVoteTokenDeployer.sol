// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBVoteTokenDeployer {
  function deployVoteToken(
        string calldata name,
        string calldata symbol,
        address owner
    ) external returns (address) ;
}

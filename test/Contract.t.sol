// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@jbx-protocol/contracts-v2/contracts/system_tests/helpers/TestBaseWorkflow.sol";
import "../src/JBGovernanceDeployer.sol";

contract ContractTest is TestBaseWorkflow {
    JBGovernanceDeployer public deployer;

    JBController controller;
    JBProjectMetadata _projectMetadata;
    JBFundingCycleData _data;
    JBFundingCycleMetadata _metadata;
    JBGroupedSplits[] _groupedSplits; // Default empty
    JBFundAccessConstraints[] _fundAccessConstraints; // Default empty
    IJBPaymentTerminal[] _terminals; // Default empty

    function setUp() public virtual override {
        super.setUp();
        controller = jbController();

        _projectMetadata = JBProjectMetadata({
            content: "myIPFSHash",
            domain: 1
        });

        _data = JBFundingCycleData({
            duration: 14,
            weight: 1000 * 10**18,
            discountRate: 450000000,
            ballot: IJBFundingCycleBallot(address(0))
        });

        _metadata = JBFundingCycleMetadata({
            global: JBGlobalFundingCycleMetadata({
                allowSetTerminals: false,
                allowSetController: false
            }),
            reservedRate: 5000, //50%
            redemptionRate: 5000, //50%
            ballotRedemptionRate: 0,
            pausePay: false,
            pauseDistributions: false,
            pauseRedeem: false,
            pauseBurn: false,
            allowMinting: false,
            allowChangeToken: true,
            allowTerminalMigration: false,
            allowControllerMigration: false,
            holdFees: false,
            useTotalOverflowForRedemptions: false,
            useDataSourceForPay: false,
            useDataSourceForRedeem: false,
            dataSource: address(0)
        });

        deployer = new JBGovernanceDeployer(jbController());
    }

    function testLaunchProject() public {
        deployer.launchProjectWithGovernance(
            JBLaunchProjectData({
                projectMetadata: _projectMetadata,
                data: _data,
                metadata: _metadata,
                mustStartAtOrAfter: 0,
                groupedSplits: _groupedSplits,
                fundAccessConstraints: _fundAccessConstraints,
                terminals: _terminals,
                memo: ""
            }),
            JBGovernanceTokenConfig({
                governanceToken: address(0),
                governanceTokenName: "TOKEN Project",
                governanceTokenSymbol: "SMBL",
                skipInterfaceCheck: false
            }),
            JBDeployGovernance({
                governorName: "Token's Governor",
                votingDelay: 1000,
                votingPeriod: 1024,
                proposalThreshold: 100e18,
                quoromFraction: 10
            })
        );

        assert(true);
    }
}

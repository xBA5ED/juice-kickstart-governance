// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@jbx-protocol/contracts-v2/contracts/interfaces/IJBController.sol";

import "./structs/JBDeployGovernance.sol";
import "./structs/JBLaunchProjectData.sol";
import "./structs/JBGovernanceTokenConfig.sol";
import "./governors/JBGovernor.sol";
import "./interfaces/IJBVoteTokenDeployer.sol";
import "./JBVoteToken.sol";

/**
 * Kickstarts new Juicebox projects by deploying everything needed for on-chain (token) governance
 */
contract JBGovernanceDeployer {
    /** 
        @notice
        The controller with which new projects should be deployed. 
    */
    IJBController public immutable controller;

     /** 
        @notice
        The contract that deployes VoteTokens
    */
    IJBVoteTokenDeployer public immutable tokenDeployer;

    constructor(
        IJBController _controller,
        IJBVoteTokenDeployer _tokenDeployer
    ){
        controller = _controller;
        tokenDeployer = _tokenDeployer;
    }

    /**
     * @notice
     * Create a new project configured with on-chain governance
     * 
     * @param _projectData the data regarding the Juicebox project
     * @param _tokenConfig the data regarding the governance token
     * @param _governanceConfig the data regarding governance settings
     */
    function launchProjectWithGovernance(
        JBLaunchProjectData calldata _projectData,
        JBGovernanceTokenConfig calldata _tokenConfig,
        JBDeployGovernance calldata _governanceConfig
    ) external {
        // Launch the project and make this contract the owner
        uint256 _projectId = _launchProjectFor(address(this), _projectData);
        return _setupGovernance(_projectId, _tokenConfig, _governanceConfig);
    }

    /**
     * @notice
     * Reconfigure an existing project to use on-chain governance
     * 
     * @param _projectId the project to reconfigure
     * @param _tokenConfig the data regarding the governance token
     * @param _governanceConfig the data regarding governance settings
     */
    function reconfigureProjectForGovernance(
        uint256 _projectId,
        JBGovernanceTokenConfig calldata _tokenConfig,
        JBDeployGovernance calldata _governanceConfig
    ) external {
        // Transfer ownership temporarily to this contract so we can configure it
        controller.projects().transferFrom(msg.sender, address(this), _projectId);
        return _setupGovernance(_projectId, _tokenConfig, _governanceConfig);
    }

    function _initGovernor(
        address _token,
        JBDeployGovernance calldata _governanceConfig
    ) internal returns (JBGovernor _governor) {
        return new JBGovernor(
            _governanceConfig.governorName,
            IVotes(_token),
            _governanceConfig.votingDelay,
            _governanceConfig.votingPeriod,
            _governanceConfig.proposalThreshold,
            _governanceConfig.quoromFraction
        );
    }


    function _setupGovernance(
        uint256 _projectId,
        JBGovernanceTokenConfig calldata _tokenConfig,
        JBDeployGovernance calldata _governanceConfig
    ) internal {
         // Prepare the (new) governance token
        (address _currentToken, address _newToken) = _prepareToken(_projectId, _tokenConfig);
        
        // TODO: Figure out if the tokenStore is able to mint new tokens
        
        // Deploy the governor
        JBGovernor _governor = _initGovernor(_newToken, _governanceConfig);

        // Change the projects token
        if(_currentToken != _newToken){
            _changeTokenTo(
                _projectId,
                _currentToken,
                _newToken,
                address(_governor)
            );
        }
        
        // Transfer ownership to the Governor
        controller.projects().transferFrom(address(this), address(_governor), _projectId);
    }

    /**
     * @notice
     * Configure a project to support on-chain governance
     * 
     * @param _projectId what project this is for
     * @param _tokenConfig the settings regarding the token
     * 
     * @return _currentToken the current token of the project
     * @return _newToken the new token of the project
     */
    function _prepareToken(
        uint256 _projectId,
        JBGovernanceTokenConfig calldata _tokenConfig
    ) internal returns (address _currentToken, address _newToken) {
        // Get the current configured token
        _currentToken = address(controller.tokenStore().tokenOf(_projectId));

        // Check if we should keep the current token
        if(_currentToken != address(0) && _currentToken == _tokenConfig.governanceToken){
            // Perform safety/sanity check to make sure the current token also supports IVotes
            // Otherwise the project may end up in an unrecoverable state
            if(
                !_tokenConfig.skipInterfaceCheck &&
                !ERC165Checker.supportsInterface(_currentToken, type(IVotes).interfaceId)
            ){
                // TODO: Replace with fancy error
                revert("CURRENT_TOKEN_UNSUPORTED");
            }
            
            return (_currentToken, _currentToken);
        }

        // If there is a new address passed to use as a governance token
        if(_tokenConfig.governanceToken != address(0)){
            // Perform safety/sanity check to make sure the token is supported by both JB and the Governor
            // Otherwise the project may end up in an unrecoverable state
            if(
                !_tokenConfig.skipInterfaceCheck &&
                (!ERC165Checker.supportsInterface(_tokenConfig.governanceToken, type(IJBToken).interfaceId) ||
                !ERC165Checker.supportsInterface(_tokenConfig.governanceToken, type(IVotes).interfaceId))
            ){
                // TODO: Replace with fancy error
                revert("TOKEN_UNSUPORTED");
            }

            return (_currentToken, _tokenConfig.governanceToken);
        }
        
        // Deploy a new token and transfer ownership to the tokenStore in preperation
        address _tokenStore = address(controller.tokenStore());
        _newToken = tokenDeployer.deployVoteToken(
            _tokenConfig.governanceTokenName,
            _tokenConfig.governanceTokenSymbol,
            _tokenStore
        );

        return (_currentToken, address(_newToken));
    }


    function _changeTokenTo(
        uint256 _projectId,
        address _oldToken,
        address _newToken,
        address _governor
    ) internal {
        controller.changeTokenOf(
            _projectId,
            IJBToken(_newToken),
            _governor
        );

        if(_oldToken != address(0)){
            // TODO: Configure migration terminal for the old token to the new token
        }
    }

    /** 
      @notice
      Launches a project.

      @param _owner The address to set as the owner of the project. The project ERC-721 will be owned by this address.
      @param _launchProjectData Data necessary to fulfill the transaction to launch the project.
    */
    function _launchProjectFor(
        address _owner,
        JBLaunchProjectData calldata _launchProjectData
    ) internal returns (uint256) {
        return controller.launchProjectFor(
            _owner,
            _launchProjectData.projectMetadata,
            _launchProjectData.data,
            _launchProjectData.metadata,
            _launchProjectData.mustStartAtOrAfter,
            _launchProjectData.groupedSplits,
            _launchProjectData.fundAccessConstraints,
            _launchProjectData.terminals,
            _launchProjectData.memo
        );
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        // TODO: Make this revert if its not the project we are configuring right now
        // that way a user can't accidentally transfer their project here

        return IERC721Receiver.onERC721Received.selector;
    }
}
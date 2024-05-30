

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {RogueGovernance} from "src/governance/RogueGovernance.sol";
import {RogueGovernanceToken} from "src/governance/GovernanceToken.sol";

contract GovernanceTest is Test {

    RogueGovernance private governance;
    RogueGovernanceToken private governanceToken;
    address private owner = address(0xa);

    function setUp() external {
        vm.startPrank(owner);
        governanceToken = new RogueGovernanceToken();
        governance = new RogueGovernance(address(governanceToken), address(0xb));
    }

    function testCreateProposal() external {
        string memory desc = "proposal to change the minimum proposal token balance";
        governance.createProposal(desc, 1000, 30 minutes, RogueGovernance.ExecutionType.Proposal_Staking_Amount);
        (uint id,string memory description,,,,,,,) = governance.proposals(1);
        console.log("here is the output", id);
        assertEq(governance.proposalCount(), 1);
        assertEq(description, desc);
    }

    function testChangeStakingAmount() external {
        assertEq(governance.allowedStakingTokenAmoount(), 0);
        governance.createProposal("", 1000, 30 minutes, RogueGovernance.ExecutionType.Proposal_Staking_Amount);
        governance.vote(1, RogueGovernance.Decision.For);
        vm.warp(1 hours);
        string memory response = governance.executeProposal(1);
        assertEq(response, "action performed");
        assertEq(governance.allowedStakingTokenAmoount(), 1000);
    }

    
}
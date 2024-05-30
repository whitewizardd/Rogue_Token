

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;
import {Test, console} from "forge-std/Test.sol";
import "src/governance/RogueGovernance.sol";
import "src/governance/GovernanceToken.sol";

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
        vm.startPrank(owner);

        governance.createProposal("proposal to change the minimum proposal token balance", 1000, 30 minutes, RogueGovernance.ExecutionType.Staking_Amount);
        // uint256 id;
        // string description;
        // uint256 newValue;
        // uint256 endTime;
        // Decision decision;
        // uint256 forVote;
        // uint256 againstVote;
        // uint256 abstainVote;
        // bool executed;
        // ExecutionType executionType;
        // mapping(address => bool) hasvoted;

        (,string memory desc,,,,,,,,) = governance.proposals(1);

        assertEq(desc, "proposal to change the minimum proposal token balance");
    }

}
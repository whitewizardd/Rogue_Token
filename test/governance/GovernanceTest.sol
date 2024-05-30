

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;
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
        // vm.startPrank(owner);

        governance.createProposal("proposal to change the minimum proposal token balance", 1000, 30 minutes, RogueGovernance.ExecutionType.Staking_Amount);

        (,,,,,,,,,,) = governance.proposals(1);
        console.log("here is the output","");
        // assertEq(governance.proposalCount, 1);
    }

}
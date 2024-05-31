

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {RogueStaking} from "src/Stake/RogueStake.sol";
import {RogueGovernance} from "src/governance/RogueGovernance.sol";
import {RogueGovernanceToken} from "src/governance/GovernanceToken.sol";

// link sepolia 0x779877A7B0D9E8603169DdbD7836e478b4624789
// link fuji 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846

// price feeds sepolia link/usd 0xc59E3633BAAC79493d908e63626716e204A45EdF
// price feeds fuji link/usd 0x34C4c526902d88a3Aa98DB8a9b802603EB1E3470

contract RogueStakeTest is Test {

    RogueStaking private staking;
    RogueGovernance private governance;
    RogueGovernanceToken private token;
    address private owner = address(0xaa);

    function setUp() external {
        vm.startPrank(owner);
        governance = new RogueGovernance(address(token));
        staking = new RogueStaking(
            address(token),
            address(governance),
            address(0xba),
            14,
            address(token),
            3
        );
    }

    function testCreateStake() external {

    }
}
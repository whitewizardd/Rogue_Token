

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {RogueStaking} from "src/Stake/RogueStake.sol";
import {RogueGovernance} from "src/governance/RogueGovernance.sol";
import {RogueGovernanceToken} from "src/governance/GovernanceToken.sol";


contract RogueStakeScript is Script {

    RogueStaking private staking;

    function run() external returns(RogueStaking) {
        vm.startBroadcast();
        RogueGovernanceToken governanceToken = new RogueGovernanceToken();
        RogueGovernance governance = new RogueGovernance(address(governanceToken));
        staking = new RogueStaking(
            0x779877A7B0D9E8603169DdbD7836e478b4624789,
            address(governance),
            0xc59E3633BAAC79493d908e63626716e204A45EdF,
            12,
            address(governanceToken),
            2
        );

        vm.stopBroadcast();
        return staking;
    }
}
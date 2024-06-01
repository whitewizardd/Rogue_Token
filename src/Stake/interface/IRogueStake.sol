// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

interface IRogueStake {
    function changeStakeAmount(uint256 amount) external;
    function changeWithdrawlRate(uint8 amount) external;
}

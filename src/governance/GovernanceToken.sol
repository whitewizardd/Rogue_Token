// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RogueGovernanceToken is ERC20("RogueGovernance", "RGT"), Ownable {
    constructor() Ownable(msg.sender) {
        _mint(msg.sender, 100_000_000_000_000);
    }
    // function
}

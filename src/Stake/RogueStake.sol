// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract RogueStaking is Ownable(msg.sender), AccessControl {
    bytes32 public constant governanceContract = bytes32("governance_only_contract");

    mapping(address => uint256) public stakes;
    IERC20 public stakingToken;
    AggregatorV3Interface public aggregatorInterface;

    uint public minimumStakeAmount;

    constructor(address _stakingContractAddress, address _governanceContract, address _feedsPrice) {
        stakingToken = IERC20(_stakingContractAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        aggregatorInterface = AggregatorV3Interface(_feedsPrice);
        _grantRole(governanceContract, _governanceContract);
    }

    function withdrawFunds() external onlyOwner {
        uint256 amount = stakes[address(this)];
    }

    function changeStakeAmount(uint amount) external onlyRole(governanceContract){
        require(amount > 0, "cannot set amount to zero");
        minimumStakeAmount = amount;
    }
}

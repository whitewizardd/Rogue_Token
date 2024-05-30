// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract RogueStaking is Ownable(msg.sender), AccessControl {
    bytes32 public constant governanceContract = bytes32("governance_only_contract");

    mapping(address => Stake[]) public stakes;
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    AggregatorV3Interface public aggregatorInterface;
    uint public rewardRate;
    uint public withdrawalFeeRate;

    uint public minimumStakeAmount;

    struct Stake {
        uint256 amount;
        uint256 usdValue;
        uint256 stakedAt;
        uint256 endedAt;
        bool closed;
    }

    event Staked(address indexed user, uint256 amount, uint256 usdValue);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event MinimumStakeAmountUpdated(uint256 newMinimumStakeAmountUSD);
    event RewardRateUpdated(uint256 newRewardRate);
    event FeeRatesUpdated(uint256 newStakingFeeRate, uint256 newWithdrawalFeeRate, uint256 newPerformanceFeeRate);

    constructor(address _stakingContractAddress, address _governanceContract, address _feedsPrice, uint _rewardRate, address _rewardToken, uint withdrawRate) {
        stakingToken = IERC20(_stakingContractAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        aggregatorInterface = AggregatorV3Interface(_feedsPrice);
        _grantRole(governanceContract, _governanceContract);
        rewardRate = _rewardRate;
        rewardToken = IERC20(_rewardToken);
        withdrawalFeeRate = withdrawRate;
    }

    function stake(uint256 amount) external {
        uint256 usdValue = getUsdValue(amount);
        require(usdValue >= minimumStakeAmount, "Cannot stake below the minimum USD value");

        stakingToken.transferFrom(msg.sender, address(this), amount);

        Stake memory staking;
        staking.amount = amount;
        staking.usdValue = usdValue;
        staking.stakedAt = block.timestamp;

        stakes[msg.sender].push(staking);

        emit Staked(msg.sender, amount, usdValue);
    }

    function withdraw(uint256 index) external {
        require(index < stakes[msg.sender].length, "Invalid stake index");

        Stake storage stakeInfo = stakes[msg.sender][index];
        require(!stakeInfo.closed, "already closed stake");
        uint256 reward = calculateReward(stakeInfo);

        // close the stake
        stakeInfo.closed = true;
        stakeInfo.endedAt = block.timestamp;

        // Apply withdrawal fee
        uint256 withdrawalFee = (stakeInfo.amount * withdrawalFeeRate) / 10000;
        uint256 netAmount = stakeInfo.amount - withdrawalFee;

        stakingToken.transfer(msg.sender, netAmount);
        rewardToken.transfer(msg.sender, reward);

        emit Withdrawn(msg.sender, netAmount, reward);
    }

    function getUsdValue(uint amount) private view returns (uint actual){
        (,int256 priceFeeds,,,) = aggregatorInterface.latestRoundData();
        uint decimalValue = aggregatorInterface.decimals();
        actual = (amount * uint(priceFeeds))/(10 ** decimalValue); 
    }

    function getUserStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    function calculateReward(Stake memory stakeInfo) internal view returns (uint256) {
        uint256 stakedDuration = block.timestamp - stakeInfo.stakedAt;
        uint256 reward = (stakeInfo.usdValue * rewardRate * stakedDuration) / 1e18;
        return reward;
    }

    function changeStakeAmount(uint amount) external onlyRole(governanceContract){
        require(amount > 0, "cannot set amount to zero");
        minimumStakeAmount = amount;
    }

    function getUserTotalStaked(address user) external view returns (uint256 totalStaked) {
        Stake[] memory userStakes = stakes[user]; 
        for (uint i = 0; i < userStakes.length; i++) {
            totalStaked += userStakes[i].usdValue;
        }
    }
}
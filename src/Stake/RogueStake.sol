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
    uint256 public rewardRate;
    uint8 public withdrawalFeeRate;

    uint256 public minimumStakeAmount;

    struct Stake {
        uint256 amount;
        uint256 usdValue;
        uint256 stakedAt;
        uint256 endedAt;
        uint256 rewardAmount;
        bool closed;
    }

    event Staked(address indexed user, uint256 amount, uint256 usdValue);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event MinimumStakeAmountUpdated(uint256 newMinimumStakeAmountUSD);
    event RewardRateUpdated(uint256 newRewardRate);
    event FeeRatesUpdated(uint256 newStakingFeeRate, uint256 newWithdrawalFeeRate, uint256 newPerformanceFeeRate);

    constructor(
        address _stakingContractAddress,
        address _governanceContract,
        address _feedsPrice,
        uint256 _rewardRate,
        address _rewardToken,
        uint8 withdrawRate
    ) {
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
        stakeInfo.rewardAmount = reward;

        // Apply withdrawal fee
        uint256 withdrawalFee = (stakeInfo.amount * withdrawalFeeRate) / 10000;
        uint256 netAmount = stakeInfo.amount - withdrawalFee;

        stakingToken.transfer(msg.sender, netAmount);
        stakingToken.transfer(owner(), withdrawalFee);
        rewardToken.transfer(msg.sender, reward);

        emit Withdrawn(msg.sender, netAmount, reward);
    }

    function getUsdValue(uint256 amount) private view returns (uint256 actual) {
        (, int256 priceFeeds,,,) = aggregatorInterface.latestRoundData();
        uint256 decimalValue = aggregatorInterface.decimals();
        actual = (amount * uint256(priceFeeds)) / (10 ** decimalValue);
    }

    function getUserStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    function calculateReward(Stake memory stakeInfo) internal view returns (uint256) {
        uint256 stakedDuration = block.timestamp - stakeInfo.stakedAt;
        uint256 reward = (stakeInfo.usdValue * rewardRate * stakedDuration) / 1e18;
        return reward;
    }

    function changeStakeAmount(uint256 amount) external onlyRole(governanceContract) {
        checkInput(amount);
        minimumStakeAmount = amount;
    }

    function changeWithdrawlRate(uint8 amount) external onlyRole(governanceContract){
        checkInput(amount);
        withdrawalFeeRate = amount;
    }

    function checkInput(uint256 amount) private pure {
        if (amount < 1) {
            revert("cannot set amount to zero");
        }
    }

    function getUserTotalStaked(address user) external view returns (uint256 totalStaked) {
        Stake[] memory userStakes = stakes[user];
        for (uint256 i = 0; i < userStakes.length; i++) {
            totalStaked += userStakes[i].usdValue;
        }
    }
}

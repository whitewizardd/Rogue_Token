// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "src/Stake/interface/IRogueStake.sol";

contract RogueGovernance {
    address public immutable governanceToken;
    IERC20 public iErc20;
    uint256 public proposalCount;
    uint256 public quorum;
    IRogueStake public iRogue;

    constructor(address _governanceToken, address _stakingContract) {
        governanceToken = _governanceToken;
        iErc20 = IERC20(_governanceToken);
        iRogue = IRogueStake(_stakingContract);
    }

    struct Proposal {
        uint256 id;
        string description;
        uint256 newValue;
        uint256 endTime;
        Decision decision;
        uint256 forVote;
        uint256 againstVote;
        bool executed;
        ExecutionType executionType;
    }

    enum Decision {
        Abstain,
        Against,
        For
    }

    enum ExecutionType {
        Proposal_Staking_Amount,
        Voting_Amount,
        Quorum,
        Staking_Amount,
        Withdrawal_Rate
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public allowedStakingTokenAmoount;
    uint256 public allowedTokenVotingBalance;
    mapping(uint => mapping(address => bool)) hasvoted;

    function createProposal(string memory desc, uint256 newValue, uint256 deadline, ExecutionType exeType) external {
        require(deadline > block.timestamp, "deadline must be greater than current time");
        require(
            iErc20.balanceOf(msg.sender) > allowedStakingTokenAmoount, "does not posses enough token to create proposal"
        );

        uint256 proposeCount = ++proposalCount;

        Proposal storage proposal = proposals[proposeCount];
        proposal.id = proposalCount;
        proposal.endTime = block.timestamp + deadline;
        proposal.description = desc;
        proposal.newValue = newValue;
        proposal.executionType = exeType;

        // should emit or do something.
    }

    function vote(uint256 proposalId, Decision decision) external {
        Proposal storage proposal = proposals[proposalId];

        require(!proposal.executed, "Already executed");
        require(proposal.endTime >= block.timestamp, "Already ended");
        require(iErc20.balanceOf(msg.sender) >= allowedTokenVotingBalance, "not enough  balance");
        require(!hasvoted[proposalId][msg.sender], "Already voted");

        if (decision == Decision.For) {
            proposal.forVote = proposal.forVote + 1;
        } else {
            proposal.againstVote = proposal.againstVote + 1;
        }

        hasvoted[proposalId][msg.sender] = true;

        // should emit or do something.
    }

    function changeTokenBalance(uint256 amount) private {
        allowedTokenVotingBalance = amount;
    }

    function changeStakingAmount(uint256 amount) private {
        allowedStakingTokenAmoount = amount;
    }

    function changeQuorum(uint256 amount) private {
        quorum = amount;
    }

    function executeProposal(uint256 proposalId) external returns (string memory) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Not ended");
        require(!proposal.executed, "Already executed");
        require(proposal.forVote + proposal.againstVote >= quorum, "Quorum not met");

        if (proposal.forVote > proposal.againstVote) {
            if (proposal.executionType == ExecutionType.Proposal_Staking_Amount) {
                changeStakingAmount(proposal.newValue);
            } else if (proposal.executionType == ExecutionType.Voting_Amount) {
                changeTokenBalance(proposal.newValue);
            } else if (proposal.executionType == ExecutionType.Quorum) {
                changeQuorum(proposal.newValue);
            } else if (proposal.executionType == ExecutionType.Staking_Amount) {
                iRogue.changeStakeAmount(proposal.newValue);
            } else if (proposal.executionType == ExecutionType.Withdrawal_Rate){
                iRogue.changeWithdrawlRate(uint8(proposal.newValue));
            }

            // emit something
            return "action performed";
        } else {
            return "cannot perform action, for the proposal not reached";
        }
        // should revert or do something
    }
}

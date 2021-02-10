// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/IERC20.sol";

contract GovernorAlpha {
  /// @notice The name of this contract
  string public constant name = "Hedge Tech Governor Alpha";

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() public pure returns (uint256) { return 4000e18; } // 4,000 = 4% of HTG

  /// @notice The number of votes required in order for a voter to become a proposer
  function proposalThreshold() public pure returns (uint256) { return 1000e18; } // 1,000 = 1% of HTG

  /// @notice The delay before voting on a proposal may take place, once proposed
  function votingDelay() public pure returns (uint256) { return 1; } // 1 block

  /// @notice The duration of voting on a proposal, in blocks
  function votingPeriod() public pure returns (uint256) { return 17280; } // ~3 days in blocks (assuming 15s blocks)

  /// @notice The address of the Compound governance token
  IERC20 public htg;

  /// @notice The total number of proposals
  uint256 public proposalCount;

  struct Proposal {
    // Unique id for looking up a proposal
    uint256 id;

    // Creator of the proposal
    address proposer;

    // The block at which voting begins: holders must delegate their votes prior to this block
    uint256 startBlock;

    // The block at which voting ends: votes must be cast prior to this block
    uint256 endBlock;

    // Current number of votes in favor of this proposal
    uint256 forVotes;

    // Current number of votes in opposition to this proposal
    uint256 againstVotes;

    // Flag marking whether the proposal has been canceled
    bool canceled;

    // Raw votes (without rooting) given to this proposal
    uint256 rawVotes;

    // Receipts of ballots for the entire set of voters
    mapping (address => Receipt) receipts;
  }

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    // Whether or not a vote has been cast
    bool hasVoted;

    // Whether or not the voter supports the proposal
    bool support;

    // The number of votes the voter had, which were cast
    uint256 votes;
  }

  /// @notice Possible states that a proposal may be in
  enum ProposalState {
    Pending,
    Canceled,
    Defeated,
    Succeeded,
    Active
  }

  /// @notice The official record of all proposals ever proposed
  mapping (uint256 => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping (address => uint256) public latestProposalIds;

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(uint256 id, address proposer, uint256 startBlock, uint256 endBlock, string description);

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 id);

  constructor(address htg_) public {
    htg = IERC20(htg_);
    proposalCount = 0;
  }

  function propose (string memory description) public returns (uint256) {
    address _proposer = msg.sender;
    uint256 _startBlock = block.number;
    uint256 _endBlock = _startBlock + votingPeriod();
    uint256 _id = proposalCount;

    Proposal memory newProposal = Proposal({
      id: _id,
      proposer: _proposer,
      startBlock: _startBlock,
      endBlock: _endBlock,
      forVotes: 0,
      againstVotes: 0,
      rawVotes: 0,
      canceled: false
    });

    proposals[_id] = newProposal;
    proposalCount++;

    emit ProposalCreated(_id, _proposer, _startBlock, _endBlock, description);
    return newProposal.id;
  }

  function cancel(uint256 proposalId) public {
    ProposalState state = state(proposalId);
    require(state != ProposalState.Succeeded, "GovernorAlpha::cancel: cannot cancel succeeded proposal");

    Proposal storage proposal = proposals[proposalId];
    address _proposer = proposal.proposer;
    require(_proposer == msg.sender, "GovernorAlpha::cancel: proposal can only be cancelled by proposer");

    proposal.canceled = true;
    
    emit ProposalCanceled(proposalId);
  }


  function vote(uint256 proposalId, bool support) public {
    address _voter = msg.sender;
    uint256 _rawVotes = htg.balanceOf(_voter);
    uint256 _votes = sqrt(_rawVotes);
    
    Proposal storage _proposal = proposals[proposalId];
    Receipt storage _receipt = _proposal.receipts[_voter];
    require(_receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");

    if (support) {
      _proposal.forVotes = add(_proposal.forVotes, _votes);
    } else {
      _proposal.againstVotes = add(_proposal.againstVotes, _votes);
    }

    _proposal.rawVotes = add(_proposal.rawVotes, _rawVotes);

    _receipt.hasVoted = true;
    _receipt.support = support;
    _receipt.votes = _votes;

    emit VoteCast(_voter, proposalId, support, _votes);
  }

  function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
    return proposals[proposalId].receipts[voter];
  }

  function state(uint256 proposalId) public view returns (ProposalState) {
    require(proposalCount >= proposalId && proposalId >= 0, "GovernorAlpha::state: invalid proposal id");
    
    Proposal storage proposal = proposals[proposalId];
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.number <= proposal.startBlock) {
      return ProposalState.Pending;
    } else if (block.number <= proposal.endBlock) {
      return ProposalState.Active;
    } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
      return ProposalState.Defeated;
    } else if (proposal.forVotes >= proposal.againstVotes && proposal.forVotes >= quorumVotes()) {
      return ProposalState.Succeeded;
    }
  }

  
  // Sqrt
  function sqrt(uint256 x) internal pure returns (uint256 y) {
    uint256 z = div(add(x, 1), 2);
    y = x;
    while (z < y) {
      y = z;
      z = div(add(div(x, z), z), 2);
    }
  }
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }
    
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }


  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }


}
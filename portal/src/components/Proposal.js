import React, {Component} from 'react';

import upvote from '../images/upvote.svg';
import downvote from '../images/downvote.svg';

import '../layout/components/proposals.sass';

class Proposal extends Component {
  constructor(props) {
    super(props);

    this.state = {
      proposalState: ""
    }
  }

  async componentDidMount() {
    // setInterval(() => {
    await this.getProposals();
    // }, 2000);
  }

  getState = (stateId) => {
    if (stateId === 0) {
      return "Pending";
    } else if (stateId === 1) {
      return "Cancelled";
    } else if (stateId === 2) {
      return "Defeated";
    } else if (stateId === 3) {
      return "Succeeded";
    } else if (stateId === 4) {
      return "Active";
    }
  }

  getProposals = async () => {
    if(this.props.network === 'Mainnet') {
      this.props.xhr(
        "https://api-hedgetech.herokuapp.com/mainnet/proposal/" + this.props.id + "/state/", 
      (res) => {
        const data = JSON.parse(res);
        if(this.state.proposals !== data) {
          const _proposalState = this.getState(data);
          this.setState({proposalState: _proposalState});
        }
      });
    } else if(this.props.network === 'Rinkeby') {
      this.props.xhr(
        "https://api-hedgetech.herokuapp.com/rinkeby/proposal/" + this.props.id + "/state/", 
      (res) => {
        const data = JSON.parse(res);
        if(this.state.proposals !== data) {
          const _proposalState = this.getState(data);
          this.setState({proposalState: _proposalState});
        }
      });
    } else {
      // Default to Mainnet
      this.props.xhr(
        "https://api-hedgetech.herokuapp.com/mainnet/proposal/" + this.props.id + "/state/", 
      (res) => {
        const data = JSON.parse(res);
        if(this.state.proposals !== data) {
          const _proposalState = this.getState(data);
          this.setState({proposalState: _proposalState});
        }
      });
    }
  }

  handleVoteFor = () => {
    this.props.contract.methods.vote(this.props.id, true)
      .send({from: this.props.account}, (err, transactionHash) => {
        this.props.setMessage('Transaction Pending...', transactionHash);
      }).on('confirmation', (number, receipt) => {
        if(number === 0) {
          this.props.setMessage('Transaction Confirmed!', receipt.transactionHash);
        }
        setTimeout(() => {
          this.props.clearMessage();
        }, 5000);
      }).on('error', (err, receipt) => {
        this.props.setMessage('Transaction Failed.', receipt ? receipt.transactionHash : null);
      });
  }

  handleVoteAgainst = () => {
    this.props.contract.methods.vote(this.props.id, false)
      .send({from: this.props.account}, (err, transactionHash) => {
        this.props.setMessage('Transaction Pending...', transactionHash);
      }).on('confirmation', (number, receipt) => {
        if(number === 0) {
          this.props.setMessage('Transaction Confirmed!', receipt.transactionHash);
        }
        setTimeout(() => {
          this.props.clearMessage();
        }, 5000);
      }).on('error', (err, receipt) => {
        this.props.setMessage('Transaction Failed.', receipt ? receipt.transactionHash : null);
      });
  }

  render() {
    let arrows;
    
    if(this.props.account && parseInt(this.props.end) > this.props.latestBlock) {
      arrows = 
        <div className="proposal__arrows">
          <img 
            src={upvote} 
            alt="Vote for" 
            className="proposal__arrow"
            onClick={this.handleVoteFor}
          />
          <img 
            src={downvote} 
            alt="Vote against" 
            className="proposal__arrow" 
            onClick={this.handleVoteAgainst}
          />
        </div>;
    }
    
    return (
      <div className="proposal">
        <h4 className="proposal__title">
          {this.props.title}
        </h4>
        <div className="proposal__bottom">
          {arrows}
          <p className="proposal__description">
            {this.props.description}
          </p>

        </div>
        <div className="proposal__state">
          <h5> {this.state.proposalState} </h5>
        </div>
      </div>
    );
  }
}

export default Proposal;
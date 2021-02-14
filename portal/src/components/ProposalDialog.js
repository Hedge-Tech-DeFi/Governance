import React, {Component} from 'react';

import '../layout/components/proposals.sass';

class ProposalDialog extends Component {
  constructor(props) {
    super(props);

    this.state = {
      description: ""
    }

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleChange(event) {
    this.setState({description: event.target.value});
  }

  handleSubmit(event) {}

  handlePropose = () => {
    this.props.contract.methods.propose(this.state.description)
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
    return (
      <div className="proposal">
        <h4 className="proposal__title">
          {this.props.title}
        </h4>
        <div className="proposal__bottom">
          <textarea type="text" value={this.state.description} className="proposal__input" onChange={this.handleChange}/>
        </div>
        <div className="proposal__state">
          <h5 onClick={this.handlePropose}> Submit </h5>
        </div>
      </div>
    );
  }
}

export default ProposalDialog;
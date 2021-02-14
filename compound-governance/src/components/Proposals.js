import React, {Component} from 'react';

import Proposal from './Proposal';

import '../layout/components/proposals.sass';
import ProposalDialog from './ProposalDialog';

class Proposals extends Component {
  constructor(props) {
    super(props);

    this.state = {
      proposals: []
    }
  }

  componentDidMount = () => {
    setInterval(() => {
      this.getProposals();
    }, 2000);
  }

  getProposals = async () => {
    if(this.props.network === 'Mainnet') {
      this.props.xhr(
        "http://localhost:8000/mainnet/proposals/", 
      (res) => {
        const data = JSON.parse(res);
        if(this.state.proposals !== data.proposals) {
          this.setState({proposals: data.proposals});
        }
      });
    } else if(this.props.network === 'Rinkeby') {
      this.props.xhr(
        "http://localhost:8000/rinkeby/proposals/", 
      (res) => {
        const data = JSON.parse(res);
        if(this.state.proposals !== data) {
          this.setState({proposals: data});
        }
      });
    } else {
      // Default to Rinkeby for now
      // TODO: Default to mainnet once it's populated with proposals
      this.props.xhr(
        "http://localhost:8000/rinkeby/proposals/", 
      (res) => {
        const data = JSON.parse(res);
        if(this.state.proposals !== data) {
          this.setState({proposals: data});
        }
      });
    }
  }

  render() {
    let proposals = [];



    this.state.proposals.forEach(proposal => {
      if(proposal.title.length > 0) {
        proposals.push(
          <Proposal
            title={proposal.title}
            description={proposal.description} 
            key={proposal.id}
            id={proposal.id}
            end={proposal.endBlock}
            {...this.props}
          />
        );
      } 
    });

    proposals.push(
      <ProposalDialog
        title={"Add Proposal"}
        description={""} 
        key={-1}
        id={-1}
        end={0}
        {...this.props}
      />
    );

    return (
      <section className="proposals">
        {proposals.reverse()}
      </section>
    );
  }
}

export default Proposals;
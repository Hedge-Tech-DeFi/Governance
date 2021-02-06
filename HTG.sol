pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/ERC20.sol";

contract HTG is ERC20 {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor () public ERC20("Hedge Tech Governance", "HTG") {
        owner = msg.sender;
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
    
}

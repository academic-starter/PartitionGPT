// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract EncryptedERC20 is Ownable2Step {
    event Transfer(address indexed from, address indexed to, uint64 amount);
    event Approval(address indexed owner, address indexed spender, uint64 amount);
    event Mint(address indexed to, uint64 amount);

    uint64 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 public constant decimals = 6;

    // A mapping from address to an encrypted balance.
    mapping(address => uint64) internal balances;

    // A mapping of the form mapping(owner => mapping(spender => allowance)).
    mapping(address => mapping(address => uint64)) internal allowances;

    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) {
        _name = name_;
        _symbol = symbol_;
    }

    // Returns the name of the token.
    function name() public view virtual returns (string memory) {
        return _name;
    }

    // Returns the symbol of the token, usually a shorter version of the name.
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    // Returns the total supply of the token
    function totalSupply() public view virtual returns (uint64) {
        return _totalSupply;
    }

    // Sets the balance of the owner to the given encrypted balance.
    function mint(uint64 mintedAmount) public virtual onlyOwner {
        balances[owner()] = balances[owner()] + mintedAmount; // overflow impossible because of next line
        _totalSupply = _totalSupply + mintedAmount;
        emit Mint(owner(), mintedAmount);
    }

    // Transfers an encrypted amount from the message sender address to the `to` address.
    function transfer(address to, uint64 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    // Returns the balance handle of the caller.
    function balanceOf(address wallet) public view virtual returns (uint64) {
        return balances[wallet];
    }

    // Sets the `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint64 amount) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        emit Approval(owner, spender, amount);
        return true;
    }

    // Returns the remaining number of tokens that `spender` is allowed to spend
    // on behalf of the caller.
    function allowance(address owner, address spender) public view virtual returns (uint64) {
        return _allowance(owner, spender);
    }

    // Transfers `amount` tokens using the caller's allowance.
    function transferFrom(address from, address to, uint64 amount) public virtual returns (bool) {
        address spender = msg.sender;
        bool isTransferable = _updateAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint64 amount) internal virtual {
        allowances[owner][spender] = amount;
    }

    function _allowance(address owner, address spender) internal view virtual returns (uint64) {
        return allowances[owner][spender];
    }

    function _updateAllowance(address owner, address spender, uint64 amount) internal virtual returns (bool) {
        uint64 currentAllowance = _allowance(owner, spender);
        bool canApprove = amount <= currentAllowance;
        if (canApprove) {
            _approve(owner, spender, currentAllowance - amount);
        }else{
            _approve(owner, spender, 0);
        }
        return canApprove;
    }

    // Transfers an encrypted amount.
    function _transfer(address from, address to, uint64 amount) internal virtual {
         // Make sure the sender has enough tokens.
        bool isTransferable = amount <= balances[from];

        // Add to the balance of `to` and subract from the balance of `from`.
        if (isTransferable){
            balances[to] = balances[to] + amount;
            balances[from] = balances[from] - amount;
            emit Transfer(from, to, amount); // Comp.sol (TFHE) has a bug, fake Transfer event will be emitted.
        }
    
    }
}

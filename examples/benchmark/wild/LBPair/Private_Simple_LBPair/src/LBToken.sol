pragma solidity 0.8.10;

contract LBToken is ILBToken {

    mapping(address => mapping(uint256 => uint256)) private _balances;
    mapping(uint256 => uint256) private _totalSupplies;
    mapping(address => mapping(address => bool)) private _spenderApprovals;
    modifier checkApproval(address from, address spender) {
        if (!_isApprovedForAll(from, spender)) revert LBToken__SpenderNotApproved(from, spender);
        _;
    }
}
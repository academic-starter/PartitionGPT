pragma solidity 0.8.10;

contract LBToken is ILBToken {

    mapping(address => mapping(uint256 => uint256)) private _balances;
    mapping(uint256 => uint256) private _totalSupplies;
    mapping(address => mapping(address => bool)) private _spenderApprovals;
    modifier checkApproval(address from, address spender) {
        if (!_isApprovedForAll(from, spender)) revert LBToken__SpenderNotApproved(from, spender);
        _;
    }
    function name() public view virtual override returns (string memory) {
        return "Liquidity Book Token";
    }
    function symbol() public view virtual override returns (string memory) {
        return "LBT";
    }
    function totalSupply(uint256 id) public view virtual override returns (uint256) {
        return _totalSupplies[id];
    }
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        return _balances[account][id];
    }
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        public
        view
        virtual
        override
        checkLength(accounts.length, ids.length)
        returns (uint256[] memory batchBalances)
    {
        batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; ++i) {
                batchBalances[i] = balanceOf(accounts[i], ids[i]);
            }
        }
    }
    function isApprovedForAll(address owner, address spender) public view virtual override returns (bool) {
        return _isApprovedForAll(owner, spender);
    }
    function approveForAll(address spender, bool approved) public virtual override {
        _approveForAll(msg.sender, spender, approved);
    }
    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts)
        public
        virtual
        override
        checkApproval(from, msg.sender)
    {
        _batchTransferFrom(from, to, ids, amounts);
    }
    function _isApprovedForAll(address owner, address spender) internal view returns (bool) {
        return owner == spender || _spenderApprovals[owner][spender];
    }
    function _mint(address account, uint256 id, uint256 amount) internal {
        _totalSupplies[id] += amount;

        unchecked {
            _balances[account][id] += amount;
        }
    }
    function _burn(address account, uint256 id, uint256 amount) internal {
        mapping(uint256 => uint256) storage accountBalances = _balances[account];

        uint256 balance = accountBalances[id];
        if (balance < amount) revert LBToken__BurnExceedsBalance(account, id, amount);

        unchecked {
            _totalSupplies[id] -= amount;
            accountBalances[id] = balance - amount;
        }
    }
    function _batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts)
        internal
        checkLength(ids.length, amounts.length)
        notAddressZeroOrThis(to)
    {
        mapping(uint256 => uint256) storage fromBalances = _balances[from];
        mapping(uint256 => uint256) storage toBalances = _balances[to];

        for (uint256 i; i < ids.length;) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = fromBalances[id];
            if (fromBalance < amount) revert LBToken__TransferExceedsBalance(from, id, amount);

            unchecked {
                fromBalances[id] = fromBalance - amount;
                toBalances[id] += amount;

                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }
    function _approveForAll(address owner, address spender, bool approved) internal notAddressZeroOrThis(owner) {
        if (owner == spender) revert LBToken__SelfApproval(owner);

        _spenderApprovals[owner][spender] = approved;
        emit ApprovalForAll(owner, spender, approved);
    }
}
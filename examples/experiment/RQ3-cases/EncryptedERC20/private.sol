pragma solidity 0.8.0;
contract EncryptedERC20 {
    event Transfer(address indexed from, address indexed to, uint64 amount);
    event Approval(address indexed owner, address indexed spender, uint64 amount);
    event Mint(address indexed to, uint64 amount);

    // A mapping from address to an encrypted balance.
    mapping(address => uint64) internal balances;

    // A mapping of the form mapping(owner => mapping(spender => allowance)).
    mapping(address => mapping(address => uint64)) internal allowances; 
    
    event TransferMessagePassing(address indexed sender, address indexed to, uint64 amount);
    event BalanceOfMessagePassing(uint64 amount);
    event ApproveMessagePassing(address owner, address spender, uint64 amount);
    event AllowanceMessagePassing(uint64 amount);
    event TransformMessagePassing(address indexed sender, address indexed to, uint64 amount);

    constructor(string memory name_, string memory symbol_) {
    }

    function mint(address user, uint64 mintedAmount) external virtual {
        balances[user] = balances[user] + mintedAmount; // overflow impossible because of next line
    }

    function transfer(address sender, address to, uint64 amount) external virtual  {
        _transfer(sender, to, amount);
        emit TransferMessagePassing(sender, to, amount);
    }

    function balanceOf(address wallet) external virtual  {
        emit BalanceOfMessagePassing(balances[wallet]);
    }

    function approve(address owner, address spender, uint64 amount) external virtual {
        _approve(owner, spender, amount);
        emit ApproveMessagePassing(owner, spender, amount);
    }


    // Returns the remaining number of tokens that `spender` is allowed to spend
    // on behalf of the caller.
    function allowance(address owner, address spender) public virtual {
        uint64 amt = _allowance(owner, spender);
        emit AllowanceMessagePassing(amt);
    }

    function transferFrom(address from, address to, address spender, uint64 amount) external virtual {
        bool isTransferable = _updateAllowance(from, spender, amount);
        if (isTransferable) 
            _transfer(from, to, amount);
        emit TransformMessagePassing(from, to, amount);
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
pragma solidity 0.8.25;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

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
        mint_priv(mintedAmount);
        _totalSupply = _totalSupply + mintedAmount;
        emit Mint(owner(), mintedAmount);
    }

    function mint_priv(uint64 mintedAmount) internal virtual {
        balances[owner()] = balances[owner()] + mintedAmount; // overflow impossible because of next line
    }

    // Transfers an encrypted amount from the message sender address to the `to` address.
    function transfer(address to, uint64 amount) public virtual returns (bool) {
        transfer_priv(msg.sender, to, amount);
        return true;
    }

    function transfer_priv(address sender, address to, uint64 amount) public virtual returns (bool) {
        _transfer(sender, to, amount);
    }

    // Returns the balance handle of the caller.
    function balanceOf(address wallet) public view virtual returns (uint64) {
        uint64 bal =  balanceOf_priv(wallet);
        return balanceOf_callback(bal);
    }

    function balanceOf_priv(address wallet) public view virtual returns (uint64) {
        return balances[wallet];
    }

    function balanceOf_callback(uint64 bal) public view virtual returns (uint64) {
        return bal;
    }

    // Sets the `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint64 amount) public virtual returns (bool) {
        address owner = msg.sender;
        approve_priv(owner, spender, amount);
        return true;
    }

    function approve_priv(address owner, address spender, uint64 amount) internal virtual returns (bool) {
        _approve(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }



    // Returns the remaining number of tokens that `spender` is allowed to spend
    // on behalf of the caller.
    function allowance(address owner, address spender) public view virtual returns (uint64) {
        require(msg.sender == owner || msg.sender == spender);
        uint64 amt = allowance_priv(owner, spender);
        return allowance_callback(amt);
    }

    function allowance_priv(address owner, address spender) public view virtual returns (uint64) {
        uint64 amt = _allowance(owner, spender);
        return amt;
    }

    function allowance_callback(uint64 amt) public view virtual returns (uint64) {
        return amt;
    }

    // Transfers `amount` tokens using the caller's allowance.
    function transferFrom(address from, address to, uint64 amount) public virtual returns (bool) {
        address spender = msg.sender;
        transferFrom_priv(from, to, spender, amount);
        return true;
    }
    
    function transferFrom_priv(address from, address to, address spender, uint64 amount) public virtual returns (bool) {
        bool isTransferable = _updateAllowance(from, spender, amount);
        if (isTransferable) 
            _transfer(from, to, amount);
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
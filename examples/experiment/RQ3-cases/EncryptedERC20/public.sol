pragma solidity 0.8.0;
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
    // error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    // error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert();// OwnableInvalidOwner(address(0));
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
            revert(); //OwnableUnauthorizedAccount(_msgSender());
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
            revert();// OwnableInvalidOwner(address(0));
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
            revert();// OwnableUnauthorizedAccount(sender);
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

    event MintMessagePassing(address user, uint mintedAmount);
    event TransferMessagePassing(address indexed sender, address indexed to, uint64 amount);
    event TransferSuccess(address indexed sender, address indexed to, uint64 amount);
    event BalanceOfMessagePassing(address indexed wallet);
    event BalanceOfWallet(uint64 amount);
    event ApproveMessagePassing(address owner, address spender, uint64 amount);
    event AllowanceMessagePassing(address owner, address spender);
    event Allowance(uint64 amount);
    event TransformMessagePassing(address from, address to, address spender, uint64 amount);


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
        _totalSupply = _totalSupply + mintedAmount;
        emit Mint(owner(), mintedAmount);
        emit MintMessagePassing(owner(), mintedAmount);
    }

    // Transfers an encrypted amount from the message sender address to the `to` address.
    function transfer(address to, uint64 amount) public virtual {
        emit TransferMessagePassing(msg.sender, to, amount);
    }

    function transfer_callback(address sender, address to, uint64 amount) external {
        emit TransferSuccess(sender, to, amount);
    }

    // Returns the balance handle of the caller.
    function balanceOf(address wallet) public virtual {
        emit BalanceOfMessagePassing(wallet);
    }

    function balanceOf_callback(uint64 bal) public virtual {
        emit BalanceOfWallet(bal);
    }

    // Sets the `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint64 amount) public virtual {
        address owner = msg.sender;
        emit ApproveMessagePassing(owner, spender, amount);
    }
    function approve_callback(address owner, address spender, uint64 amount) external {
        emit Approval(owner, spender, amount);
    }

    // Returns the remaining number of tokens that `spender` is allowed to spend
    // on behalf of the caller.
    function allowance(address owner, address spender) public virtual {
        require(msg.sender == owner || msg.sender == spender);
        emit AllowanceMessagePassing(owner, spender);
    }

    function allowance_callback(uint64 amt) public virtual {
        emit Allowance(amt);
    }

    // Transfers `amount` tokens using the caller's allowance.
    function transferFrom(address from, address to, uint64 amount) public virtual {
        address spender = msg.sender;
        emit TransformMessagePassing(from, to, spender, amount);
    }
    
    function transferFrom_callback(address sender, address to, uint64 amount) external {
        emit TransferSuccess(sender, to, amount);
    }
    
}
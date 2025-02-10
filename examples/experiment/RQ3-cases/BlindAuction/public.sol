pragma solidity 0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns(uint256) {
        return 0;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // error OwnableUnauthorizedAccount(address account);
    // error OwnableInvalidOwner(address owner);

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert();// OwnableUnauthorizedAccount(_msgSender());
        }
    }


    function owner() public view virtual returns(address) {
        return _owner;
    }


    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert();// OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


    function transferOwnership(address newOwner) public virtual
    onlyOwner {
        if (newOwner == address(0)) {
            revert();// OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }


    function renounceOwnership() public virtual
    onlyOwner {
        _transferOwnership(address(0));
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }
}
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    function pendingOwner() public view virtual returns(address) {
        return _pendingOwner;
    }


    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert();// OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }


    function transferOwnership(address newOwner) public virtual override
    onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

}
contract BlindAuction is Ownable2Step {
    uint256 public endTime;
    address public beneficiary;
    uint256 public bidCounter;
    bool private objectClaimed;
    bool public tokenTransferred;
    bool public stoppable;
    bool public manuallyStopped = false;


    // error TooEarly(uint256 time);
    // error TooLate(uint256 time);

    event BidMessagePassing(address indexed to, uint value);
    event GetBidMessagePassing(address indexed account);
    event BidAmount(uint value);

    event ClaimMessagePassing(address indexed user);
    event WithdrawMessagePassing(address indexed user);

    constructor(
        address _beneficiary,
        uint256 biddingTime,
        bool isStoppable
    )
    Ownable(msg.sender) {
        beneficiary = _beneficiary;
        endTime = block.timestamp + biddingTime;
        objectClaimed = false;
        tokenTransferred = false;
        bidCounter = 0;
        stoppable = isStoppable;
    }


    function bid(uint64 value) external
    onlyBeforeEnd {
        emit BidMessagePassing(msg.sender, value); // this message will be sent to invoke "bid" function of private contract
    }

    // this function will be called back from private contract
    function bid_callback(bool increment) external
    {
        if (increment) {
            bidCounter++;
        }
    }

    function getBid_callback(uint64 amount) external {
        emit BidAmount(amount);
    }

    // Returns the `account`'s encrypted bid, can be used in a reencryption request
    function getBid(address account) external {
        assert(msg.sender == account);
        emit GetBidMessagePassing(msg.sender);
    }

    function claim_callback(bool enable_claim) external {
        if (enable_claim){
            objectClaimed = true;
        }
    }
  
    // Claim the object. Succeeds only if the caller was the first to get the highest bid.
    function claim() public onlyAfterEnd {
        require(!objectClaimed);
        emit ClaimMessagePassing(msg.sender);
    }
  
    // Withdraw a bid from the auction to the caller once the auction has stopped.
    function withdraw() public onlyAfterEnd {
        emit WithdrawMessagePassing(msg.sender);
    }

    function auctionEnd() public
    onlyAfterEnd {
        require(!tokenTransferred);
        tokenTransferred = true;
    }


    function stop() external
    onlyOwner {
        require(stoppable);
        manuallyStopped = true;
    }

    modifier onlyBeforeEnd() {
        if (block.timestamp >= endTime || manuallyStopped == true) revert();
        _;
    }

    modifier onlyAfterEnd() {
        if (block.timestamp < endTime && manuallyStopped == false) revert();
        _;
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
    function name() public view virtual returns(string memory) {
        return _name;
    }

    // Returns the symbol of the token, usually a shorter version of the name.
    function symbol() public view virtual returns(string memory) {
        return _symbol;
    }

    // Returns the total supply of the token
    function totalSupply() public view virtual returns(uint64) {
        return _totalSupply;
    }

    // Sets the balance of the owner to the given encrypted balance.
    function mint(uint64 mintedAmount) public virtual onlyOwner {
        balances[owner()] = balances[owner()] + mintedAmount; // overflow impossible because of next line
        _totalSupply = _totalSupply + mintedAmount;
        emit Mint(owner(), mintedAmount);
    }

    // Transfers an encrypted amount from the message sender address to the `to` address.
    function transfer(address to, uint64 amount) public virtual returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    // Returns the balance handle of the caller.
    function balanceOf(address wallet) public view virtual returns(uint64) {
        return balances[wallet];
    }

    // Sets the `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint64 amount) public virtual returns(bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        emit Approval(owner, spender, amount);
        return true;
    }

    // Returns the remaining number of tokens that `spender` is allowed to spend
    // on behalf of the caller.
    function allowance(address owner, address spender) public view virtual returns(uint64) {
        return _allowance(owner, spender);
    }

    // Transfers `amount` tokens using the caller's allowance.
    function transferFrom(address from, address to, uint64 amount) public virtual returns(bool) {
        address spender = msg.sender;
        bool isTransferable = _updateAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint64 amount) internal virtual {
        allowances[owner][spender] = amount;
    }

    function _allowance(address owner, address spender) internal view virtual returns(uint64) {
        return allowances[owner][spender];
    }

    function _updateAllowance(address owner, address spender, uint64 amount) internal virtual returns(bool) {
        uint64 currentAllowance = _allowance(owner, spender);
        bool canApprove = amount <= currentAllowance;
        if (canApprove) {
            _approve(owner, spender, currentAllowance - amount);
        } else {
            _approve(owner, spender, 0);
        }
        return canApprove;
    }

    // Transfers an encrypted amount.
    function _transfer(address from, address to, uint64 amount) internal virtual {
        // Make sure the sender has enough tokens.
        bool isTransferable = amount <= balances[from];

        // Add to the balance of `to` and subract from the balance of `from`.
        if (isTransferable) {
            balances[to] = balances[to] + amount;
            balances[from] = balances[from] - amount;
            emit Transfer(from, to, amount); // Comp.sol (TFHE) has a bug, fake Transfer event will be emitted.
        }
    }
}
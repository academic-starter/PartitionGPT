// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
contract EncryptedFunds is Ownable2Step {
    event Transfer(address indexed from, address indexed to);
    event Approval(address indexed owner, address indexed spender);
    event Mint(address indexed to, uint64 encryptedTokenID, uint64 amount);

    // Event to track the total supply for each token
    event TotalSupplyUpdated(uint64 tokenID, uint64 totalSupply);
    event TokenAccessed(uint64 tokenID);
    event BalanceBeforeTransfer(uint64 tokenID, uint64 balance, uint64 allowance);
    event TransferValue(uint64 tokenID, uint64 transferValue);
    event BalanceAfterTransfer(uint64 tokenID, uint64 newBalanceTo, uint64 newBalanceFrom, uint64 updatedAllowance);

    // Struct to store metadata (name, symbol) for each token
    struct TokenMetadata {
        string name;
        string symbol;
    }

    // A mapping from address to encrypted balances of tokens (stored as encrypted)
    mapping(address => mapping(uint64 => uint64)) internal balances;

    // A mapping for allowances, works like balances but for allowances
    mapping(address => mapping(address => mapping(uint64 => uint64))) internal allowances;

    // A mapping for encrypted token IDs to their metadata (name and symbol)
    mapping(uint64 => TokenMetadata) private tokenMetadata;

    // A mapping for total supply per encrypted token ID; can be hidden in prodcution
    mapping(uint64 => uint64) private totalSupplyPerToken;

    // Encrypted token IDs mapping (e.g., Token A = 1, Token B = 2, etc.)
    mapping(uint256 => uint64) private encryptedTokenIDs;

    constructor() payable Ownable(msg.sender) {
        // Initialize metadata for each token and assign encrypted token IDs
        uint64 tokenAID = 1;
        uint64 tokenBID = 2;
        uint64 tokenCID = 3;

        // Store encrypted token IDs
        encryptedTokenIDs[0] = tokenAID;
        encryptedTokenIDs[1] = tokenBID;
        encryptedTokenIDs[2] = tokenCID;

        // Set the metadata for each token
        tokenMetadata[tokenAID] = TokenMetadata("Token A", "TKA");
        tokenMetadata[tokenBID] = TokenMetadata("Token B", "TKB");
        tokenMetadata[tokenCID] = TokenMetadata("Token C", "TKC");
    }

    // Get the total supply of a specific token by its encrypted ID
    function totalSupply(uint64 encryptedTokenID) public view returns (uint64) {
        uint64 bal = totalSupply_priv(encryptedTokenID);
        return totalSupply_callback(bal);
    }

    function totalSupply_priv(uint64 encryptedTokenID) internal view returns (uint64) {
        return totalSupplyPerToken[encryptedTokenID];
    }
    
    function totalSupply_callback(uint64 bal) internal pure returns (uint64) {
        return bal;
    }

    // Getter function to retrieve encrypted token IDs by index
    function getEncryptedTokenID(uint256 index) public view returns (uint64) {
        return encryptedTokenIDs[index];
    }

    // Get the name of a specific token using its encrypted token ID
    function getTokenName(uint64 tokenID) public view returns (string memory) {
        return tokenMetadata[tokenID].name;
    }

    // Get the symbol of a specific token using its encrypted token ID
    function getTokenSymbol(uint64 tokenID) public view returns (string memory) {
        return tokenMetadata[tokenID].symbol;
    }

    function mint(uint64 encryptedTokenID, uint64 mintedAmount) public virtual onlyOwner {
        mint_priv(owner(), encryptedTokenID, mintedAmount);
    }

    function mint_priv(address sender, uint64 encryptedTokenID, uint64 mintedAmount) internal {
        balances[sender][encryptedTokenID] =balances[sender][encryptedTokenID] + mintedAmount;
        // Update the total supply for the specific token
        totalSupplyPerToken[encryptedTokenID] = totalSupplyPerToken[encryptedTokenID] + mintedAmount;
        emit Mint(sender, encryptedTokenID, mintedAmount);
    }


    //used for testing
    function burn(uint64 encryptedTokenID, uint64 mintedAmount) public virtual onlyOwner {
       burn_priv(owner(), encryptedTokenID, mintedAmount);
    }

    function burn_priv(address sender, uint64 encryptedTokenID, uint64 mintedAmount) public virtual onlyOwner {
        balances[sender][encryptedTokenID] = balances[sender][encryptedTokenID] - mintedAmount;
      
        totalSupplyPerToken[encryptedTokenID] = totalSupplyPerToken[encryptedTokenID] - mintedAmount;
        emit Mint(sender, encryptedTokenID, mintedAmount);
    }


    function approve(address spender, uint64 encryptedTokenID, uint64 amount) public virtual returns (bool) {
        address owner = msg.sender;
        bool flag = approve_priv(spender, owner, encryptedTokenID, amount);
        return approve_callback(flag);
    }
    function approve_priv(address spender, address owner, uint64 encryptedTokenID, uint64 amount) internal returns (bool) {
        _approve(owner, spender, encryptedTokenID, amount);
        emit Approval(owner, spender);
        return true;
    }
    function approve_callback(bool flag) internal pure returns (bool) {
       return flag; 
    }

    function transferFrom(
        address from,
        address to,
        uint64 encryptedTokenID,
        uint64 amount
    ) public virtual returns (bool) {
        address spender = msg.sender;
        bool flag = transferFrom_priv(from, to, spender, encryptedTokenID, amount);
        return transferFrom_callback(flag);
    }

    function transferFrom_priv(
        address from,
        address to,
        address spender,
        uint64 encryptedTokenID,
        uint64 amount
    ) internal returns (bool) {
        _transferHidden(from, to, spender, encryptedTokenID, amount);
        return true;
    }

    function transferFrom_callback(
        bool flag
    ) internal pure returns (bool) {
        return flag;
    }

    function _approve(address owner, address spender, uint64 encryptedTokenID, uint64 amount) internal virtual {
        for (uint256 i = 0; i < _getNumberOfTokens(); i++) {
            uint64 currentTokenID = encryptedTokenIDs[i];
            bool isCorrectToken = encryptedTokenID == currentTokenID;
            uint64 currentAllowance = allowances[owner][spender][currentTokenID];
            uint64 newAllowance = isCorrectToken? amount: currentAllowance;
            allowances[owner][spender][currentTokenID] = newAllowance;
        }
    }

    function _allowance(
        address owner,
        address spender,
        uint64 encryptedTokenID
    ) internal view virtual returns (uint64) {
        return allowances[owner][spender][encryptedTokenID];
    }

    function _transferHidden(
        address from,
        address to,
        address spender,
        uint64 encryptedTokenID,
        uint64 amount
    ) internal virtual {
        for (uint256 i = 0; i < _getNumberOfTokens(); i++) {
            uint64 currentTokenID = encryptedTokenIDs[i];
            emit TokenAccessed(currentTokenID);
            _checkAndTransferBalances(from, to, spender, currentTokenID, encryptedTokenID, amount);
        }
        emit Transfer(from, to);
    }

    function _checkAndTransferBalances(
        address from,
        address to,
        address spender,
        uint64 currentTokenID,
        uint64 encryptedTokenID,
        uint64 amount
    ) internal {
        bool isCorrectToken = encryptedTokenID == currentTokenID;
        uint64 currentBalance = balances[from][currentTokenID];
        uint64 currentAllowance = _allowance(from, spender, currentTokenID);
        emit BalanceBeforeTransfer(currentTokenID, currentBalance, currentAllowance);

        bool allowedTransfer = amount <= currentAllowance;
        bool canTransfer = amount <= currentBalance;
        bool isTransferable = canTransfer && allowedTransfer;

        uint64 updatedAllowance = isTransferable?currentAllowance -amount : currentAllowance;
        allowances[from][spender][currentTokenID] = updatedAllowance;

        uint64 transferAmount = isCorrectToken? amount: 0;
        uint64 transferValue = isTransferable? transferAmount:0;

        emit TransferValue(currentTokenID, transferValue);

        _updateBalances(from, to, currentTokenID, transferValue);
    }

    // Helper function to update the balances
    function _updateBalances(address from, address to, uint64 currentTokenID, uint64 transferValue) internal {
        uint64 newBalanceTo = balances[to][currentTokenID] + transferValue;
        balances[to][currentTokenID] = newBalanceTo;

        uint64 newBalanceFrom = balances[from][currentTokenID] - transferValue;
        balances[from][currentTokenID] = newBalanceFrom;

        emit BalanceAfterTransfer(
            currentTokenID,
            newBalanceTo,
            newBalanceFrom,
            allowances[from][msg.sender][currentTokenID]
        );
    }

    function _getNumberOfTokens() internal pure returns (uint256) {
        return 3; // Example with 3 tokens (extendable if needed)
    }

    function balanceOf(address account, uint64 encryptedTokenID) public view virtual returns (uint64) {
        require(msg.sender == account);
        // Return the balance of the specified account for the specified encrypted token ID
        uint64 amt = balanceOf_priv(account, encryptedTokenID);
        return balanceOf_callback(amt);
    }
    function balanceOf_priv(address account, uint64 encryptedTokenID) internal view returns (uint64) {
        // Return the balance of the specified account for the specified encrypted token ID
        return balances[account][encryptedTokenID];
    }
    
    function balanceOf_callback(uint64 amt) internal pure returns (uint64) {
        // Return the balance of the specified account for the specified encrypted token ID
        return amt;
    }
}
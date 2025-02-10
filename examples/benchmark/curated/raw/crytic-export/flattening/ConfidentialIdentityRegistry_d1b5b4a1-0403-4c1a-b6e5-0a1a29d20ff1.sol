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
contract ConfidentialIdentityRegistry is Ownable2Step {
    uint constant MAX_IDENTIFIERS_LENGTH = 20;

    // A mapping from wallet to registrarId
    mapping(address => uint) public registrars;

    // A mapping from wallet to an identity.
    mapping(address => Identity) internal identities;

    struct Identity {
        uint registrarId;
        mapping(string => uint64) identifiers;
        string[] identifierList;
    }

    mapping(address => mapping(address => mapping(string => bool))) permissions; // users => contracts => identifiers[]

    event NewRegistrar(address wallet, uint registrarId);
    event RemoveRegistrar(address wallet);
    event NewDid(address wallet);
    event RemoveDid(address wallet);

    constructor() Ownable(msg.sender) {}

    function addRegistrar(address wallet, uint registrarId) public onlyOwner {
        require(registrarId > 0, "registrarId needs to be > 0");
        registrars[wallet] = registrarId;
        emit NewRegistrar(wallet, registrarId);
    }

    function removeRegistrar(address wallet) public onlyOwner {
        require(registrars[wallet] > 0, "wallet is not registrar");
        registrars[wallet] = 0;
        emit RemoveRegistrar(wallet);
    }

    // Add user
    function addDid(address wallet) public onlyRegistrar {
        require(
            identities[wallet].registrarId == 0,
            "This wallet is already registered"
        );
        Identity storage newIdentity = identities[wallet];
        newIdentity.registrarId = registrars[msg.sender];
        emit NewDid(wallet);
    }

    function removeDid(
        address wallet
    ) public onlyExistingWallet(wallet) onlyRegistrarOf(wallet) {
        string[] memory identifierList_ = identities[wallet].identifierList;
        uint identifierLength = identifierList_.length;
        for (uint i; i < identifierLength; i++) {
            identities[wallet].identifiers[identifierList_[i]] = 0;
        }
        delete identities[wallet];
        emit RemoveDid(wallet);
    }

    // Set user's identifiers
    function setIdentifier(
        address wallet,
        string memory identifier,
        uint64 value
    ) internal onlyExistingWallet(wallet) onlyRegistrarOf(wallet) {
        identities[wallet].identifiers[identifier] = value;
        string[] memory identifierList_ = identities[wallet].identifierList;
        uint identifierLength = identifierList_.length;
        for (uint i; i < identifierLength; i++) {
            if (
                keccak256(bytes(identities[wallet].identifierList[i])) ==
                keccak256(bytes(identifier))
            ) return;
        }
        require(
            identifierLength + 1 <= MAX_IDENTIFIERS_LENGTH,
            "Too many identifiers"
        );
        identities[wallet].identifierList.push(identifier);
    }

    function removeIdentifier(
        address wallet,
        string memory identifier
    ) internal onlyExistingWallet(wallet) onlyRegistrarOf(wallet) {
        string[] memory identifierList_ = identities[wallet].identifierList;
        uint identifierLength = identifierList_.length;
        for (uint i; i < identifierLength; i++) {
            if (
                keccak256(bytes(identities[wallet].identifierList[i])) ==
                keccak256(bytes(identifier))
            ) {
                identities[wallet].identifierList[i] = identities[wallet]
                    .identifierList[identifierLength - 1];
                identities[wallet].identifierList.pop();
                return;
            }
        }
        require(false, "Identifier not found");
    }

    // User handling permission permission
    function grantAccess(
        address allowed,
        string[] calldata identifiers
    ) public {
        for (uint i = 0; i < identifiers.length; i++) {
            permissions[msg.sender][allowed][identifiers[i]] = true;
        }
    }

    function revokeAccess(
        address allowed,
        string[] calldata identifiers
    ) public {
        for (uint i = 0; i < identifiers.length; i++) {
            permissions[msg.sender][allowed][identifiers[i]] = false;
        }
    }

    function getRegistrar(address wallet) public view returns (uint) {
        return identities[wallet].registrarId;
    }

    function getIdentifier(
        address wallet,
        string calldata identifier
    )
        public
        onlyExistingWallet(wallet)
        onlyAllowed(wallet, identifier)
        returns (uint64)
    {
        return
            identities[wallet].identifiers[identifier];
    }

    // ACL
    modifier onlyExistingWallet(address wallet) {
        require(
            identities[wallet].registrarId > 0,
            "This wallet isn't registered"
        );
        _;
    }

    modifier onlyRegistrar() {
        require(registrars[msg.sender] > 0, "You're not a registrar");
        _;
    }

    modifier onlyRegistrarOf(address wallet) {
        uint registrarId = registrars[msg.sender];
        require(
            identities[wallet].registrarId == registrarId,
            "You're not managing this identity"
        );
        _;
    }

    modifier onlyAllowed(address wallet, string memory identifier) {
        require(
            owner() == msg.sender ||
                permissions[wallet][msg.sender][identifier],
            "User didn't give you permission to access this identifier."
        );
        _;
    }
}


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

/// @title IdentityManager Interface
/// @author Alessandro Manfredi
/// @notice This contract is the interface for the IdentityManager contract.
interface IIdentityManager {
    error DkimSignatureVerificationFailed();
    error InvalidEmailPublicKeyHash();
    error InvalidFromDomainHash();

    function verifyProofAndGetVoterId(
        bytes calldata identityPublicValues,
        bytes calldata identityProofBytes
    ) external view returns (bytes32);
}

/// @title Suffragium Interface
/// @author Alessandro Manfredi
/// @notice This contract is the interface for the Suffragium voting system.
interface ISuffragium is IIdentityManager {
    enum VoteState {
        NotCreated,
        Created,
        RequestedToReveal,
        Revealed
    }

    struct Vote {
        uint256 endBlock;
        uint256 minQuorum;
        uint64 encryptedResult;
        uint256 result;
        uint256 voteCount;
        string description;
        VoteState state;
    }

    event MinQuorumSet(uint256 minQuorum);
    event VoteCasted(uint256 indexed voteId);
    event VoteCreated(uint256 indexed voteId);
    event VoteRevealRequested(uint256 indexed voteId);
    event VoteRevealed(uint256 indexed voteId);

    error AlreadyVoted();
    error VoteDoesNotExist();
    error VoteNotClosed();
    error VoteClosed();

    function createVote(uint256 endBlock, uint256 minQuorum, string calldata description) external;

    function castVote(
        uint256 voteId,
        bool support,
        bytes32 voterId
    ) external ;

    function getVote(uint256 voteId) external view returns (Vote memory);

    function hasVoted(uint256 voteId, bytes32 voterId) external view returns (bool);

    function isVotePassed(uint256 voteId) external view returns (bool);

    function requestRevealVote(uint256 voteId) external;

    function revealVote(uint256 requestId, uint256 encryptedResult) external;
}

/// @title SP1 Verifier Interface
/// @author Succinct Labs
/// @notice This contract is the interface for the SP1 Verifier.
interface ISP1Verifier {
    /// @notice Verifies a proof with given public values and vkey.
    /// @dev It is expected that the first 4 bytes of proofBytes must match the first 4 bytes of
    /// target verifier's VERIFIER_HASH.
    /// @param programVKey The verification key for the RISC-V program.
    /// @param publicValues The public values encoded as bytes.
    /// @param proofBytes The proof of the program execution the SP1 zkVM encoded as bytes.
    function verifyProof(bytes32 programVKey, bytes calldata publicValues, bytes calldata proofBytes) external view;
}

interface ISP1VerifierWithHash is ISP1Verifier {
    /// @notice Returns the hash of the verifier.
    function VERIFIER_HASH() external pure returns (bytes32);
}


/**
 * @title IdentityManager
 * @notice Manages voter identity verification using DKIM email signatures
 * @dev Uses zero-knowledge proofs to verify email authenticity while preserving privacy
 */
contract IdentityManager is IIdentityManager {
    /// @notice Address of the SP1 zero-knowledge proof verifier contract
    address public immutable VERIFIER;

    /// @notice Verification key for the zero-knowledge program
    bytes32 public immutable PROGRAM_V_KEY;

    /// @notice Hash of the expected DKIM public key for email verification
    bytes32 public immutable EMAIL_PUBLIC_KEY_HASH;

    /// @notice Hash of the expected email sender domain
    bytes32 public immutable FROM_DOMAIN_HASH;

    /**
     * @notice Initializes the identity manager with verification parameters
     * @param verifier Address of the SP1 verifier contract
     * @param programVKey Verification key for the ZK program
     * @param emailPublicKeyHash Hash of the DKIM public key
     * @param fromDomainHash Hash of the sender domain
     */
    constructor(address verifier, bytes32 programVKey, bytes32 emailPublicKeyHash, bytes32 fromDomainHash) {
        VERIFIER = verifier;
        PROGRAM_V_KEY = programVKey;
        EMAIL_PUBLIC_KEY_HASH = emailPublicKeyHash;
        FROM_DOMAIN_HASH = fromDomainHash;
    }

    /// @inheritdoc IIdentityManager
    function verifyProofAndGetVoterId(
        bytes calldata identityPublicValues,
        bytes calldata identityProofBytes
    ) public view returns (bytes32) {
        // TODO: use identityPublicValues and identityProofBytes
        ISP1Verifier(VERIFIER).verifyProof(PROGRAM_V_KEY, abi.encodePacked(""), abi.encodePacked(""));

        // Decode the public values committed by the ZK program
        (bytes32 fromDomainHash, bytes32 emailPublicKeyHash, bytes32 voterId, bool verified) = abi.decode(
            identityPublicValues,
            (bytes32, bytes32, bytes32, bool)
        );

        // Verify the DKIM signature was valid
        if (!verified) revert DkimSignatureVerificationFailed();

        // Verify the email used the expected DKIM public key
        if (emailPublicKeyHash != EMAIL_PUBLIC_KEY_HASH) revert InvalidEmailPublicKeyHash();

        // Verify the email came from the expected domain
        if (fromDomainHash != FROM_DOMAIN_HASH) revert InvalidFromDomainHash();

        return voterId;
    }
}


/**
 * @title Suffragium
 * @dev A voting system contract that uses FHE (Fully Homomorphic Encryption) to enable private voting
 * while maintaining vote integrity and preventing manipulation.
 */
contract Suffragium is ISuffragium, IdentityManager, Ownable {
    // Mapping of vote IDs to Vote structs containing vote details
    mapping(uint256 => Vote) private _votes;
    // Double mapping tracking which voters have cast votes for each vote ID
    mapping(uint256 => mapping(bytes32 => bool)) private _castedVotes;
    // Counter for generating unique vote IDs
    uint256 public numberOfVotes;

    /**
     * @dev Constructor initializes the contract with required parameters
     * @param verifier Address of the proof verifier contract
     * @param programVKey Verification key for the zero-knowledge program
     * @param emailPublicKeyHash Hash of the email public key for voter verification
     * @param fromDomainHash Hash of the allowed email domain
     */
    constructor(
        address verifier,
        bytes32 programVKey,
        bytes32 emailPublicKeyHash,
        bytes32 fromDomainHash
    ) IdentityManager(verifier, programVKey, emailPublicKeyHash, fromDomainHash) Ownable(msg.sender) {}

    /// @inheritdoc ISuffragium
    function createVote(uint256 endBlock, uint256 minQuorum, string calldata description) external onlyOwner {
        uint256 voteId = numberOfVotes;
        _votes[voteId] = Vote(endBlock, minQuorum, 0, 0, 0, description, VoteState.Created);
        numberOfVotes++;
        emit VoteCreated(voteId);
    }

    /// @inheritdoc ISuffragium
    function castVote(
        uint256 voteId,
        bool support,
        bytes32 voterId
    ) external {
        // NOTE: If an attacker gains access to the email, they can generate a proof and submit it on-chain with a support value greater than 1, resulting in censorship of the legitimate voter.
        if (_castedVotes[voteId][voterId]) revert AlreadyVoted();
        _castedVotes[voteId][voterId] = true;

        Vote storage vote = _getVote(voteId);
        if (block.number > vote.endBlock) revert VoteClosed();

        // Increment the vote count for this specific vote
        vote.voteCount++;

        // Update vote tallies if vote is valid
        vote.encryptedResult = vote.encryptedResult +  (support?1:0);
       
        emit VoteCasted(voteId);
    }

    /// @inheritdoc ISuffragium
    function getVote(uint256 voteId) external view returns (Vote memory) {
        return _getVote(voteId);
    }

    /// @inheritdoc ISuffragium
    function hasVoted(uint256 voteId, bytes32 voterId) external view returns (bool) {
        return _castedVotes[voteId][voterId];
    }

    /// @inheritdoc ISuffragium
    function isVotePassed(uint256 voteId) external view returns (bool) {
        Vote storage vote = _getVote(voteId);
        if (vote.state != VoteState.Revealed) return false;
        if (vote.result == 0) return false;
        return (vote.result * 10 ** 18) / vote.voteCount >= vote.minQuorum;
    }

    /// @inheritdoc ISuffragium
    function requestRevealVote(uint256 voteId) external {
        Vote storage vote = _getVote(voteId);
        if (block.number <= vote.endBlock) revert VoteNotClosed();

        // Request decryption of vote results through the Gateway
        uint256[] memory cts = new uint256[](1);
        cts[0] = vote.encryptedResult;
        vote.state = VoteState.RequestedToReveal;

        emit VoteRevealRequested(voteId);
    }

    /// @inheritdoc ISuffragium
    function revealVote(uint256 voteId, uint256 result) external {
        // Update vote with decrypted results
        Vote storage vote = _getVote(voteId);
        vote.state = VoteState.Revealed;
        vote.result = result;

        emit VoteRevealed(voteId);
    }

    /**
     * @dev Internal helper to retrieve a vote by ID and validate its existence
     * @param voteId ID of the vote to retrieve
     * @return Vote storage pointer to the vote data
     */
    function _getVote(uint256 voteId) internal view returns (Vote storage) {
        Vote storage vote = _votes[voteId];
        if (vote.endBlock == 0) revert VoteDoesNotExist();
        return vote;
    }
}
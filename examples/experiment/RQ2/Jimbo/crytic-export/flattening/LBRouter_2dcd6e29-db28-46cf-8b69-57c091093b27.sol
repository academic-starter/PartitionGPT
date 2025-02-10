pragma solidity 0.8.10;
library Encoded {
    uint256 internal constant MASK_UINT1 = 0x1;
    uint256 internal constant MASK_UINT8 = 0xff;
    uint256 internal constant MASK_UINT12 = 0xfff;
    uint256 internal constant MASK_UINT14 = 0x3fff;
    uint256 internal constant MASK_UINT16 = 0xffff;
    uint256 internal constant MASK_UINT20 = 0xfffff;
    uint256 internal constant MASK_UINT24 = 0xffffff;
    uint256 internal constant MASK_UINT40 = 0xffffffffff;
    uint256 internal constant MASK_UINT64 = 0xffffffffffffffff;
    uint256 internal constant MASK_UINT128 = 0xffffffffffffffffffffffffffffffff;

    /**
     * @notice Internal function to set a value in an encoded bytes32 using a mask and offset
     * @dev This function can overflow
     * @param encoded The previous encoded value
     * @param value The value to encode
     * @param mask The mask
     * @param offset The offset
     * @return newEncoded The new encoded value
     */
    function set(bytes32 encoded, uint256 value, uint256 mask, uint256 offset)
        internal
        pure
        returns (bytes32 newEncoded)
    {
        assembly {
            newEncoded := and(encoded, not(shl(offset, mask)))
            newEncoded := or(newEncoded, shl(offset, and(value, mask)))
        }
    }

    /**
     * @notice Internal function to set a bool in an encoded bytes32 using an offset
     * @dev This function can overflow
     * @param encoded The previous encoded value
     * @param boolean The bool to encode
     * @param offset The offset
     * @return newEncoded The new encoded value
     */
    function setBool(bytes32 encoded, bool boolean, uint256 offset) internal pure returns (bytes32 newEncoded) {
        return set(encoded, boolean ? 1 : 0, MASK_UINT1, offset);
    }

    /**
     * @notice Internal function to decode a bytes32 sample using a mask and offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param mask The mask
     * @param offset The offset
     * @return value The decoded value
     */
    function decode(bytes32 encoded, uint256 mask, uint256 offset) internal pure returns (uint256 value) {
        assembly {
            value := and(shr(offset, encoded), mask)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a bool using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return boolean The decoded value as a bool
     */
    function decodeBool(bytes32 encoded, uint256 offset) internal pure returns (bool boolean) {
        assembly {
            boolean := and(shr(offset, encoded), MASK_UINT1)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint8 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint8(bytes32 encoded, uint256 offset) internal pure returns (uint8 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT8)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint12 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint16, since uint12 is not supported
     */
    function decodeUint12(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT12)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint14 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint16, since uint14 is not supported
     */
    function decodeUint14(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT14)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint16 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint16(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT16)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint20 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint24, since uint20 is not supported
     */
    function decodeUint20(bytes32 encoded, uint256 offset) internal pure returns (uint24 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT20)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint24 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint24(bytes32 encoded, uint256 offset) internal pure returns (uint24 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT24)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint40 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint40(bytes32 encoded, uint256 offset) internal pure returns (uint40 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT40)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint64 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint64(bytes32 encoded, uint256 offset) internal pure returns (uint64 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT64)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint128 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint128(bytes32 encoded, uint256 offset) internal pure returns (uint128 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT128)
        }
    }
}
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}
library PackedUint128Math {
    error PackedUint128Math__AddOverflow();
    error PackedUint128Math__SubUnderflow();
    error PackedUint128Math__MultiplierTooLarge();

    uint256 private constant OFFSET = 128;
    uint256 private constant MASK_128 = 0xffffffffffffffffffffffffffffffff;
    uint256 private constant MASK_128_PLUS_ONE = MASK_128 + 1;

    /**
     * @dev Encodes two uint128 into a single bytes32
     * @param x1 The first uint128
     * @param x2 The second uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     */
    function encode(uint128 x1, uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := or(and(x1, MASK_128), shl(OFFSET, x2))
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the first uint128
     * @param x1 The uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: empty
     */
    function encodeFirst(uint128 x1) internal pure returns (bytes32 z) {
        assembly {
            z := and(x1, MASK_128)
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the second uint128
     * @param x2 The uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: empty
     * [128 - 256[: x2
     */
    function encodeSecond(uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := shl(OFFSET, x2)
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the first or second uint128
     * @param x The uint128
     * @param first Whether to encode as the first or second uint128
     * @return z The encoded bytes32 as follows:
     * if first:
     * [0 - 128[: x
     * [128 - 256[: empty
     * else:
     * [0 - 128[: empty
     * [128 - 256[: x
     */
    function encode(uint128 x, bool first) internal pure returns (bytes32 z) {
        return first ? encodeFirst(x) : encodeSecond(x);
    }

    /**
     * @dev Decodes a bytes32 into two uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return x1 The first uint128
     * @return x2 The second uint128
     */
    function decode(bytes32 z) internal pure returns (uint128 x1, uint128 x2) {
        assembly {
            x1 := and(z, MASK_128)
            x2 := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x
     * [128 - 256[: any
     * @return x The first uint128
     */
    function decodeX(bytes32 z) internal pure returns (uint128 x) {
        assembly {
            x := and(z, MASK_128)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the second uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: any
     * [128 - 256[: y
     * @return y The second uint128
     */
    function decodeY(bytes32 z) internal pure returns (uint128 y) {
        assembly {
            y := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first or second uint128
     * @param z The encoded bytes32 as follows:
     * if first:
     * [0 - 128[: x1
     * [128 - 256[: empty
     * else:
     * [0 - 128[: empty
     * [128 - 256[: x2
     * @param first Whether to decode as the first or second uint128
     * @return x The decoded uint128
     */
    function decode(bytes32 z, bool first) internal pure returns (uint128 x) {
        return first ? decodeX(z) : decodeY(z);
    }

    /**
     * @dev Adds two encoded bytes32, reverting on overflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := add(x, y)
        }

        if (z < x || uint128(uint256(z)) < uint128(uint256(x))) {
            revert PackedUint128Math__AddOverflow();
        }
    }

    /**
     * @dev Adds an encoded bytes32 and two uint128, reverting on overflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return add(x, encode(y1, y2));
    }

    /**
     * @dev Subtracts two encoded bytes32, reverting on underflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := sub(x, y)
        }

        if (z > x || uint128(uint256(z)) > uint128(uint256(x))) {
            revert PackedUint128Math__SubUnderflow();
        }
    }

    /**
     * @dev Subtracts an encoded bytes32 and two uint128, reverting on underflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return sub(x, encode(y1, y2));
    }

    /**
     * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return x1 < y1 || x2 < y2
     */
    function lt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 < y1 || x2 < y2;
    }

    /**
     * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return x1 < y1 || x2 < y2
     */
    function gt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 > y1 || x2 > y2;
    }

    /**
     * @dev Multiplies an encoded bytes32 by a uint128 then divides the result by 10_000, rounding down
     * The result can't overflow as the multiplier needs to be smaller or equal to 10_000
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param multiplier The uint128 to multiply by (must be smaller or equal to 10_000)
     * @return z The product of x and multiplier encoded as follows:
     * [0 - 128[: floor((x1 * multiplier) / 10_000)
     * [128 - 256[: floor((x2 * multiplier) / 10_000)
     */
    function scalarMulDivBasisPointRoundDown(bytes32 x, uint128 multiplier) internal pure returns (bytes32 z) {
        if (multiplier == 0) return 0;

        uint256 BASIS_POINT_MAX = Constants.BASIS_POINT_MAX;
        if (multiplier > BASIS_POINT_MAX) revert PackedUint128Math__MultiplierTooLarge();

        (uint128 x1, uint128 x2) = decode(x);

        assembly {
            x1 := div(mul(x1, multiplier), BASIS_POINT_MAX)
            x2 := div(mul(x2, multiplier), BASIS_POINT_MAX)
        }

        return encode(x1, x2);
    }
}
interface IPendingOwnable {
    error PendingOwnable__AddressZero();
    error PendingOwnable__NoPendingOwner();
    error PendingOwnable__NotOwner();
    error PendingOwnable__NotPendingOwner();
    error PendingOwnable__PendingOwnerAlreadySet();

    event PendingOwnerSet(address indexed pendingOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}
interface ILBLegacyPair is ILBLegacyToken {
    /// @dev Structure to store the protocol fees:
    /// - binStep: The bin step
    /// - baseFactor: The base factor
    /// - filterPeriod: The filter period, where the fees stays constant
    /// - decayPeriod: The decay period, where the fees are halved
    /// - reductionFactor: The reduction factor, used to calculate the reduction of the accumulator
    /// - variableFeeControl: The variable fee control, used to control the variable fee, can be 0 to disable them
    /// - protocolShare: The share of fees sent to protocol
    /// - maxVolatilityAccumulated: The max value of volatility accumulated
    /// - volatilityAccumulated: The value of volatility accumulated
    /// - volatilityReference: The value of volatility reference
    /// - indexRef: The index reference
    /// - time: The last time the accumulator was called
    struct FeeParameters {
        // 144 lowest bits in slot
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        // 112 highest bits in slot
        uint24 volatilityAccumulated;
        uint24 volatilityReference;
        uint24 indexRef;
        uint40 time;
    }

    /// @dev Structure used during swaps to distributes the fees:
    /// - total: The total amount of fees
    /// - protocol: The amount of fees reserved for protocol
    struct FeesDistribution {
        uint128 total;
        uint128 protocol;
    }

    /// @dev Structure to store the reserves of bins:
    /// - reserveX: The current reserve of tokenX of the bin
    /// - reserveY: The current reserve of tokenY of the bin
    struct Bin {
        uint112 reserveX;
        uint112 reserveY;
        uint256 accTokenXPerShare;
        uint256 accTokenYPerShare;
    }

    /// @dev Structure to store the information of the pair such as:
    /// slot0:
    /// - activeId: The current id used for swaps, this is also linked with the price
    /// - reserveX: The sum of amounts of tokenX across all bins
    /// slot1:
    /// - reserveY: The sum of amounts of tokenY across all bins
    /// - oracleSampleLifetime: The lifetime of an oracle sample
    /// - oracleSize: The current size of the oracle, can be increase by users
    /// - oracleActiveSize: The current active size of the oracle, composed only from non empty data sample
    /// - oracleLastTimestamp: The current last timestamp at which a sample was added to the circular buffer
    /// - oracleId: The current id of the oracle
    /// slot2:
    /// - feesX: The current amount of fees to distribute in tokenX (total, protocol)
    /// slot3:
    /// - feesY: The current amount of fees to distribute in tokenY (total, protocol)
    struct PairInformation {
        uint24 activeId;
        uint136 reserveX;
        uint136 reserveY;
        uint16 oracleSampleLifetime;
        uint16 oracleSize;
        uint16 oracleActiveSize;
        uint40 oracleLastTimestamp;
        uint16 oracleId;
        FeesDistribution feesX;
        FeesDistribution feesY;
    }

    /// @dev Structure to store the debts of users
    /// - debtX: The tokenX's debt
    /// - debtY: The tokenY's debt
    struct Debts {
        uint256 debtX;
        uint256 debtY;
    }

    /// @dev Structure to store fees:
    /// - tokenX: The amount of fees of token X
    /// - tokenY: The amount of fees of token Y
    struct Fees {
        uint128 tokenX;
        uint128 tokenY;
    }

    /// @dev Structure to minting informations:
    /// - amountXIn: The amount of token X sent
    /// - amountYIn: The amount of token Y sent
    /// - amountXAddedToPair: The amount of token X that have been actually added to the pair
    /// - amountYAddedToPair: The amount of token Y that have been actually added to the pair
    /// - activeFeeX: Fees X currently generated
    /// - activeFeeY: Fees Y currently generated
    /// - totalDistributionX: Total distribution of token X. Should be 1e18 (100%) or 0 (0%)
    /// - totalDistributionY: Total distribution of token Y. Should be 1e18 (100%) or 0 (0%)
    /// - id: Id of the current working bin when looping on the distribution array
    /// - amountX: The amount of token X deposited in the current bin
    /// - amountY: The amount of token Y deposited in the current bin
    /// - distributionX: Distribution of token X for the current working bin
    /// - distributionY: Distribution of token Y for the current working bin
    struct MintInfo {
        uint256 amountXIn;
        uint256 amountYIn;
        uint256 amountXAddedToPair;
        uint256 amountYAddedToPair;
        uint256 activeFeeX;
        uint256 activeFeeY;
        uint256 totalDistributionX;
        uint256 totalDistributionY;
        uint256 id;
        uint256 amountX;
        uint256 amountY;
        uint256 distributionX;
        uint256 distributionY;
    }

    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        bool swapForY,
        uint256 amountIn,
        uint256 amountOut,
        uint256 volatilityAccumulated,
        uint256 fees
    );

    event FlashLoan(address indexed sender, address indexed receiver, IERC20 token, uint256 amount, uint256 fee);

    event CompositionFee(
        address indexed sender, address indexed recipient, uint256 indexed id, uint256 feesX, uint256 feesY
    );

    event DepositedToBin(
        address indexed sender, address indexed recipient, uint256 indexed id, uint256 amountX, uint256 amountY
    );

    event WithdrawnFromBin(
        address indexed sender, address indexed recipient, uint256 indexed id, uint256 amountX, uint256 amountY
    );

    event FeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event ProtocolFeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event OracleSizeIncreased(uint256 previousSize, uint256 newSize);

    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function factory() external view returns (address);

    function getReservesAndId() external view returns (uint256 reserveX, uint256 reserveY, uint256 activeId);

    function getGlobalFees()
        external
        view
        returns (uint128 feesXTotal, uint128 feesYTotal, uint128 feesXProtocol, uint128 feesYProtocol);

    function getOracleParameters()
        external
        view
        returns (
            uint256 oracleSampleLifetime,
            uint256 oracleSize,
            uint256 oracleActiveSize,
            uint256 oracleLastTimestamp,
            uint256 oracleId,
            uint256 min,
            uint256 max
        );

    function getOracleSampleFrom(uint256 timeDelta)
        external
        view
        returns (uint256 cumulativeId, uint256 cumulativeAccumulator, uint256 cumulativeBinCrossed);

    function feeParameters() external view returns (FeeParameters memory);

    function findFirstNonEmptyBinId(uint24 id_, bool sentTokenY) external view returns (uint24 id);

    function getBin(uint24 id) external view returns (uint256 reserveX, uint256 reserveY);

    function pendingFees(address account, uint256[] memory ids)
        external
        view
        returns (uint256 amountX, uint256 amountY);

    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);

    function flashLoan(address receiver, IERC20 token, uint256 amount, bytes calldata data) external;

    function mint(
        uint256[] calldata ids,
        uint256[] calldata distributionX,
        uint256[] calldata distributionY,
        address to
    ) external returns (uint256 amountXAddedToPair, uint256 amountYAddedToPair, uint256[] memory liquidityMinted);

    function burn(uint256[] calldata ids, uint256[] calldata amounts, address to)
        external
        returns (uint256 amountX, uint256 amountY);

    function increaseOracleLength(uint16 newSize) external;

    function collectFees(address account, uint256[] calldata ids) external returns (uint256 amountX, uint256 amountY);

    function collectProtocolFees() external returns (uint128 amountX, uint128 amountY);

    function setFeesParameters(bytes32 packedFeeParameters) external;

    function forceDecay() external;

    function initialize(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 sampleLifetime,
        bytes32 packedFeeParameters
    ) external;
}
contract LBRouter is ILBRouter {
    using TokenHelper for IERC20;
    using TokenHelper for IWNATIVE;
    using JoeLibrary for uint256;
    using PackedUint128Math for bytes32;

    ILBFactory private immutable _factory;
    IJoeFactory private immutable _factoryV1;
    ILBLegacyFactory private immutable _legacyFactory;
    ILBLegacyRouter private immutable _legacyRouter;
    IWNATIVE private immutable _wnative;

    modifier onlyFactoryOwner() {
        if (msg.sender != _factory.owner()) revert LBRouter__NotFactoryOwner();
        _;
    }

    modifier ensure(uint256 deadline) {
        if (block.timestamp > deadline) revert LBRouter__DeadlineExceeded(deadline, block.timestamp);
        _;
    }

    modifier verifyPathValidity(Path memory path) {
        if (
            path.pairBinSteps.length == 0 || path.versions.length != path.pairBinSteps.length
                || path.pairBinSteps.length + 1 != path.tokenPath.length
        ) revert LBRouter__LengthsMismatch();
        _;
    }

    /**
     * @notice Constructor
     * @param factory Address of Joe V2.1 factory
     * @param factoryV1 Address of Joe V1 factory
     * @param legacyFactory Address of Joe V2 factory
     * @param legacyRouter Address of Joe V2 router
     * @param wnative Address of WNATIVE
     */
    constructor(
        ILBFactory factory,
        IJoeFactory factoryV1,
        ILBLegacyFactory legacyFactory,
        ILBLegacyRouter legacyRouter,
        IWNATIVE wnative
    ) {
        _factory = factory;
        _factoryV1 = factoryV1;
        _legacyFactory = legacyFactory;
        _legacyRouter = legacyRouter;
        _wnative = wnative;
    }

    /**
     * @dev Receive function that only accept NATIVE from the WNATIVE contract
     */
    receive() external payable {
        if (msg.sender != address(_wnative)) revert LBRouter__SenderIsNotWNATIVE();
    }

    /**
     * View function to get the factory V2.1 address
     * @return lbFactory The address of the factory V2.1
     */
    function getFactory() external view override returns (ILBFactory lbFactory) {
        return _factory;
    }

    /**
     * View function to get the factory V2 address
     * @return legacyLBfactory The address of the factory V2
     */
    function getLegacyFactory() external view override returns (ILBLegacyFactory legacyLBfactory) {
        return _legacyFactory;
    }

    /**
     * View function to get the factory V1 address
     * @return factoryV1 The address of the factory V1
     */
    function getV1Factory() external view override returns (IJoeFactory factoryV1) {
        return _factoryV1;
    }

    /**
     * View function to get the router V2 address
     * @return legacyRouter The address of the router V2
     */
    function getLegacyRouter() external view override returns (ILBLegacyRouter legacyRouter) {
        return _legacyRouter;
    }

    /**
     * View function to get the WNATIVE address
     * @return wnative The address of WNATIVE
     */
    function getWNATIVE() external view override returns (IWNATIVE wnative) {
        return _wnative;
    }

    /**
     * @notice Returns the approximate id corresponding to the inputted price.
     * Warning, the returned id may be inaccurate close to the start price of a bin
     * @param pair The address of the LBPair
     * @param price The price of y per x (multiplied by 1e36)
     * @return The id corresponding to this price
     */
    function getIdFromPrice(ILBPair pair, uint256 price) external view override returns (uint24) {
        return pair.getIdFromPrice(price);
    }

    /**
     * @notice Returns the price corresponding to the inputted id
     * @param pair The address of the LBPair
     * @param id The id
     * @return The price corresponding to this id
     */
    function getPriceFromId(ILBPair pair, uint24 id) external view override returns (uint256) {
        return pair.getPriceFromId(id);
    }

    /**
     * @notice Simulate a swap in
     * @param pair The address of the LBPair
     * @param amountOut The amount of token to receive
     * @param swapForY Whether you swap X for Y (true), or Y for X (false)
     * @return amountIn The amount of token to send in order to receive amountOut token
     * @return amountOutLeft The amount of token Out that can't be returned due to a lack of liquidity
     * @return fee The amount of fees paid in token sent
     */
    function getSwapIn(ILBPair pair, uint128 amountOut, bool swapForY)
        public
        view
        override
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee)
    {
        (amountIn, amountOutLeft, fee) = pair.getSwapIn(amountOut, swapForY);
    }

    /**
     * @notice Simulate a swap out
     * @param pair The address of the LBPair
     * @param amountIn The amount of token sent
     * @param swapForY Whether you swap X for Y (true), or Y for X (false)
     * @return amountInLeft The amount of token In that can't be swapped due to a lack of liquidity
     * @return amountOut The amount of token received if amountIn tokenX are sent
     * @return fee The amount of fees paid in token sent
     */
    function getSwapOut(ILBPair pair, uint128 amountIn, bool swapForY)
        external
        view
        override
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee)
    {
        (amountInLeft, amountOut, fee) = pair.getSwapOut(amountIn, swapForY);
    }

    /**
     * @notice Create a liquidity bin LBPair for tokenX and tokenY using the factory
     * @param tokenX The address of the first token
     * @param tokenY The address of the second token
     * @param activeId The active id of the pair
     * @param binStep The bin step in basis point, used to calculate log(1 + binStep)
     * @return pair The address of the newly created LBPair
     */
    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        override
        returns (ILBPair pair)
    {
        pair = _factory.createLBPair(tokenX, tokenY, activeId, binStep);
    }

    /**
     * @notice Add liquidity while performing safety checks
     * @dev This function is compliant with fee on transfer tokens
     * @param liquidityParameters The liquidity parameters
     * @return amountXAdded The amount of token X added
     * @return amountYAdded The amount of token Y added
     * @return amountXLeft The amount of token X left (sent back to liquidityParameters.refundTo)
     * @return amountYLeft The amount of token Y left (sent back to liquidityParameters.refundTo)
     * @return depositIds The ids of the deposits
     * @return liquidityMinted The amount of liquidity minted
     */
    function addLiquidity(LiquidityParameters calldata liquidityParameters)
        external
        override
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        )
    {
        ILBPair lbPair = ILBPair(
            _getLBPairInformation(
                liquidityParameters.tokenX, liquidityParameters.tokenY, liquidityParameters.binStep, Version.V2_1
            )
        );
        if (liquidityParameters.tokenX != lbPair.getTokenX()) revert LBRouter__WrongTokenOrder();

        liquidityParameters.tokenX.safeTransferFrom(msg.sender, address(lbPair), liquidityParameters.amountX);
        liquidityParameters.tokenY.safeTransferFrom(msg.sender, address(lbPair), liquidityParameters.amountY);

        (amountXAdded, amountYAdded, amountXLeft, amountYLeft, depositIds, liquidityMinted) =
            _addLiquidity(liquidityParameters, lbPair);
    }

    /**
     * @notice Add liquidity with NATIVE while performing safety checks
     * @dev This function is compliant with fee on transfer tokens
     * @param liquidityParameters The liquidity parameters
     * @return amountXAdded The amount of token X added
     * @return amountYAdded The amount of token Y added
     * @return amountXLeft The amount of token X left (sent back to liquidityParameters.refundTo)
     * @return amountYLeft The amount of token Y left (sent back to liquidityParameters.refundTo)
     * @return depositIds The ids of the deposits
     * @return liquidityMinted The amount of liquidity minted
     */
    function addLiquidityNATIVE(LiquidityParameters calldata liquidityParameters)
        external
        payable
        override
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        )
    {
        ILBPair _LBPair = ILBPair(
            _getLBPairInformation(
                liquidityParameters.tokenX, liquidityParameters.tokenY, liquidityParameters.binStep, Version.V2_1
            )
        );
        if (liquidityParameters.tokenX != _LBPair.getTokenX()) revert LBRouter__WrongTokenOrder();

        if (liquidityParameters.tokenX == _wnative && liquidityParameters.amountX == msg.value) {
            _wnativeDepositAndTransfer(address(_LBPair), msg.value);
            liquidityParameters.tokenY.safeTransferFrom(msg.sender, address(_LBPair), liquidityParameters.amountY);
        } else if (liquidityParameters.tokenY == _wnative && liquidityParameters.amountY == msg.value) {
            liquidityParameters.tokenX.safeTransferFrom(msg.sender, address(_LBPair), liquidityParameters.amountX);
            _wnativeDepositAndTransfer(address(_LBPair), msg.value);
        } else {
            revert LBRouter__WrongNativeLiquidityParameters(
                address(liquidityParameters.tokenX),
                address(liquidityParameters.tokenY),
                liquidityParameters.amountX,
                liquidityParameters.amountY,
                msg.value
            );
        }

        (amountXAdded, amountYAdded, amountXLeft, amountYLeft, depositIds, liquidityMinted) =
            _addLiquidity(liquidityParameters, _LBPair);
    }

    /**
     * @notice Remove liquidity while performing safety checks
     * @dev This function is compliant with fee on transfer tokens
     * @param tokenX The address of token X
     * @param tokenY The address of token Y
     * @param binStep The bin step of the LBPair
     * @param amountXMin The min amount to receive of token X
     * @param amountYMin The min amount to receive of token Y
     * @param ids The list of ids to burn
     * @param amounts The list of amounts to burn of each id in `_ids`
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountX Amount of token X returned
     * @return amountY Amount of token Y returned
     */
    function removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 amountX, uint256 amountY) {
        ILBPair _LBPair = ILBPair(_getLBPairInformation(tokenX, tokenY, binStep, Version.V2_1));
        bool isWrongOrder = tokenX != _LBPair.getTokenX();

        if (isWrongOrder) (amountXMin, amountYMin) = (amountYMin, amountXMin);

        (amountX, amountY) = _removeLiquidity(_LBPair, amountXMin, amountYMin, ids, amounts, to);

        if (isWrongOrder) (amountX, amountY) = (amountY, amountX);
    }

    /**
     * @notice Remove NATIVE liquidity while performing safety checks
     * @dev This function is **NOT** compliant with fee on transfer tokens.
     * This is wanted as it would make users pays the fee on transfer twice,
     * use the `removeLiquidity` function to remove liquidity with fee on transfer tokens.
     * @param token The address of token
     * @param binStep The bin step of the LBPair
     * @param amountTokenMin The min amount to receive of token
     * @param amountNATIVEMin The min amount to receive of NATIVE
     * @param ids The list of ids to burn
     * @param amounts The list of amounts to burn of each id in `_ids`
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountToken Amount of token returned
     * @return amountNATIVE Amount of NATIVE returned
     */
    function removeLiquidityNATIVE(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountNATIVEMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 amountToken, uint256 amountNATIVE) {
        IWNATIVE wnative = _wnative;

        ILBPair lbPair = ILBPair(_getLBPairInformation(token, IERC20(wnative), binStep, Version.V2_1));

        {
            bool isNATIVETokenY = IERC20(wnative) == lbPair.getTokenY();

            if (!isNATIVETokenY) {
                (amountTokenMin, amountNATIVEMin) = (amountNATIVEMin, amountTokenMin);
            }

            (uint256 amountX, uint256 amountY) =
                _removeLiquidity(lbPair, amountTokenMin, amountNATIVEMin, ids, amounts, address(this));

            (amountToken, amountNATIVE) = isNATIVETokenY ? (amountX, amountY) : (amountY, amountX);
        }

        token.safeTransfer(to, amountToken);

        wnative.withdraw(amountNATIVE);
        _safeTransferNATIVE(to, amountNATIVE);
    }

    /**
     * @notice Swaps exact tokens for tokens while performing safety checks
     * @param amountIn The amount of token to send
     * @param amountOutMin The min amount of token to receive
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountOut Output amount of the swap
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) verifyPathValidity(path) returns (uint256 amountOut) {
        address[] memory pairs = _getPairs(path.pairBinSteps, path.versions, path.tokenPath);

        path.tokenPath[0].safeTransferFrom(msg.sender, pairs[0], amountIn);

        amountOut = _swapExactTokensForTokens(amountIn, pairs, path.versions, path.tokenPath, to);

        if (amountOutMin > amountOut) revert LBRouter__InsufficientAmountOut(amountOutMin, amountOut);
    }

    /**
     * @notice Swaps exact tokens for NATIVE while performing safety checks
     * @param amountIn The amount of token to send
     * @param amountOutMinNATIVE The min amount of NATIVE to receive
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountOut Output amount of the swap
     */
    function swapExactTokensForNATIVE(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external override ensure(deadline) verifyPathValidity(path) returns (uint256 amountOut) {
        if (path.tokenPath[path.pairBinSteps.length] != IERC20(_wnative)) {
            revert LBRouter__InvalidTokenPath(address(path.tokenPath[path.pairBinSteps.length]));
        }

        address[] memory pairs = _getPairs(path.pairBinSteps, path.versions, path.tokenPath);

        path.tokenPath[0].safeTransferFrom(msg.sender, pairs[0], amountIn);

        amountOut = _swapExactTokensForTokens(amountIn, pairs, path.versions, path.tokenPath, address(this));

        if (amountOutMinNATIVE > amountOut) revert LBRouter__InsufficientAmountOut(amountOutMinNATIVE, amountOut);

        _wnative.withdraw(amountOut);
        _safeTransferNATIVE(to, amountOut);
    }

    /**
     * @notice Swaps exact NATIVE for tokens while performing safety checks
     * @param amountOutMin The min amount of token to receive
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountOut Output amount of the swap
     */
    function swapExactNATIVEForTokens(uint256 amountOutMin, Path memory path, address to, uint256 deadline)
        external
        payable
        override
        ensure(deadline)
        verifyPathValidity(path)
        returns (uint256 amountOut)
    {
        if (path.tokenPath[0] != IERC20(_wnative)) revert LBRouter__InvalidTokenPath(address(path.tokenPath[0]));

        address[] memory pairs = _getPairs(path.pairBinSteps, path.versions, path.tokenPath);

        _wnativeDepositAndTransfer(pairs[0], msg.value);

        amountOut = _swapExactTokensForTokens(msg.value, pairs, path.versions, path.tokenPath, to);

        if (amountOutMin > amountOut) revert LBRouter__InsufficientAmountOut(amountOutMin, amountOut);
    }

    /**
     * @notice Swaps tokens for exact tokens while performing safety checks
     * @param amountOut The amount of token to receive
     * @param amountInMax The max amount of token to send
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountsIn Input amounts of the swap
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) verifyPathValidity(path) returns (uint256[] memory amountsIn) {
        address[] memory pairs = _getPairs(path.pairBinSteps, path.versions, path.tokenPath);

        {
            amountsIn = _getAmountsIn(path.versions, pairs, path.tokenPath, amountOut);

            if (amountsIn[0] > amountInMax) revert LBRouter__MaxAmountInExceeded(amountInMax, amountsIn[0]);

            path.tokenPath[0].safeTransferFrom(msg.sender, pairs[0], amountsIn[0]);

            uint256 _amountOutReal = _swapTokensForExactTokens(pairs, path.versions, path.tokenPath, amountsIn, to);

            if (_amountOutReal < amountOut) revert LBRouter__InsufficientAmountOut(amountOut, _amountOutReal);
        }
    }

    /**
     * @notice Swaps tokens for exact NATIVE while performing safety checks
     * @param amountNATIVEOut The amount of NATIVE to receive
     * @param amountInMax The max amount of token to send
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountsIn path amounts for every step of the swap
     */
    function swapTokensForExactNATIVE(
        uint256 amountNATIVEOut,
        uint256 amountInMax,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external override ensure(deadline) verifyPathValidity(path) returns (uint256[] memory amountsIn) {
        if (path.tokenPath[path.pairBinSteps.length] != IERC20(_wnative)) {
            revert LBRouter__InvalidTokenPath(address(path.tokenPath[path.pairBinSteps.length]));
        }

        address[] memory pairs = _getPairs(path.pairBinSteps, path.versions, path.tokenPath);
        amountsIn = _getAmountsIn(path.versions, pairs, path.tokenPath, amountNATIVEOut);

        if (amountsIn[0] > amountInMax) revert LBRouter__MaxAmountInExceeded(amountInMax, amountsIn[0]);

        path.tokenPath[0].safeTransferFrom(msg.sender, pairs[0], amountsIn[0]);

        uint256 _amountOutReal =
            _swapTokensForExactTokens(pairs, path.versions, path.tokenPath, amountsIn, address(this));

        if (_amountOutReal < amountNATIVEOut) revert LBRouter__InsufficientAmountOut(amountNATIVEOut, _amountOutReal);

        _wnative.withdraw(_amountOutReal);
        _safeTransferNATIVE(to, _amountOutReal);
    }

    /**
     * @notice Swaps NATIVE for exact tokens while performing safety checks
     * @dev Will refund any NATIVE amount sent in excess to `msg.sender`
     * @param amountOut The amount of tokens to receive
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountsIn path amounts for every step of the swap
     */
    function swapNATIVEForExactTokens(uint256 amountOut, Path memory path, address to, uint256 deadline)
        external
        payable
        override
        ensure(deadline)
        verifyPathValidity(path)
        returns (uint256[] memory amountsIn)
    {
        if (path.tokenPath[0] != IERC20(_wnative)) revert LBRouter__InvalidTokenPath(address(path.tokenPath[0]));

        address[] memory pairs = _getPairs(path.pairBinSteps, path.versions, path.tokenPath);
        amountsIn = _getAmountsIn(path.versions, pairs, path.tokenPath, amountOut);

        if (amountsIn[0] > msg.value) revert LBRouter__MaxAmountInExceeded(msg.value, amountsIn[0]);

        _wnativeDepositAndTransfer(pairs[0], amountsIn[0]);

        uint256 amountOutReal = _swapTokensForExactTokens(pairs, path.versions, path.tokenPath, amountsIn, to);

        if (amountOutReal < amountOut) revert LBRouter__InsufficientAmountOut(amountOut, amountOutReal);

        if (msg.value > amountsIn[0]) _safeTransferNATIVE(msg.sender, msg.value - amountsIn[0]);
    }

    /**
     * @notice Swaps exact tokens for tokens while performing safety checks supporting for fee on transfer tokens
     * @param amountIn The amount of token to send
     * @param amountOutMin The min amount of token to receive
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountOut Output amount of the swap
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) verifyPathValidity(path) returns (uint256 amountOut) {
        address[] memory pairs = _getPairs(path.pairBinSteps, path.versions, path.tokenPath);

        IERC20 targetToken = path.tokenPath[pairs.length];

        uint256 balanceBefore = targetToken.balanceOf(to);

        path.tokenPath[0].safeTransferFrom(msg.sender, pairs[0], amountIn);

        _swapSupportingFeeOnTransferTokens(pairs, path.versions, path.tokenPath, to);

        amountOut = targetToken.balanceOf(to) - balanceBefore;
        if (amountOutMin > amountOut) revert LBRouter__InsufficientAmountOut(amountOutMin, amountOut);
    }

    /**
     * @notice Swaps exact tokens for NATIVE while performing safety checks supporting for fee on transfer tokens
     * @param amountIn The amount of token to send
     * @param amountOutMinNATIVE The min amount of NATIVE to receive
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountOut Output amount of the swap
     */
    function swapExactTokensForNATIVESupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external override ensure(deadline) verifyPathValidity(path) returns (uint256 amountOut) {
        if (path.tokenPath[path.pairBinSteps.length] != IERC20(_wnative)) {
            revert LBRouter__InvalidTokenPath(address(path.tokenPath[path.pairBinSteps.length]));
        }

        address[] memory pairs = _getPairs(path.pairBinSteps, path.versions, path.tokenPath);

        uint256 balanceBefore = _wnative.balanceOf(address(this));

        path.tokenPath[0].safeTransferFrom(msg.sender, pairs[0], amountIn);

        _swapSupportingFeeOnTransferTokens(pairs, path.versions, path.tokenPath, address(this));

        amountOut = _wnative.balanceOf(address(this)) - balanceBefore;
        if (amountOutMinNATIVE > amountOut) revert LBRouter__InsufficientAmountOut(amountOutMinNATIVE, amountOut);

        _wnative.withdraw(amountOut);
        _safeTransferNATIVE(to, amountOut);
    }

    /**
     * @notice Swaps exact NATIVE for tokens while performing safety checks supporting for fee on transfer tokens
     * @param amountOutMin The min amount of token to receive
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountOut Output amount of the swap
     */
    function swapExactNATIVEForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable override ensure(deadline) verifyPathValidity(path) returns (uint256 amountOut) {
        if (path.tokenPath[0] != IERC20(_wnative)) revert LBRouter__InvalidTokenPath(address(path.tokenPath[0]));

        address[] memory pairs = _getPairs(path.pairBinSteps, path.versions, path.tokenPath);

        IERC20 targetToken = path.tokenPath[pairs.length];

        uint256 balanceBefore = targetToken.balanceOf(to);

        _wnativeDepositAndTransfer(pairs[0], msg.value);

        _swapSupportingFeeOnTransferTokens(pairs, path.versions, path.tokenPath, to);

        amountOut = targetToken.balanceOf(to) - balanceBefore;
        if (amountOutMin > amountOut) revert LBRouter__InsufficientAmountOut(amountOutMin, amountOut);
    }

    /**
     * @notice Unstuck tokens that are sent to this contract by mistake
     * @dev Only callable by the factory owner
     * @param token The address of the token
     * @param to The address of the user to send back the tokens
     * @param amount The amount to send
     */
    function sweep(IERC20 token, address to, uint256 amount) external override onlyFactoryOwner {
        if (address(token) == address(0)) {
            if (amount == type(uint256).max) amount = address(this).balance;
            _safeTransferNATIVE(to, amount);
        } else {
            if (amount == type(uint256).max) amount = token.balanceOf(address(this));
            token.safeTransfer(to, amount);
        }
    }

    /**
     * @notice Unstuck LBTokens that are sent to this contract by mistake
     * @dev Only callable by the factory owner
     * @param lbToken The address of the LBToken
     * @param to The address of the user to send back the tokens
     * @param ids The list of token ids
     * @param amounts The list of amounts to send
     */
    function sweepLBToken(ILBToken lbToken, address to, uint256[] calldata ids, uint256[] calldata amounts)
        external
        override
        onlyFactoryOwner
    {
        lbToken.batchTransferFrom(address(this), to, ids, amounts);
    }

    /**
     * @notice Helper function to add liquidity
     * @param liq The liquidity parameter
     * @param pair LBPair where liquidity is deposited
     * @return amountXAdded Amount of token X added
     * @return amountYAdded Amount of token Y added
     * @return amountXLeft Amount of token X left
     * @return amountYLeft Amount of token Y left
     * @return depositIds The list of deposit ids
     * @return liquidityMinted The list of liquidity minted
     */
    function _addLiquidity(LiquidityParameters calldata liq, ILBPair pair)
        private
        ensure(liq.deadline)
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        )
    {
        unchecked {
            if (liq.deltaIds.length != liq.distributionX.length || liq.deltaIds.length != liq.distributionY.length) {
                revert LBRouter__LengthsMismatch();
            }

            if (liq.activeIdDesired > type(uint24).max || liq.idSlippage > type(uint24).max) {
                revert LBRouter__IdDesiredOverflows(liq.activeIdDesired, liq.idSlippage);
            }

            bytes32[] memory liquidityConfigs = new bytes32[](liq.deltaIds.length);
            depositIds = new uint256[](liq.deltaIds.length);
            {
                uint256 _activeId = pair.getActiveId();
                if (
                    liq.activeIdDesired + liq.idSlippage < _activeId || _activeId + liq.idSlippage < liq.activeIdDesired
                ) {
                    revert LBRouter__IdSlippageCaught(liq.activeIdDesired, liq.idSlippage, _activeId);
                }

                for (uint256 i; i < liquidityConfigs.length; ++i) {
                    int256 _id = int256(_activeId) + liq.deltaIds[i];

                    if (_id < 0 || uint256(_id) > type(uint24).max) revert LBRouter__IdOverflows(_id);
                    depositIds[i] = uint256(_id);
                    liquidityConfigs[i] = LiquidityConfigurations.encodeParams(
                        uint64(liq.distributionX[i]), uint64(liq.distributionY[i]), uint24(uint256(_id))
                    );
                }
            }

            bytes32 amountsReceived;
            bytes32 amountsLeft;
            (amountsReceived, amountsLeft, liquidityMinted) = pair.mint(liq.to, liquidityConfigs, liq.refundTo);

            amountXAdded = amountsReceived.decodeX();
            amountYAdded = amountsReceived.decodeY();

            if (amountXAdded < liq.amountXMin || amountYAdded < liq.amountYMin) {
                revert LBRouter__AmountSlippageCaught(liq.amountXMin, amountXAdded, liq.amountYMin, amountYAdded);
            }

            amountXLeft = amountsLeft.decodeX();
            amountYLeft = amountsLeft.decodeY();
        }
    }

    /**
     * @notice Helper function to return the amounts in
     * @param versions The list of versions (V1, V2 or V2_1)
     * @param pairs The list of pairs
     * @param tokenPath The swap path
     * @param amountOut The amount out
     * @return amountsIn The list of amounts in
     */
    function _getAmountsIn(
        Version[] memory versions,
        address[] memory pairs,
        IERC20[] memory tokenPath,
        uint256 amountOut
    ) private view returns (uint256[] memory amountsIn) {
        amountsIn = new uint256[](tokenPath.length);
        // Avoid doing -1, as `pairs.length == pairBinSteps.length-1`
        amountsIn[pairs.length] = amountOut;

        for (uint256 i = pairs.length; i != 0; i--) {
            IERC20 token = tokenPath[i - 1];
            Version version = versions[i - 1];
            address pair = pairs[i - 1];

            if (version == Version.V1) {
                (uint256 reserveIn, uint256 reserveOut,) = IJoePair(pair).getReserves();
                if (token > tokenPath[i]) {
                    (reserveIn, reserveOut) = (reserveOut, reserveIn);
                }

                uint256 amountOut_ = amountsIn[i];
                amountsIn[i - 1] = uint128(amountOut_.getAmountIn(reserveIn, reserveOut));
            } else if (version == Version.V2) {
                (amountsIn[i - 1],) = _legacyRouter.getSwapIn(
                    ILBLegacyPair(pair), uint128(amountsIn[i]), ILBLegacyPair(pair).tokenX() == token
                );
            } else {
                (amountsIn[i - 1],,) =
                    getSwapIn(ILBPair(pair), uint128(amountsIn[i]), ILBPair(pair).getTokenX() == token);
            }
        }
    }

    /**
     * @notice Helper function to remove liquidity
     * @param pair The address of the LBPair
     * @param amountXMin The min amount to receive of token X
     * @param amountYMin The min amount to receive of token Y
     * @param ids The list of ids to burn
     * @param amounts The list of amounts to burn of each id in `_ids`
     * @param to The address of the recipient
     * @return amountX The amount of token X sent by the pair
     * @return amountY The amount of token Y sent by the pair
     */
    function _removeLiquidity(
        ILBPair pair,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to
    ) private returns (uint256 amountX, uint256 amountY) {
        (bytes32[] memory amountsBurned) = pair.burn(msg.sender, to, ids, amounts);

        for (uint256 i; i < amountsBurned.length; ++i) {
            amountX += amountsBurned[i].decodeX();
            amountY += amountsBurned[i].decodeY();
        }

        if (amountX < amountXMin || amountY < amountYMin) {
            revert LBRouter__AmountSlippageCaught(amountXMin, amountX, amountYMin, amountY);
        }
    }

    /**
     * @notice Helper function to swap exact tokens for tokens
     * @param amountIn The amount of token sent
     * @param pairs The list of pairs
     * @param versions The list of versions (V1, V2 or V2_1)
     * @param tokenPath The swap path using the binSteps following `pairBinSteps`
     * @param to The address of the recipient
     * @return amountOut The amount of token sent to `to`
     */
    function _swapExactTokensForTokens(
        uint256 amountIn,
        address[] memory pairs,
        Version[] memory versions,
        IERC20[] memory tokenPath,
        address to
    ) private returns (uint256 amountOut) {
        IERC20 token;
        Version version;
        address recipient;
        address pair;

        IERC20 tokenNext = tokenPath[0];
        amountOut = amountIn;

        unchecked {
            for (uint256 i; i < pairs.length; ++i) {
                pair = pairs[i];
                version = versions[i];

                token = tokenNext;
                tokenNext = tokenPath[i + 1];

                recipient = i + 1 == pairs.length ? to : pairs[i + 1];

                if (version == Version.V1) {
                    (uint256 reserve0, uint256 reserve1,) = IJoePair(pair).getReserves();

                    if (token < tokenNext) {
                        amountOut = amountOut.getAmountOut(reserve0, reserve1);
                        IJoePair(pair).swap(0, amountOut, recipient, "");
                    } else {
                        amountOut = amountOut.getAmountOut(reserve1, reserve0);
                        IJoePair(pair).swap(amountOut, 0, recipient, "");
                    }
                } else if (version == Version.V2) {
                    bool swapForY = tokenNext == ILBLegacyPair(pair).tokenY();

                    (uint256 amountXOut, uint256 amountYOut) = ILBLegacyPair(pair).swap(swapForY, recipient);

                    if (swapForY) amountOut = amountYOut;
                    else amountOut = amountXOut;
                } else {
                    bool swapForY = tokenNext == ILBPair(pair).getTokenY();

                    (uint256 amountXOut, uint256 amountYOut) = ILBPair(pair).swap(swapForY, recipient).decode();

                    if (swapForY) amountOut = amountYOut;
                    else amountOut = amountXOut;
                }
            }
        }
    }

    /**
     * @notice Helper function to swap tokens for exact tokens
     * @param pairs The array of pairs
     * @param versions The list of versions (V1, V2 or V2_1)
     * @param tokenPath The swap path using the binSteps following `pairBinSteps`
     * @param amountsIn The list of amounts in
     * @param to The address of the recipient
     * @return amountOut The amount of token sent to `to`
     */
    function _swapTokensForExactTokens(
        address[] memory pairs,
        Version[] memory versions,
        IERC20[] memory tokenPath,
        uint256[] memory amountsIn,
        address to
    ) private returns (uint256 amountOut) {
        IERC20 token;
        address recipient;
        address pair;
        Version version;

        IERC20 tokenNext = tokenPath[0];

        unchecked {
            for (uint256 i; i < pairs.length; ++i) {
                pair = pairs[i];
                version = versions[i];

                token = tokenNext;
                tokenNext = tokenPath[i + 1];

                recipient = i + 1 == pairs.length ? to : pairs[i + 1];

                if (version == Version.V1) {
                    amountOut = amountsIn[i + 1];
                    if (token < tokenNext) {
                        IJoePair(pair).swap(0, amountOut, recipient, "");
                    } else {
                        IJoePair(pair).swap(amountOut, 0, recipient, "");
                    }
                } else if (version == Version.V2) {
                    bool swapForY = tokenNext == ILBLegacyPair(pair).tokenY();

                    (uint256 amountXOut, uint256 amountYOut) = ILBLegacyPair(pair).swap(swapForY, recipient);

                    if (swapForY) amountOut = amountYOut;
                    else amountOut = amountXOut;
                } else {
                    bool swapForY = tokenNext == ILBPair(pair).getTokenY();

                    (uint256 amountXOut, uint256 amountYOut) = ILBPair(pair).swap(swapForY, recipient).decode();

                    if (swapForY) amountOut = amountYOut;
                    else amountOut = amountXOut;
                }
            }
        }
    }

    /**
     * @notice Helper function to swap exact tokens supporting for fee on transfer tokens
     * @param pairs The list of pairs
     * @param versions The list of versions (V1, V2 or V2_1)
     * @param tokenPath The swap path using the binSteps following `pairBinSteps`
     * @param to The address of the recipient
     */
    function _swapSupportingFeeOnTransferTokens(
        address[] memory pairs,
        Version[] memory versions,
        IERC20[] memory tokenPath,
        address to
    ) private {
        IERC20 token;
        Version version;
        address recipient;
        address pair;

        IERC20 tokenNext = tokenPath[0];

        unchecked {
            for (uint256 i; i < pairs.length; ++i) {
                pair = pairs[i];
                version = versions[i];

                token = tokenNext;
                tokenNext = tokenPath[i + 1];

                recipient = i + 1 == pairs.length ? to : pairs[i + 1];

                if (version == Version.V1) {
                    (uint256 _reserve0, uint256 _reserve1,) = IJoePair(pair).getReserves();
                    if (token < tokenNext) {
                        uint256 amountIn = token.balanceOf(pair) - _reserve0;
                        uint256 amountOut = amountIn.getAmountOut(_reserve0, _reserve1);

                        IJoePair(pair).swap(0, amountOut, recipient, "");
                    } else {
                        uint256 amountIn = token.balanceOf(pair) - _reserve1;
                        uint256 amountOut = amountIn.getAmountOut(_reserve1, _reserve0);

                        IJoePair(pair).swap(amountOut, 0, recipient, "");
                    }
                } else if (version == Version.V2) {
                    ILBLegacyPair(pair).swap(tokenNext == ILBLegacyPair(pair).tokenY(), recipient);
                } else {
                    ILBPair(pair).swap(tokenNext == ILBPair(pair).getTokenY(), recipient);
                }
            }
        }
    }

    /**
     * @notice Helper function to return the address of the LBPair
     * @dev Revert if the pair is not created yet
     * @param tokenX The address of the tokenX
     * @param tokenY The address of the tokenY
     * @param binStep The bin step of the LBPair
     * @param version The version of the LBPair
     * @return lbPair The address of the LBPair
     */
    function _getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep, Version version)
        private
        view
        returns (address lbPair)
    {
        if (version == Version.V2) {
            lbPair = address(_legacyFactory.getLBPairInformation(tokenX, tokenY, binStep).LBPair);
        } else {
            lbPair = address(_factory.getLBPairInformation(tokenX, tokenY, binStep).LBPair);
        }

        if (lbPair == address(0)) {
            revert LBRouter__PairNotCreated(address(tokenX), address(tokenY), binStep);
        }
    }

    /**
     * @notice Helper function to return the address of the pair (v1 or v2, according to `binStep`)
     * @dev Revert if the pair is not created yet
     * @param tokenX The address of the tokenX
     * @param tokenY The address of the tokenY
     * @param binStep The bin step of the LBPair
     * @param version The version of the LBPair
     * @return pair The address of the pair of binStep `binStep`
     */
    function _getPair(IERC20 tokenX, IERC20 tokenY, uint256 binStep, Version version)
        private
        view
        returns (address pair)
    {
        if (version == Version.V1) {
            pair = _factoryV1.getPair(address(tokenX), address(tokenY));
            if (pair == address(0)) revert LBRouter__PairNotCreated(address(tokenX), address(tokenY), binStep);
        } else {
            pair = address(_getLBPairInformation(tokenX, tokenY, binStep, version));
        }
    }

    /**
     * @notice Helper function to return a list of pairs
     * @param pairBinSteps The list of bin steps
     * @param versions The list of versions (V1, V2 or V2_1)
     * @param tokenPath The swap path using the binSteps following `pairBinSteps`
     * @return pairs The list of pairs
     */
    function _getPairs(uint256[] memory pairBinSteps, Version[] memory versions, IERC20[] memory tokenPath)
        private
        view
        returns (address[] memory pairs)
    {
        pairs = new address[](pairBinSteps.length);

        IERC20 token;
        IERC20 tokenNext = tokenPath[0];
        unchecked {
            for (uint256 i; i < pairs.length; ++i) {
                token = tokenNext;
                tokenNext = tokenPath[i + 1];

                pairs[i] = _getPair(token, tokenNext, pairBinSteps[i], versions[i]);
            }
        }
    }

    /**
     * @notice Helper function to transfer NATIVE
     * @param to The address of the recipient
     * @param amount The NATIVE amount to send
     */
    function _safeTransferNATIVE(address to, uint256 amount) private {
        (bool success,) = to.call{value: amount}("");
        if (!success) revert LBRouter__FailedToSendNATIVE(to, amount);
    }

    /**
     * @notice Helper function to deposit and transfer _wnative
     * @param to The address of the recipient
     * @param amount The NATIVE amount to wrap
     */
    function _wnativeDepositAndTransfer(address to, uint256 amount) private {
        _wnative.deposit{value: amount}();
        _wnative.safeTransfer(to, amount);
    }
}
interface ILBLegacyToken is IERC165 {
    event TransferSingle(address indexed sender, address indexed from, address indexed to, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory batchBalances);

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata id, uint256[] calldata amount)
        external;
}
interface IWNATIVE is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}
library JoeLibrary {
    error JoeLibrary__AddressZero();
    error JoeLibrary__IdenticalAddresses();
    error JoeLibrary__InsufficientAmount();
    error JoeLibrary__InsufficientLiquidity();

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert JoeLibrary__IdenticalAddresses();
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert JoeLibrary__AddressZero();
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        if (amountA == 0) revert JoeLibrary__InsufficientAmount();
        if (reserveA == 0 || reserveB == 0) revert JoeLibrary__InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert JoeLibrary__InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert JoeLibrary__InsufficientLiquidity();
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        if (amountOut == 0) revert JoeLibrary__InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert JoeLibrary__InsufficientLiquidity();
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }
}
library LiquidityConfigurations {
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using Encoded for bytes32;

    error LiquidityConfigurations__InvalidConfig();

    uint256 private constant OFFSET_ID = 0;
    uint256 private constant OFFSET_DISTRIBUTION_Y = 24;
    uint256 private constant OFFSET_DISTRIBUTION_X = 88;

    uint256 private constant PRECISION = 1e18;

    /**
     * @dev Encode the distributionX, distributionY and id into a single bytes32
     * @param distributionX The distribution of the first token
     * @param distributionY The distribution of the second token
     * @param id The id of the pool
     * @return config The encoded config as follows:
     * [0 - 24[: id
     * [24 - 88[: distributionY
     * [88 - 152[: distributionX
     * [152 - 256[: empty
     */
    function encodeParams(uint64 distributionX, uint64 distributionY, uint24 id)
        internal
        pure
        returns (bytes32 config)
    {
        config = config.set(distributionX, Encoded.MASK_UINT64, OFFSET_DISTRIBUTION_X);
        config = config.set(distributionY, Encoded.MASK_UINT64, OFFSET_DISTRIBUTION_Y);
        config = config.set(id, Encoded.MASK_UINT24, OFFSET_ID);
    }

    /**
     * @dev Decode the distributionX, distributionY and id from a single bytes32
     * @param config The encoded config as follows:
     * [0 - 24[: id
     * [24 - 88[: distributionY
     * [88 - 152[: distributionX
     * [152 - 256[: empty
     * @return distributionX The distribution of the first token
     * @return distributionY The distribution of the second token
     * @return id The id of the bin to add the liquidity to
     */
    function decodeParams(bytes32 config)
        internal
        pure
        returns (uint64 distributionX, uint64 distributionY, uint24 id)
    {
        distributionX = config.decodeUint64(OFFSET_DISTRIBUTION_X);
        distributionY = config.decodeUint64(OFFSET_DISTRIBUTION_Y);
        id = config.decodeUint24(OFFSET_ID);

        if (uint256(config) > type(uint152).max || distributionX > PRECISION || distributionY > PRECISION) {
            revert LiquidityConfigurations__InvalidConfig();
        }
    }

    /**
     * @dev Get the amounts and id from a config and amountsIn
     * @param config The encoded config as follows:
     * [0 - 24[: id
     * [24 - 88[: distributionY
     * [88 - 152[: distributionX
     * [152 - 256[: empty
     * @param amountsIn The amounts to distribute as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return amounts The distributed amounts as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return id The id of the bin to add the liquidity to
     */
    function getAmountsAndId(bytes32 config, bytes32 amountsIn) internal pure returns (bytes32, uint24) {
        (uint64 distributionX, uint64 distributionY, uint24 id) = decodeParams(config);

        (uint128 x1, uint128 x2) = amountsIn.decode();

        assembly {
            x1 := div(mul(x1, distributionX), PRECISION)
            x2 := div(mul(x2, distributionY), PRECISION)
        }

        return (x1.encode(x2), id);
    }
}
interface ILBLegacyRouter {
    struct LiquidityParameters {
        IERC20 tokenX;
        IERC20 tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        uint256 deadline;
    }

    function factory() external view returns (address);

    function wavax() external view returns (address);

    function oldFactory() external view returns (address);

    function getIdFromPrice(ILBLegacyPair LBPair, uint256 price) external view returns (uint24);

    function getPriceFromId(ILBLegacyPair LBPair, uint24 id) external view returns (uint256);

    function getSwapIn(ILBLegacyPair lbPair, uint256 amountOut, bool swapForY)
        external
        view
        returns (uint256 amountIn, uint256 feesIn);

    function getSwapOut(ILBLegacyPair lbPair, uint256 amountIn, bool swapForY)
        external
        view
        returns (uint256 amountOut, uint256 feesIn);

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBLegacyPair pair);

    function addLiquidity(LiquidityParameters calldata liquidityParameters)
        external
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function addLiquidityAVAX(LiquidityParameters calldata liquidityParameters)
        external
        payable
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function removeLiquidityAVAX(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMinAVAX,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amountsIn);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinAVAX,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function sweep(IERC20 token, address to, uint256 amount) external;

    function sweepLBToken(ILBToken _lbToken, address _to, uint256[] calldata _ids, uint256[] calldata _amounts)
        external;
}
interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}
interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__AlreadyInitialized();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function forceDecay() external;
}
interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}
library TokenHelper {
    using AddressHelper for address;

    error TokenHelper__TransferFailed();

    /**
     * @notice Transfers token and reverts if the transfer fails
     * @param token The address of the token
     * @param owner The owner of the tokens
     * @param recipient The address of the recipient
     * @param amount The amount to send
     */
    function safeTransferFrom(IERC20 token, address owner, address recipient, uint256 amount) internal {
        bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, owner, recipient, amount);

        bytes memory returnData = address(token).callAndCatch(data);

        if (returnData.length > 0 && !abi.decode(returnData, (bool))) revert TokenHelper__TransferFailed();
    }

    /**
     * @notice Transfers token and reverts if the transfer fails
     * @param token The address of the token
     * @param recipient The address of the recipient
     * @param amount The amount to send
     */
    function safeTransfer(IERC20 token, address recipient, uint256 amount) internal {
        bytes memory data = abi.encodeWithSelector(token.transfer.selector, recipient, amount);

        bytes memory returnData = address(token).callAndCatch(data);

        if (returnData.length > 0 && !abi.decode(returnData, (bool))) revert TokenHelper__TransferFailed();
    }
}
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}
interface ILBRouter {
    error LBRouter__SenderIsNotWNATIVE();
    error LBRouter__PairNotCreated(address tokenX, address tokenY, uint256 binStep);
    error LBRouter__WrongAmounts(uint256 amount, uint256 reserve);
    error LBRouter__SwapOverflows(uint256 id);
    error LBRouter__BrokenSwapSafetyCheck();
    error LBRouter__NotFactoryOwner();
    error LBRouter__TooMuchTokensIn(uint256 excess);
    error LBRouter__BinReserveOverflows(uint256 id);
    error LBRouter__IdOverflows(int256 id);
    error LBRouter__LengthsMismatch();
    error LBRouter__WrongTokenOrder();
    error LBRouter__IdSlippageCaught(uint256 activeIdDesired, uint256 idSlippage, uint256 activeId);
    error LBRouter__AmountSlippageCaught(uint256 amountXMin, uint256 amountX, uint256 amountYMin, uint256 amountY);
    error LBRouter__IdDesiredOverflows(uint256 idDesired, uint256 idSlippage);
    error LBRouter__FailedToSendNATIVE(address recipient, uint256 amount);
    error LBRouter__DeadlineExceeded(uint256 deadline, uint256 currentTimestamp);
    error LBRouter__AmountSlippageBPTooBig(uint256 amountSlippage);
    error LBRouter__InsufficientAmountOut(uint256 amountOutMin, uint256 amountOut);
    error LBRouter__MaxAmountInExceeded(uint256 amountInMax, uint256 amountIn);
    error LBRouter__InvalidTokenPath(address wrongToken);
    error LBRouter__InvalidVersion(uint256 version);
    error LBRouter__WrongNativeLiquidityParameters(
        address tokenX, address tokenY, uint256 amountX, uint256 amountY, uint256 msgValue
    );

    /**
     * @dev This enum represents the version of the pair requested
     * - V1: Joe V1 pair
     * - V2: LB pair V2. Also called legacyPair
     * - V2_1: LB pair V2.1 (current version)
     */
    enum Version {
        V1,
        V2,
        V2_1
    }

    /**
     * @dev The liquidity parameters, such as:
     * - tokenX: The address of token X
     * - tokenY: The address of token Y
     * - binStep: The bin step of the pair
     * - amountX: The amount to send of token X
     * - amountY: The amount to send of token Y
     * - amountXMin: The min amount of token X added to liquidity
     * - amountYMin: The min amount of token Y added to liquidity
     * - activeIdDesired: The active id that user wants to add liquidity from
     * - idSlippage: The number of id that are allowed to slip
     * - deltaIds: The list of delta ids to add liquidity (`deltaId = activeId - desiredId`)
     * - distributionX: The distribution of tokenX with sum(distributionX) = 100e18 (100%) or 0 (0%)
     * - distributionY: The distribution of tokenY with sum(distributionY) = 100e18 (100%) or 0 (0%)
     * - to: The address of the recipient
     * - refundTo: The address of the recipient of the refunded tokens if too much tokens are sent
     * - deadline: The deadline of the transaction
     */
    struct LiquidityParameters {
        IERC20 tokenX;
        IERC20 tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        address refundTo;
        uint256 deadline;
    }

    /**
     * @dev The path parameters, such as:
     * - pairBinSteps: The list of bin steps of the pairs to go through
     * - versions: The list of versions of the pairs to go through
     * - tokenPath: The list of tokens in the path to go through
     */
    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function getFactory() external view returns (ILBFactory);

    function getLegacyFactory() external view returns (ILBLegacyFactory);

    function getV1Factory() external view returns (IJoeFactory);

    function getLegacyRouter() external view returns (ILBLegacyRouter);

    function getWNATIVE() external view returns (IWNATIVE);

    function getIdFromPrice(ILBPair LBPair, uint256 price) external view returns (uint24);

    function getPriceFromId(ILBPair LBPair, uint24 id) external view returns (uint256);

    function getSwapIn(ILBPair LBPair, uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(ILBPair LBPair, uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function addLiquidity(LiquidityParameters calldata liquidityParameters)
        external
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        );

    function addLiquidityNATIVE(LiquidityParameters calldata liquidityParameters)
        external
        payable
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        );

    function removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function removeLiquidityNATIVE(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountNATIVEMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountNATIVE);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForNATIVE(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNATIVEForTokens(uint256 amountOutMin, Path memory path, address to, uint256 deadline)
        external
        payable
        returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapTokensForExactNATIVE(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapNATIVEForExactTokens(uint256 amountOut, Path memory path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amountsIn);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForNATIVESupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNATIVEForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function sweep(IERC20 token, address to, uint256 amount) external;

    function sweepLBToken(ILBToken _lbToken, address _to, uint256[] calldata _ids, uint256[] calldata _amounts)
        external;
}
library AddressHelper {
    error AddressHelper__NonContract();
    error AddressHelper__CallFailed();

    /**
     * @notice Private view function to perform a low level call on `target`
     * @dev Revert if the call doesn't succeed
     * @param target The address of the account
     * @param data The data to execute on `target`
     * @return returnData The data returned by the call
     */
    function callAndCatch(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call(data);

        if (success) {
            if (returnData.length == 0 && !isContract(target)) revert AddressHelper__NonContract();
        } else {
            if (returnData.length == 0) {
                revert AddressHelper__CallFailed();
            } else {
                // Look for revert reason and bubble it up if present
                assembly {
                    revert(add(32, returnData), mload(returnData))
                }
            }
        }

        return returnData;
    }

    /**
     * @notice Private view function to return if an address is a contract
     * @dev It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * @param account The address of the account
     * @return Whether the account is a contract (true) or not (false)
     */
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
interface ILBFactory is IPendingOwnable {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__PresetIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface ILBLegacyFactory is IPendingOwnable {
    /// @dev Structure to store the LBPair information, such as:
    /// - binStep: The bin step of the LBPair
    /// - LBPair: The address of the LBPair
    /// - createdByOwner: Whether the pair was created by the owner of the factory
    /// - ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
    struct LBPairInformation {
        uint16 binStep;
        ILBLegacyPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBLegacyPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event FeeParametersSet(
        address indexed sender,
        ILBLegacyPair indexed LBPair,
        uint256 binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event FactoryLockedStatusUpdated(bool unlocked);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBLegacyPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator,
        uint256 sampleLifetime
    );

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function MAX_FEE() external pure returns (uint256);

    function MIN_BIN_STEP() external pure returns (uint256);

    function MAX_BIN_STEP() external pure returns (uint256);

    function MAX_PROTOCOL_SHARE() external pure returns (uint256);

    function LBPairImplementation() external view returns (address);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAsset(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function creationUnlocked() external view returns (bool);

    function allLBPairs(uint256 id) external returns (ILBLegacyPair);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint16 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            uint256 sampleLifetime
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address LBPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBLegacyPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint256 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint16 sampleLifetime
    ) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function setFactoryLockedState(bool locked) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBLegacyPair LBPair) external;
}

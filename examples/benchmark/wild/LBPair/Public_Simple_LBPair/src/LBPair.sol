pragma solidity 0.8.10;



contract LBPair is LBToken, ReentrancyGuard, Clone, ILBPair {

    modifier onlyFactory() {
        if (msg.sender != address(_factory)) revert LBPair__OnlyFactory();
        _;
    }
    modifier onlyProtocolFeeRecipient() {
        if (msg.sender != _factory.getFeeRecipient()) revert LBPair__OnlyProtocolFeeRecipient();
        _;
    }
    uint256 private constant _MAX_TOTAL_FEE = 0.1e18; // 10%
    ILBFactory private immutable _factory;
    bytes32 private _parameters;
    bytes32 private _reserves;
    bytes32 private _protocolFees;
    TreeMath.TreeUint24 private _tree;
    OracleHelper.Oracle private _oracle;
    constructor(ILBFactory factory_) {
        _factory = factory_;

        // Disable the initialize function
        _parameters = bytes32(uint256(1));
    }
    function getFactory() external view override returns (ILBFactory factory) {
        return _factory;
    }
    function getTokenX() external pure override returns (IERC20 tokenX) {
        return _tokenX();
    }
    function getTokenY() external pure override returns (IERC20 tokenY) {
        return _tokenY();
    }
    function getBinStep() external pure override returns (uint16) {
        return _binStep();
    }
    function getReserves() external view override returns (uint128 reserveX, uint128 reserveY) {
        (reserveX, reserveY) = _reserves.sub(_protocolFees).decode();
    }
    function getActiveId() external view override returns (uint24 activeId) {
        activeId = _parameters.getActiveId();
    }
    function getNextNonEmptyBin(bool swapForY, uint24 id) external view override returns (uint24 nextId) {
        nextId = _getNextNonEmptyBin(swapForY, id);
    }
    function getProtocolFees() external view override returns (uint128 protocolFeeX, uint128 protocolFeeY) {
        (protocolFeeX, protocolFeeY) = _protocolFees.decode();
    }
    function getStaticFeeParameters()
        external
        view
        override
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        )
    {
        bytes32 parameters = _parameters;

        baseFactor = parameters.getBaseFactor();
        filterPeriod = parameters.getFilterPeriod();
        decayPeriod = parameters.getDecayPeriod();
        reductionFactor = parameters.getReductionFactor();
        variableFeeControl = parameters.getVariableFeeControl();
        protocolShare = parameters.getProtocolShare();
        maxVolatilityAccumulator = parameters.getMaxVolatilityAccumulator();
    }
    function getVariableFeeParameters()
        external
        view
        override
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate)
    {
        bytes32 parameters = _parameters;

        volatilityAccumulator = parameters.getVolatilityAccumulator();
        volatilityReference = parameters.getVolatilityReference();
        idReference = parameters.getIdReference();
        timeOfLastUpdate = parameters.getTimeOfLastUpdate();
    }
    function getOracleParameters()
        external
        view
        override
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp)
    {
        bytes32 parameters = _parameters;

        sampleLifetime = uint8(OracleHelper._MAX_SAMPLE_LIFETIME);

        uint16 oracleId = parameters.getOracleId();
        if (oracleId > 0) {
            bytes32 sample;
            (sample, activeSize) = _oracle.getActiveSampleAndSize(oracleId);

            size = sample.getOracleLength();
            lastUpdated = sample.getSampleLastUpdate();

            if (lastUpdated == 0) activeSize = 0;

            if (activeSize > 0) {
                unchecked {
                    sample = _oracle.getSample(1 + (oracleId % activeSize));
                }
                firstTimestamp = sample.getSampleLastUpdate();
            }
        }
    }
    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        override
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed)
    {
        bytes32 parameters = _parameters;
        uint16 oracleId = parameters.getOracleId();

        if (oracleId == 0 || lookupTimestamp > block.timestamp) return (0, 0, 0);

        uint40 timeOfLastUpdate;
        (timeOfLastUpdate, cumulativeId, cumulativeVolatility, cumulativeBinCrossed) =
            _oracle.getSampleAt(oracleId, lookupTimestamp);

        if (timeOfLastUpdate < lookupTimestamp) {
            parameters.updateVolatilityParameters(parameters.getActiveId());

            uint40 deltaTime = lookupTimestamp - timeOfLastUpdate;

            cumulativeId += uint64(parameters.getActiveId()) * deltaTime;
            cumulativeVolatility += uint64(parameters.getVolatilityAccumulator()) * deltaTime;
        }
    }
    function getPriceFromId(uint24 id) external pure override returns (uint256 price) {
        price = id.getPriceFromId(_binStep());
    }
    function getIdFromPrice(uint256 price) external pure override returns (uint24 id) {
        id = price.getIdFromPrice(_binStep());
    }
    function _tokenX() internal pure returns (IERC20) {
        return IERC20(_getArgAddress(0));
    }
    function _tokenY() internal pure returns (IERC20) {
        return IERC20(_getArgAddress(20));
    }
    function _binStep() internal pure returns (uint16) {
        return _getArgUint16(40);
    }
}
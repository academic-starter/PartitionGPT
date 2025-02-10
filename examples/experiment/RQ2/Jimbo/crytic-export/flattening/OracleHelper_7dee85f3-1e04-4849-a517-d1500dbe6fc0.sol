pragma solidity 0.8.10;
library PairParameterHelper {
    using SafeCast for uint256;
    using Encoded for bytes32;

    error PairParametersHelper__InvalidParameter();

    uint256 internal constant OFFSET_BASE_FACTOR = 0;
    uint256 internal constant OFFSET_FILTER_PERIOD = 16;
    uint256 internal constant OFFSET_DECAY_PERIOD = 28;
    uint256 internal constant OFFSET_REDUCTION_FACTOR = 40;
    uint256 internal constant OFFSET_VAR_FEE_CONTROL = 54;
    uint256 internal constant OFFSET_PROTOCOL_SHARE = 78;
    uint256 internal constant OFFSET_MAX_VOL_ACC = 92;
    uint256 internal constant OFFSET_VOL_ACC = 112;
    uint256 internal constant OFFSET_VOL_REF = 132;
    uint256 internal constant OFFSET_ID_REF = 152;
    uint256 internal constant OFFSET_TIME_LAST_UPDATE = 176;
    uint256 internal constant OFFSET_ORACLE_ID = 216;
    uint256 internal constant OFFSET_ACTIVE_ID = 232;

    uint256 internal constant MASK_STATIC_PARAMETER = 0xffffffffffffffffffffffffffff;

    /**
     * @dev Get the base factor from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 16[: base factor (16 bits)
     * [16 - 256[: other parameters
     * @return baseFactor The base factor
     */
    function getBaseFactor(bytes32 params) internal pure returns (uint16 baseFactor) {
        baseFactor = params.decodeUint16(OFFSET_BASE_FACTOR);
    }

    /**
     * @dev Get the filter period from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 16[: other parameters
     * [16 - 28[: filter period (12 bits)
     * [28 - 256[: other parameters
     * @return filterPeriod The filter period
     */
    function getFilterPeriod(bytes32 params) internal pure returns (uint16 filterPeriod) {
        filterPeriod = params.decodeUint12(OFFSET_FILTER_PERIOD);
    }

    /**
     * @dev Get the decay period from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 28[: other parameters
     * [28 - 40[: decay period (12 bits)
     * [40 - 256[: other parameters
     * @return decayPeriod The decay period
     */
    function getDecayPeriod(bytes32 params) internal pure returns (uint16 decayPeriod) {
        decayPeriod = params.decodeUint12(OFFSET_DECAY_PERIOD);
    }

    /**
     * @dev Get the reduction factor from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 40[: other parameters
     * [40 - 54[: reduction factor (14 bits)
     * [54 - 256[: other parameters
     * @return reductionFactor The reduction factor
     */
    function getReductionFactor(bytes32 params) internal pure returns (uint16 reductionFactor) {
        reductionFactor = params.decodeUint14(OFFSET_REDUCTION_FACTOR);
    }

    /**
     * @dev Get the variable fee control from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 54[: other parameters
     * [54 - 78[: variable fee control (24 bits)
     * [78 - 256[: other parameters
     * @return variableFeeControl The variable fee control
     */
    function getVariableFeeControl(bytes32 params) internal pure returns (uint24 variableFeeControl) {
        variableFeeControl = params.decodeUint24(OFFSET_VAR_FEE_CONTROL);
    }

    /**
     * @dev Get the protocol share from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 78[: other parameters
     * [78 - 92[: protocol share (14 bits)
     * [92 - 256[: other parameters
     * @return protocolShare The protocol share
     */
    function getProtocolShare(bytes32 params) internal pure returns (uint16 protocolShare) {
        protocolShare = params.decodeUint14(OFFSET_PROTOCOL_SHARE);
    }

    /**
     * @dev Get the max volatility accumulator from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 92[: other parameters
     * [92 - 112[: max volatility accumulator (20 bits)
     * [112 - 256[: other parameters
     * @return maxVolatilityAccumulator The max volatility accumulator
     */
    function getMaxVolatilityAccumulator(bytes32 params) internal pure returns (uint24 maxVolatilityAccumulator) {
        maxVolatilityAccumulator = params.decodeUint20(OFFSET_MAX_VOL_ACC);
    }

    /**
     * @dev Get the volatility accumulator from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 112[: other parameters
     * [112 - 132[: volatility accumulator (20 bits)
     * [132 - 256[: other parameters
     * @return volatilityAccumulator The volatility accumulator
     */
    function getVolatilityAccumulator(bytes32 params) internal pure returns (uint24 volatilityAccumulator) {
        volatilityAccumulator = params.decodeUint20(OFFSET_VOL_ACC);
    }

    /**
     * @dev Get the volatility reference from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 132[: other parameters
     * [132 - 152[: volatility reference (20 bits)
     * [152 - 256[: other parameters
     * @return volatilityReference The volatility reference
     */
    function getVolatilityReference(bytes32 params) internal pure returns (uint24 volatilityReference) {
        volatilityReference = params.decodeUint20(OFFSET_VOL_REF);
    }

    /**
     * @dev Get the index reference from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 152[: other parameters
     * [152 - 176[: index reference (24 bits)
     * [176 - 256[: other parameters
     * @return idReference The index reference
     */
    function getIdReference(bytes32 params) internal pure returns (uint24 idReference) {
        idReference = params.decodeUint24(OFFSET_ID_REF);
    }

    /**
     * @dev Get the time of last update from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 176[: other parameters
     * [176 - 216[: time of last update (40 bits)
     * [216 - 256[: other parameters
     * @return timeOflastUpdate The time of last update
     */
    function getTimeOfLastUpdate(bytes32 params) internal pure returns (uint40 timeOflastUpdate) {
        timeOflastUpdate = params.decodeUint40(OFFSET_TIME_LAST_UPDATE);
    }

    /**
     * @dev Get the oracle id from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 216[: other parameters
     * [216 - 232[: oracle id (16 bits)
     * [232 - 256[: other parameters
     * @return oracleId The oracle id
     */
    function getOracleId(bytes32 params) internal pure returns (uint16 oracleId) {
        oracleId = params.decodeUint16(OFFSET_ORACLE_ID);
    }

    /**
     * @dev Get the active index from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 232[: other parameters
     * [232 - 256[: active index (24 bits)
     * @return activeId The active index
     */
    function getActiveId(bytes32 params) internal pure returns (uint24 activeId) {
        activeId = params.decodeUint24(OFFSET_ACTIVE_ID);
    }

    /**
     * @dev Get the delta between the current active index and the cached active index
     * @param params The encoded pair parameters, as follows:
     * [0 - 232[: other parameters
     * [232 - 256[: active index (24 bits)
     * @param activeId The current active index
     * @return The delta
     */
    function getDeltaId(bytes32 params, uint24 activeId) internal pure returns (uint24) {
        uint24 id = getActiveId(params);
        unchecked {
            return activeId > id ? activeId - id : id - activeId;
        }
    }

    /**
     * @dev Calculates the base fee, with 18 decimals
     * @param params The encoded pair parameters
     * @param binStep The bin step (in basis points)
     * @return baseFee The base fee
     */
    function getBaseFee(bytes32 params, uint16 binStep) internal pure returns (uint256) {
        unchecked {
            // Base factor is in basis points, binStep is in basis points, so we multiply by 1e10
            return uint256(getBaseFactor(params)) * binStep * 1e10;
        }
    }

    /**
     * @dev Calculates the variable fee
     * @param params The encoded pair parameters
     * @param binStep The bin step (in basis points)
     * @return variableFee The variable fee
     */
    function getVariableFee(bytes32 params, uint16 binStep) internal pure returns (uint256 variableFee) {
        uint256 variableFeeControl = getVariableFeeControl(params);

        if (variableFeeControl != 0) {
            unchecked {
                // The volatility accumulator is in basis points, binStep is in basis points,
                // and the variable fee control is in basis points, so the result is in 100e18th
                uint256 prod = uint256(getVolatilityAccumulator(params)) * binStep;
                variableFee = (prod * prod * variableFeeControl + 99) / 100;
            }
        }
    }

    /**
     * @dev Calculates the total fee, which is the sum of the base fee and the variable fee
     * @param params The encoded pair parameters
     * @param binStep The bin step (in basis points)
     * @return totalFee The total fee
     */
    function getTotalFee(bytes32 params, uint16 binStep) internal pure returns (uint128) {
        unchecked {
            return (getBaseFee(params, binStep) + getVariableFee(params, binStep)).safe128();
        }
    }

    /**
     * @dev Set the oracle id in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param oracleId The oracle id
     * @return The updated encoded pair parameters
     */
    function setOracleId(bytes32 params, uint16 oracleId) internal pure returns (bytes32) {
        return params.set(oracleId, Encoded.MASK_UINT16, OFFSET_ORACLE_ID);
    }

    /**
     * @dev Set the volatility reference in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param volRef The volatility reference
     * @return The updated encoded pair parameters
     */
    function setVolatilityReference(bytes32 params, uint24 volRef) internal pure returns (bytes32) {
        if (volRef > Encoded.MASK_UINT20) revert PairParametersHelper__InvalidParameter();

        return params.set(volRef, Encoded.MASK_UINT20, OFFSET_VOL_REF);
    }

    /**
     * @dev Set the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param volAcc The volatility accumulator
     * @return The updated encoded pair parameters
     */
    function setVolatilityAccumulator(bytes32 params, uint24 volAcc) internal pure returns (bytes32) {
        if (volAcc > Encoded.MASK_UINT20) revert PairParametersHelper__InvalidParameter();

        return params.set(volAcc, Encoded.MASK_UINT20, OFFSET_VOL_ACC);
    }

    /**
     * @dev Set the active id in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param activeId The active id
     * @return newParams The updated encoded pair parameters
     */
    function setActiveId(bytes32 params, uint24 activeId) internal pure returns (bytes32 newParams) {
        return params.set(activeId, Encoded.MASK_UINT24, OFFSET_ACTIVE_ID);
    }

    /**
     * @dev Sets the static fee parameters in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param baseFactor The base factor
     * @param filterPeriod The filter period
     * @param decayPeriod The decay period
     * @param reductionFactor The reduction factor
     * @param variableFeeControl The variable fee control
     * @param protocolShare The protocol share
     * @param maxVolatilityAccumulator The max volatility accumulator
     * @return newParams The updated encoded pair parameters
     */
    function setStaticFeeParameters(
        bytes32 params,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) internal pure returns (bytes32 newParams) {
        if (
            filterPeriod > decayPeriod || decayPeriod > Encoded.MASK_UINT12
                || reductionFactor > Constants.BASIS_POINT_MAX || protocolShare > Constants.MAX_PROTOCOL_SHARE
                || maxVolatilityAccumulator > Encoded.MASK_UINT20
        ) revert PairParametersHelper__InvalidParameter();

        newParams = newParams.set(baseFactor, Encoded.MASK_UINT16, OFFSET_BASE_FACTOR);
        newParams = newParams.set(filterPeriod, Encoded.MASK_UINT12, OFFSET_FILTER_PERIOD);
        newParams = newParams.set(decayPeriod, Encoded.MASK_UINT12, OFFSET_DECAY_PERIOD);
        newParams = newParams.set(reductionFactor, Encoded.MASK_UINT14, OFFSET_REDUCTION_FACTOR);
        newParams = newParams.set(variableFeeControl, Encoded.MASK_UINT24, OFFSET_VAR_FEE_CONTROL);
        newParams = newParams.set(protocolShare, Encoded.MASK_UINT14, OFFSET_PROTOCOL_SHARE);
        newParams = newParams.set(maxVolatilityAccumulator, Encoded.MASK_UINT20, OFFSET_MAX_VOL_ACC);

        return params.set(uint256(newParams), MASK_STATIC_PARAMETER, 0);
    }

    /**
     * @dev Updates the index reference in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return newParams The updated encoded pair parameters
     */
    function updateIdReference(bytes32 params) internal pure returns (bytes32 newParams) {
        uint24 activeId = getActiveId(params);
        return params.set(activeId, Encoded.MASK_UINT24, OFFSET_ID_REF);
    }

    /**
     * @dev Updates the time of last update in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return newParams The updated encoded pair parameters
     */
    function updateTimeOfLastUpdate(bytes32 params) internal view returns (bytes32 newParams) {
        uint40 currentTime = block.timestamp.safe40();
        return params.set(currentTime, Encoded.MASK_UINT40, OFFSET_TIME_LAST_UPDATE);
    }

    /**
     * @dev Updates the volatility reference in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return The updated encoded pair parameters
     */
    function updateVolatilityReference(bytes32 params) internal pure returns (bytes32) {
        uint256 volAcc = getVolatilityAccumulator(params);
        uint256 reductionFactor = getReductionFactor(params);

        uint24 volRef;
        unchecked {
            volRef = uint24(volAcc * reductionFactor / Constants.BASIS_POINT_MAX);
        }

        return setVolatilityReference(params, volRef);
    }

    /**
     * @dev Updates the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param activeId The active id
     * @return The updated encoded pair parameters
     */
    function updateVolatilityAccumulator(bytes32 params, uint24 activeId) internal pure returns (bytes32) {
        uint256 idReference = getIdReference(params);

        uint256 deltaId;
        uint256 volAcc;

        unchecked {
            deltaId = activeId > idReference ? activeId - idReference : idReference - activeId;
            volAcc = (uint256(getVolatilityReference(params)) + deltaId * Constants.BASIS_POINT_MAX);
        }

        uint256 maxVolAcc = getMaxVolatilityAccumulator(params);

        volAcc = volAcc > maxVolAcc ? maxVolAcc : volAcc;

        return setVolatilityAccumulator(params, uint24(volAcc));
    }

    /**
     * @dev Updates the volatility reference and the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return The updated encoded pair parameters
     */
    function updateReferences(bytes32 params) internal view returns (bytes32) {
        uint256 dt = block.timestamp - getTimeOfLastUpdate(params);

        if (dt >= getFilterPeriod(params)) {
            params = updateIdReference(params);
            params = dt < getDecayPeriod(params) ? updateVolatilityReference(params) : setVolatilityReference(params, 0);
        }

        return updateTimeOfLastUpdate(params);
    }

    /**
     * @dev Updates the volatility reference and the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param activeId The active id
     * @return The updated encoded pair parameters
     */
    function updateVolatilityParameters(bytes32 params, uint24 activeId) internal view returns (bytes32) {
        params = updateReferences(params);
        return updateVolatilityAccumulator(params, activeId);
    }
}
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
library SampleMath {
    using Encoded for bytes32;

    uint256 internal constant OFFSET_ORACLE_LENGTH = 0;
    uint256 internal constant OFFSET_CUMULATIVE_ID = 16;
    uint256 internal constant OFFSET_CUMULATIVE_VOLATILITY = 80;
    uint256 internal constant OFFSET_CUMULATIVE_BIN_CROSSED = 144;
    uint256 internal constant OFFSET_SAMPLE_LIFETIME = 208;
    uint256 internal constant OFFSET_SAMPLE_CREATION = 216;

    /**
     * @dev Encodes a sample
     * @param oracleLength The oracle length
     * @param cumulativeId The cumulative id
     * @param cumulativeVolatility The cumulative volatility
     * @param cumulativeBinCrossed The cumulative bin crossed
     * @param sampleLifetime The sample lifetime
     * @param createdAt The sample creation timestamp
     * @return sample The encoded sample
     */
    function encode(
        uint16 oracleLength,
        uint64 cumulativeId,
        uint64 cumulativeVolatility,
        uint64 cumulativeBinCrossed,
        uint8 sampleLifetime,
        uint40 createdAt
    ) internal pure returns (bytes32 sample) {
        sample = sample.set(oracleLength, Encoded.MASK_UINT16, OFFSET_ORACLE_LENGTH);
        sample = sample.set(cumulativeId, Encoded.MASK_UINT64, OFFSET_CUMULATIVE_ID);
        sample = sample.set(cumulativeVolatility, Encoded.MASK_UINT64, OFFSET_CUMULATIVE_VOLATILITY);
        sample = sample.set(cumulativeBinCrossed, Encoded.MASK_UINT64, OFFSET_CUMULATIVE_BIN_CROSSED);
        sample = sample.set(sampleLifetime, Encoded.MASK_UINT8, OFFSET_SAMPLE_LIFETIME);
        sample = sample.set(createdAt, Encoded.MASK_UINT40, OFFSET_SAMPLE_CREATION);
    }

    /**
     * @dev Gets the oracle length from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 16[: oracle length (16 bits)
     * [16 - 256[: any (240 bits)
     * @return length The oracle length
     */
    function getOracleLength(bytes32 sample) internal pure returns (uint16 length) {
        return sample.decodeUint16(0);
    }

    /**
     * @dev Gets the cumulative id from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 16[: any (16 bits)
     * [16 - 80[: cumulative id (64 bits)
     * [80 - 256[: any (176 bits)
     * @return id The cumulative id
     */
    function getCumulativeId(bytes32 sample) internal pure returns (uint64 id) {
        return sample.decodeUint64(OFFSET_CUMULATIVE_ID);
    }

    /**
     * @dev Gets the cumulative volatility accumulator from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 80[: any (80 bits)
     * [80 - 144[: cumulative volatility accumulator (64 bits)
     * [144 - 256[: any (112 bits)
     * @return volatilityAccumulator The cumulative volatility
     */
    function getCumulativeVolatility(bytes32 sample) internal pure returns (uint64 volatilityAccumulator) {
        return sample.decodeUint64(OFFSET_CUMULATIVE_VOLATILITY);
    }

    /**
     * @dev Gets the cumulative bin crossed from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 144[: any (144 bits)
     * [144 - 208[: cumulative bin crossed (64 bits)
     * [208 - 256[: any (48 bits)
     * @return binCrossed The cumulative bin crossed
     */
    function getCumulativeBinCrossed(bytes32 sample) internal pure returns (uint64 binCrossed) {
        return sample.decodeUint64(OFFSET_CUMULATIVE_BIN_CROSSED);
    }

    /**
     * @dev Gets the sample lifetime from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 208[: any (208 bits)
     * [208 - 216[: sample lifetime (8 bits)
     * [216 - 256[: any (40 bits)
     * @return lifetime The sample lifetime
     */
    function getSampleLifetime(bytes32 sample) internal pure returns (uint8 lifetime) {
        return sample.decodeUint8(OFFSET_SAMPLE_LIFETIME);
    }

    /**
     * @dev Gets the sample creation timestamp from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 216[: any (216 bits)
     * [216 - 256[: sample creation timestamp (40 bits)
     * @return creation The sample creation timestamp
     */
    function getSampleCreation(bytes32 sample) internal pure returns (uint40 creation) {
        return sample.decodeUint40(OFFSET_SAMPLE_CREATION);
    }

    /**
     * @dev Gets the sample last update timestamp from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 216[: any (216 bits)
     * [216 - 256[: sample creation timestamp (40 bits)
     * @return lastUpdate The sample last update timestamp
     */
    function getSampleLastUpdate(bytes32 sample) internal pure returns (uint40 lastUpdate) {
        lastUpdate = getSampleCreation(sample) + getSampleLifetime(sample);
    }

    /**
     * @dev Gets the weighted average of two samples and their respective weights
     * @param sample1 The first encoded sample
     * @param sample2 The second encoded sample
     * @param weight1 The weight of the first sample
     * @param weight2 The weight of the second sample
     * @return weightedAverageId The weighted average id
     * @return weightedAverageVolatility The weighted average volatility
     * @return weightedAverageBinCrossed The weighted average bin crossed
     */
    function getWeightedAverage(bytes32 sample1, bytes32 sample2, uint40 weight1, uint40 weight2)
        internal
        pure
        returns (uint64 weightedAverageId, uint64 weightedAverageVolatility, uint64 weightedAverageBinCrossed)
    {
        uint256 cId1 = getCumulativeId(sample1);
        uint256 cVolatility1 = getCumulativeVolatility(sample1);
        uint256 cBinCrossed1 = getCumulativeBinCrossed(sample1);

        if (weight2 == 0) return (uint64(cId1), uint64(cVolatility1), uint64(cBinCrossed1));

        uint256 cId2 = getCumulativeId(sample2);
        uint256 cVolatility2 = getCumulativeVolatility(sample2);
        uint256 cBinCrossed2 = getCumulativeBinCrossed(sample2);

        if (weight1 == 0) return (uint64(cId2), uint64(cVolatility2), uint64(cBinCrossed2));

        uint256 totalWeight = uint256(weight1) + weight2;

        unchecked {
            weightedAverageId = uint64((cId1 * weight1 + cId2 * weight2) / totalWeight);
            weightedAverageVolatility = uint64((cVolatility1 * weight1 + cVolatility2 * weight2) / totalWeight);
            weightedAverageBinCrossed = uint64((cBinCrossed1 * weight1 + cBinCrossed2 * weight2) / totalWeight);
        }
    }

    /**
     * @dev Updates a sample with the given values
     * @param sample The encoded sample
     * @param deltaTime The time elapsed since the last update
     * @param activeId The active id
     * @param volatilityAccumulator The volatility accumulator
     * @param binCrossed The bin crossed
     * @return cumulativeId The cumulative id
     * @return cumulativeVolatility The cumulative volatility
     * @return cumulativeBinCrossed The cumulative bin crossed
     */
    function update(bytes32 sample, uint40 deltaTime, uint24 activeId, uint24 volatilityAccumulator, uint24 binCrossed)
        internal
        pure
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed)
    {
        unchecked {
            cumulativeId = uint64(activeId) * deltaTime;
            cumulativeVolatility = uint64(volatilityAccumulator) * deltaTime;
            cumulativeBinCrossed = uint64(binCrossed) * deltaTime;
        }

        cumulativeId += getCumulativeId(sample);
        cumulativeVolatility += getCumulativeVolatility(sample);
        cumulativeBinCrossed += getCumulativeBinCrossed(sample);
    }
}
library OracleHelper {
    using SampleMath for bytes32;
    using SafeCast for uint256;
    using PairParameterHelper for bytes32;

    error OracleHelper__InvalidOracleId();
    error OracleHelper__NewLengthTooSmall();
    error OracleHelper__LookUpTimestampTooOld();

    struct Oracle {
        bytes32[65535] samples;
    }

    uint256 internal constant _MAX_SAMPLE_LIFETIME = 120 seconds;

    /**
     * @dev Modifier to check that the oracle id is valid
     * @param oracleId The oracle id
     */
    modifier checkOracleId(uint16 oracleId) {
        if (oracleId == 0) revert OracleHelper__InvalidOracleId();
        _;
    }

    /**
     * @dev Returns the sample at the given oracleId
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @return sample The sample
     */
    function getSample(Oracle storage oracle, uint16 oracleId)
        internal
        view
        checkOracleId(oracleId)
        returns (bytes32 sample)
    {
        unchecked {
            sample = oracle.samples[oracleId - 1];
        }
    }

    /**
     * @dev Returns the active sample and the active size of the oracle
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @return activeSample The active sample
     * @return activeSize The active size of the oracle
     */
    function getActiveSampleAndSize(Oracle storage oracle, uint16 oracleId)
        internal
        view
        returns (bytes32 activeSample, uint16 activeSize)
    {
        activeSample = getSample(oracle, oracleId);
        activeSize = activeSample.getOracleLength();

        if (oracleId != activeSize) {
            activeSize = getSample(oracle, activeSize).getOracleLength();
            activeSize = oracleId > activeSize ? oracleId : activeSize;
        }
    }

    /**
     * @dev Returns the sample at the given timestamp. If the timestamp is not in the oracle, it returns the closest sample
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @param lookUpTimestamp The timestamp to look up
     * @return lastUpdate The last update timestamp
     * @return cumulativeId The cumulative id
     * @return cumulativeVolatility The cumulative volatility
     * @return cumulativeBinCrossed The cumulative bin crossed
     */
    function getSampleAt(Oracle storage oracle, uint16 oracleId, uint40 lookUpTimestamp)
        internal
        view
        returns (uint40 lastUpdate, uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed)
    {
        (bytes32 activeSample, uint16 activeSize) = getActiveSampleAndSize(oracle, oracleId);

        if (oracle.samples[oracleId % activeSize].getSampleLastUpdate() > lookUpTimestamp) {
            revert OracleHelper__LookUpTimestampTooOld();
        }

        lastUpdate = activeSample.getSampleLastUpdate();
        if (lastUpdate <= lookUpTimestamp) {
            return (
                lastUpdate,
                activeSample.getCumulativeId(),
                activeSample.getCumulativeVolatility(),
                activeSample.getCumulativeBinCrossed()
            );
        } else {
            lastUpdate = lookUpTimestamp;
        }
        (bytes32 prevSample, bytes32 nextSample) = binarySearch(oracle, oracleId, lookUpTimestamp, activeSize);
        uint40 weightPrev = nextSample.getSampleLastUpdate() - lookUpTimestamp;
        uint40 weightNext = lookUpTimestamp - prevSample.getSampleLastUpdate();

        (cumulativeId, cumulativeVolatility, cumulativeBinCrossed) =
            prevSample.getWeightedAverage(nextSample, weightPrev, weightNext);
    }

    /**
     * @dev Binary search to find the 2 samples surrounding the given timestamp
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @param lookUpTimestamp The timestamp to look up
     * @param length The oracle length
     * @return prevSample The previous sample
     * @return nextSample The next sample
     */
    function binarySearch(Oracle storage oracle, uint16 oracleId, uint40 lookUpTimestamp, uint16 length)
        internal
        view
        returns (bytes32, bytes32)
    {
        uint256 low = 0;
        uint256 high = length - 1;

        bytes32 sample;
        uint40 sampleLastUpdate;

        uint256 startId = oracleId; // oracleId is 1-based
        while (low <= high) {
            uint256 mid = (low + high) >> 1;

            assembly {
                oracleId := addmod(startId, mid, length)
            }

            sample = oracle.samples[oracleId];
            sampleLastUpdate = sample.getSampleLastUpdate();

            if (sampleLastUpdate > lookUpTimestamp) {
                high = mid - 1;
            } else if (sampleLastUpdate < lookUpTimestamp) {
                low = mid + 1;
            } else {
                return (sample, sample);
            }
        }

        if (lookUpTimestamp < sampleLastUpdate) {
            unchecked {
                if (oracleId == 0) {
                    oracleId = length;
                }

                return (oracle.samples[oracleId - 1], sample);
            }
        } else {
            assembly {
                oracleId := addmod(oracleId, 1, length)
            }

            return (sample, oracle.samples[oracleId]);
        }
    }

    /**
     * @dev Sets the sample at the given oracleId
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @param sample The sample
     */
    function setSample(Oracle storage oracle, uint16 oracleId, bytes32 sample) internal checkOracleId(oracleId) {
        unchecked {
            oracle.samples[oracleId - 1] = sample;
        }
    }

    /**
     * @dev Updates the oracle
     * @param oracle The oracle
     * @param parameters The parameters
     * @param activeId The active id
     * @return The updated parameters
     */
    function update(Oracle storage oracle, bytes32 parameters, uint24 activeId) internal returns (bytes32) {
        uint16 oracleId = parameters.getOracleId();
        if (oracleId == 0) return parameters;

        bytes32 sample = getSample(oracle, oracleId);

        uint40 createdAt = sample.getSampleCreation();
        uint40 lastUpdatedAt = createdAt + sample.getSampleLifetime();

        if (block.timestamp.safe40() > lastUpdatedAt) {
            unchecked {
                (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed) = sample.update(
                    uint40(block.timestamp - lastUpdatedAt),
                    activeId,
                    parameters.getVolatilityAccumulator(),
                    parameters.getDeltaId(activeId)
                );

                uint16 length = sample.getOracleLength();
                uint256 lifetime = block.timestamp - createdAt;

                if (lifetime > _MAX_SAMPLE_LIFETIME) {
                    assembly {
                        oracleId := add(mod(oracleId, length), 1)
                    }

                    lifetime = 0;
                    createdAt = uint40(block.timestamp);

                    parameters = parameters.setOracleId(oracleId);
                }

                sample = SampleMath.encode(
                    length, cumulativeId, cumulativeVolatility, cumulativeBinCrossed, uint8(lifetime), createdAt
                );
            }

            setSample(oracle, oracleId, sample);
        }

        return parameters;
    }

    /**
     * @dev Increases the oracle length
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @param newLength The new length
     */
    function increaseLength(Oracle storage oracle, uint16 oracleId, uint16 newLength) internal {
        bytes32 sample = getSample(oracle, oracleId);
        uint16 length = sample.getOracleLength();

        if (length >= newLength) revert OracleHelper__NewLengthTooSmall();

        bytes32 lastSample = length == oracleId ? sample : length == 0 ? bytes32(0) : getSample(oracle, length);

        uint256 activeSize = lastSample.getOracleLength();
        activeSize = oracleId > activeSize ? oracleId : activeSize;

        for (uint256 i = length; i < newLength;) {
            oracle.samples[i] = bytes32(uint256(activeSize));

            unchecked {
                ++i;
            }
        }

        setSample(oracle, oracleId, (sample ^ bytes32(uint256(length))) | bytes32(uint256(newLength)));
    }
}
library SafeCast {
    error SafeCast__Exceeds248Bits();
    error SafeCast__Exceeds240Bits();
    error SafeCast__Exceeds232Bits();
    error SafeCast__Exceeds224Bits();
    error SafeCast__Exceeds216Bits();
    error SafeCast__Exceeds208Bits();
    error SafeCast__Exceeds200Bits();
    error SafeCast__Exceeds192Bits();
    error SafeCast__Exceeds184Bits();
    error SafeCast__Exceeds176Bits();
    error SafeCast__Exceeds168Bits();
    error SafeCast__Exceeds160Bits();
    error SafeCast__Exceeds152Bits();
    error SafeCast__Exceeds144Bits();
    error SafeCast__Exceeds136Bits();
    error SafeCast__Exceeds128Bits();
    error SafeCast__Exceeds120Bits();
    error SafeCast__Exceeds112Bits();
    error SafeCast__Exceeds104Bits();
    error SafeCast__Exceeds96Bits();
    error SafeCast__Exceeds88Bits();
    error SafeCast__Exceeds80Bits();
    error SafeCast__Exceeds72Bits();
    error SafeCast__Exceeds64Bits();
    error SafeCast__Exceeds56Bits();
    error SafeCast__Exceeds48Bits();
    error SafeCast__Exceeds40Bits();
    error SafeCast__Exceeds32Bits();
    error SafeCast__Exceeds24Bits();
    error SafeCast__Exceeds16Bits();
    error SafeCast__Exceeds8Bits();

    /**
     * @dev Returns x on uint248 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint248
     */
    function safe248(uint256 x) internal pure returns (uint248 y) {
        if ((y = uint248(x)) != x) revert SafeCast__Exceeds248Bits();
    }

    /**
     * @dev Returns x on uint240 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint240
     */
    function safe240(uint256 x) internal pure returns (uint240 y) {
        if ((y = uint240(x)) != x) revert SafeCast__Exceeds240Bits();
    }

    /**
     * @dev Returns x on uint232 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint232
     */
    function safe232(uint256 x) internal pure returns (uint232 y) {
        if ((y = uint232(x)) != x) revert SafeCast__Exceeds232Bits();
    }

    /**
     * @dev Returns x on uint224 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint224
     */
    function safe224(uint256 x) internal pure returns (uint224 y) {
        if ((y = uint224(x)) != x) revert SafeCast__Exceeds224Bits();
    }

    /**
     * @dev Returns x on uint216 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint216
     */
    function safe216(uint256 x) internal pure returns (uint216 y) {
        if ((y = uint216(x)) != x) revert SafeCast__Exceeds216Bits();
    }

    /**
     * @dev Returns x on uint208 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint208
     */
    function safe208(uint256 x) internal pure returns (uint208 y) {
        if ((y = uint208(x)) != x) revert SafeCast__Exceeds208Bits();
    }

    /**
     * @dev Returns x on uint200 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint200
     */
    function safe200(uint256 x) internal pure returns (uint200 y) {
        if ((y = uint200(x)) != x) revert SafeCast__Exceeds200Bits();
    }

    /**
     * @dev Returns x on uint192 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint192
     */
    function safe192(uint256 x) internal pure returns (uint192 y) {
        if ((y = uint192(x)) != x) revert SafeCast__Exceeds192Bits();
    }

    /**
     * @dev Returns x on uint184 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint184
     */
    function safe184(uint256 x) internal pure returns (uint184 y) {
        if ((y = uint184(x)) != x) revert SafeCast__Exceeds184Bits();
    }

    /**
     * @dev Returns x on uint176 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint176
     */
    function safe176(uint256 x) internal pure returns (uint176 y) {
        if ((y = uint176(x)) != x) revert SafeCast__Exceeds176Bits();
    }

    /**
     * @dev Returns x on uint168 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint168
     */
    function safe168(uint256 x) internal pure returns (uint168 y) {
        if ((y = uint168(x)) != x) revert SafeCast__Exceeds168Bits();
    }

    /**
     * @dev Returns x on uint160 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint160
     */
    function safe160(uint256 x) internal pure returns (uint160 y) {
        if ((y = uint160(x)) != x) revert SafeCast__Exceeds160Bits();
    }

    /**
     * @dev Returns x on uint152 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint152
     */
    function safe152(uint256 x) internal pure returns (uint152 y) {
        if ((y = uint152(x)) != x) revert SafeCast__Exceeds152Bits();
    }

    /**
     * @dev Returns x on uint144 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint144
     */
    function safe144(uint256 x) internal pure returns (uint144 y) {
        if ((y = uint144(x)) != x) revert SafeCast__Exceeds144Bits();
    }

    /**
     * @dev Returns x on uint136 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint136
     */
    function safe136(uint256 x) internal pure returns (uint136 y) {
        if ((y = uint136(x)) != x) revert SafeCast__Exceeds136Bits();
    }

    /**
     * @dev Returns x on uint128 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint128
     */
    function safe128(uint256 x) internal pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert SafeCast__Exceeds128Bits();
    }

    /**
     * @dev Returns x on uint120 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint120
     */
    function safe120(uint256 x) internal pure returns (uint120 y) {
        if ((y = uint120(x)) != x) revert SafeCast__Exceeds120Bits();
    }

    /**
     * @dev Returns x on uint112 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint112
     */
    function safe112(uint256 x) internal pure returns (uint112 y) {
        if ((y = uint112(x)) != x) revert SafeCast__Exceeds112Bits();
    }

    /**
     * @dev Returns x on uint104 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint104
     */
    function safe104(uint256 x) internal pure returns (uint104 y) {
        if ((y = uint104(x)) != x) revert SafeCast__Exceeds104Bits();
    }

    /**
     * @dev Returns x on uint96 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint96
     */
    function safe96(uint256 x) internal pure returns (uint96 y) {
        if ((y = uint96(x)) != x) revert SafeCast__Exceeds96Bits();
    }

    /**
     * @dev Returns x on uint88 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint88
     */
    function safe88(uint256 x) internal pure returns (uint88 y) {
        if ((y = uint88(x)) != x) revert SafeCast__Exceeds88Bits();
    }

    /**
     * @dev Returns x on uint80 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint80
     */
    function safe80(uint256 x) internal pure returns (uint80 y) {
        if ((y = uint80(x)) != x) revert SafeCast__Exceeds80Bits();
    }

    /**
     * @dev Returns x on uint72 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint72
     */
    function safe72(uint256 x) internal pure returns (uint72 y) {
        if ((y = uint72(x)) != x) revert SafeCast__Exceeds72Bits();
    }

    /**
     * @dev Returns x on uint64 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint64
     */
    function safe64(uint256 x) internal pure returns (uint64 y) {
        if ((y = uint64(x)) != x) revert SafeCast__Exceeds64Bits();
    }

    /**
     * @dev Returns x on uint56 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint56
     */
    function safe56(uint256 x) internal pure returns (uint56 y) {
        if ((y = uint56(x)) != x) revert SafeCast__Exceeds56Bits();
    }

    /**
     * @dev Returns x on uint48 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint48
     */
    function safe48(uint256 x) internal pure returns (uint48 y) {
        if ((y = uint48(x)) != x) revert SafeCast__Exceeds48Bits();
    }

    /**
     * @dev Returns x on uint40 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint40
     */
    function safe40(uint256 x) internal pure returns (uint40 y) {
        if ((y = uint40(x)) != x) revert SafeCast__Exceeds40Bits();
    }

    /**
     * @dev Returns x on uint32 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint32
     */
    function safe32(uint256 x) internal pure returns (uint32 y) {
        if ((y = uint32(x)) != x) revert SafeCast__Exceeds32Bits();
    }

    /**
     * @dev Returns x on uint24 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint24
     */
    function safe24(uint256 x) internal pure returns (uint24 y) {
        if ((y = uint24(x)) != x) revert SafeCast__Exceeds24Bits();
    }

    /**
     * @dev Returns x on uint16 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint16
     */
    function safe16(uint256 x) internal pure returns (uint16 y) {
        if ((y = uint16(x)) != x) revert SafeCast__Exceeds16Bits();
    }

    /**
     * @dev Returns x on uint8 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint8
     */
    function safe8(uint256 x) internal pure returns (uint8 y) {
        if ((y = uint8(x)) != x) revert SafeCast__Exceeds8Bits();
    }
}

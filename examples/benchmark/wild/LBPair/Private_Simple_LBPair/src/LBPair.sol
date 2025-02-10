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
    mapping(uint256 => bytes32) private _bins;
    TreeMath.TreeUint24 private _tree;
    OracleHelper.Oracle private _oracle;
    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external override onlyFactory {
        bytes32 parameters = _parameters;
        if (parameters != 0) revert LBPair__AlreadyInitialized();

        __ReentrancyGuard_init();

        _setStaticFeeParameters(
            parameters.setActiveId(activeId).updateIdReference(),
            baseFactor,
            filterPeriod,
            decayPeriod,
            reductionFactor,
            variableFeeControl,
            protocolShare,
            maxVolatilityAccumulator
        );
    }
    function getBin(uint24 id) external view override returns (uint128 binReserveX, uint128 binReserveY) {
        (binReserveX, binReserveY) = _bins[id].decode();
    }
    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        override
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee)
    {
        amountOutLeft = amountOut;

        bytes32 parameters = _parameters;
        uint16 binStep = _binStep();

        uint24 id = parameters.getActiveId();

        parameters = parameters.updateReferences();

        while (true) {
            uint128 binReserves = _bins[id].decode(!swapForY);
            if (binReserves > 0) {
                uint256 price = id.getPriceFromId(binStep);

                uint128 amountOutOfBin = binReserves > amountOutLeft ? amountOutLeft : binReserves;

                parameters = parameters.updateVolatilityAccumulator(id);

                uint128 amountInWithoutFee = uint128(
                    swapForY
                        ? uint256(amountOutOfBin).shiftDivRoundUp(Constants.SCALE_OFFSET, price)
                        : uint256(amountOutOfBin).mulShiftRoundUp(price, Constants.SCALE_OFFSET)
                );

                uint128 totalFee = parameters.getTotalFee(binStep);
                uint128 feeAmount = amountInWithoutFee.getFeeAmount(totalFee);

                amountIn += amountInWithoutFee + feeAmount;
                amountOutLeft -= amountOutOfBin;

                fee += feeAmount;
            }

            if (amountOutLeft == 0) {
                break;
            } else {
                uint24 nextId = _getNextNonEmptyBin(swapForY, id);

                if (nextId == 0 || nextId == type(uint24).max) break;

                id = nextId;
            }
        }
    }
    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        override
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee)
    {
        bytes32 amountsInLeft = amountIn.encode(swapForY);

        bytes32 parameters = _parameters;
        uint16 binStep = _binStep();

        uint24 id = parameters.getActiveId();

        parameters = parameters.updateReferences();

        while (true) {
            bytes32 binReserves = _bins[id];
            if (!binReserves.isEmpty(!swapForY)) {
                parameters = parameters.updateVolatilityAccumulator(id);

                (bytes32 amountsInWithFees, bytes32 amountsOutOfBin, bytes32 totalFees) =
                    binReserves.getAmounts(parameters, binStep, swapForY, id, amountsInLeft);

                if (amountsInWithFees > 0) {
                    amountsInLeft = amountsInLeft.sub(amountsInWithFees);

                    amountOut += amountsOutOfBin.decode(!swapForY);

                    fee += totalFees.decode(swapForY);
                }
            }

            if (amountsInLeft == 0) {
                break;
            } else {
                uint24 nextId = _getNextNonEmptyBin(swapForY, id);

                if (nextId == 0 || nextId == type(uint24).max) break;

                id = nextId;
            }
        }

        amountInLeft = amountsInLeft.decode(swapForY);
    }
    function swap(bool swapForY, address to) external override nonReentrant returns (bytes32 amountsOut) {
        bytes32 reserves = _reserves;
        bytes32 protocolFees = _protocolFees;

        bytes32 amountsLeft = swapForY ? reserves.receivedX(_tokenX()) : reserves.receivedY(_tokenY());
        if (amountsLeft == 0) revert LBPair__InsufficientAmountIn();

        reserves = reserves.add(amountsLeft);

        bytes32 parameters = _parameters;
        uint16 binStep = _binStep();

        uint24 activeId = parameters.getActiveId();

        parameters = parameters.updateReferences();

        while (true) {
            bytes32 binReserves = _bins[activeId];
            if (!binReserves.isEmpty(!swapForY)) {
                parameters = parameters.updateVolatilityAccumulator(activeId);

                (bytes32 amountsInWithFees, bytes32 amountsOutOfBin, bytes32 totalFees) =
                    binReserves.getAmounts(parameters, binStep, swapForY, activeId, amountsLeft);

                if (amountsInWithFees > 0) {
                    amountsLeft = amountsLeft.sub(amountsInWithFees);
                    amountsOut = amountsOut.add(amountsOutOfBin);

                    bytes32 pFees = totalFees.scalarMulDivBasisPointRoundDown(parameters.getProtocolShare());

                    if (pFees > 0) {
                        protocolFees = protocolFees.add(pFees);
                        amountsInWithFees = amountsInWithFees.sub(pFees);
                    }

                    _bins[activeId] = binReserves.add(amountsInWithFees).sub(amountsOutOfBin);

                    emit Swap(
                        msg.sender,
                        to,
                        activeId,
                        amountsInWithFees,
                        amountsOutOfBin,
                        parameters.getVolatilityAccumulator(),
                        totalFees,
                        pFees
                        );
                }
            }

            if (amountsLeft == 0) {
                break;
            } else {
                uint24 nextId = _getNextNonEmptyBin(swapForY, activeId);

                if (nextId == 0 || nextId == type(uint24).max) revert LBPair__OutOfLiquidity();

                activeId = nextId;
            }
        }

        if (amountsOut == 0) revert LBPair__InsufficientAmountOut();

        _reserves = reserves.sub(amountsOut);
        _protocolFees = protocolFees;

        parameters = _oracle.update(parameters, activeId);
        _parameters = parameters.setActiveId(activeId);

        if (swapForY) {
            amountsOut.transferY(_tokenY(), to);
        } else {
            amountsOut.transferX(_tokenX(), to);
        }
    }
    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data)
        external
        override
        nonReentrant
    {
        if (amounts == 0) revert LBPair__ZeroBorrowAmount();

        bytes32 reservesBefore = _reserves;
        bytes32 parameters = _parameters;

        bytes32 totalFees = _getFlashLoanFees(amounts);

        amounts.transfer(_tokenX(), _tokenY(), address(receiver));

        (bool success, bytes memory rData) = address(receiver).call(
            abi.encodeWithSelector(
                ILBFlashLoanCallback.LBFlashLoanCallback.selector,
                msg.sender,
                _tokenX(),
                _tokenY(),
                amounts,
                totalFees,
                data
            )
        );

        if (!success || rData.length != 32 || abi.decode(rData, (bytes32)) != Constants.CALLBACK_SUCCESS) {
            revert LBPair__FlashLoanCallbackFailed();
        }

        bytes32 balancesAfter = bytes32(0).received(_tokenX(), _tokenY());

        if (balancesAfter.lt(reservesBefore.add(totalFees))) revert LBPair__FlashLoanInsufficientAmount();

        totalFees = balancesAfter.sub(reservesBefore);

        uint24 activeId = parameters.getActiveId();
        bytes32 protocolFees = totalSupply(activeId) == 0
            ? totalFees
            : totalFees.scalarMulDivBasisPointRoundDown(parameters.getProtocolShare());

        _reserves = balancesAfter;

        _protocolFees = _protocolFees.add(protocolFees);
        _bins[activeId] = _bins[activeId].add(totalFees.sub(protocolFees));

        emit FlashLoan(msg.sender, receiver, activeId, amounts, totalFees, protocolFees);
    }
    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        override
        nonReentrant
        notAddressZeroOrThis(to)
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted)
    {
        if (liquidityConfigs.length == 0) revert LBPair__EmptyMarketConfigs();

        MintArrays memory arrays = MintArrays({
            ids: new uint256[](liquidityConfigs.length),
            amounts: new bytes32[](liquidityConfigs.length),
            liquidityMinted: new uint256[](liquidityConfigs.length)
        });

        bytes32 reserves = _reserves;

        amountsReceived = reserves.received(_tokenX(), _tokenY());
        amountsLeft = _mintBins(liquidityConfigs, amountsReceived, to, arrays);

        _reserves = reserves.add(amountsReceived.sub(amountsLeft));

        if (amountsLeft > 0) amountsLeft.transfer(_tokenX(), _tokenY(), refundTo);

        liquidityMinted = arrays.liquidityMinted;

        emit TransferBatch(msg.sender, address(0), to, arrays.ids, liquidityMinted);
        emit DepositedToBins(msg.sender, to, arrays.ids, arrays.amounts);
    }
    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        override
        nonReentrant
        checkApproval(from, msg.sender)
        returns (bytes32[] memory amounts)
    {
        if (ids.length == 0 || ids.length != amountsToBurn.length) revert LBPair__InvalidInput();

        amounts = new bytes32[](ids.length);

        bytes32 amountsOut;

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();
            uint256 amountToBurn = amountsToBurn[i];

            if (amountToBurn == 0) revert LBPair__ZeroAmount(id);

            bytes32 binReserves = _bins[id];
            uint256 supply = totalSupply(id);

            _burn(from, id, amountToBurn);

            bytes32 amountsOutFromBin = binReserves.getAmountOutOfBin(amountToBurn, supply);

            if (amountsOutFromBin == 0) revert LBPair__ZeroAmountsOut(id);

            binReserves = binReserves.sub(amountsOutFromBin);

            if (supply == amountToBurn) _tree.remove(id);

            _bins[id] = binReserves;
            amounts[i] = amountsOutFromBin;
            amountsOut = amountsOut.add(amountsOutFromBin);

            unchecked {
                ++i;
            }
        }

        _reserves = _reserves.sub(amountsOut);

        amountsOut.transfer(_tokenX(), _tokenY(), to);

        emit TransferBatch(msg.sender, from, address(0), ids, amountsToBurn);
        emit WithdrawnFromBins(msg.sender, to, ids, amounts);
    }
    function collectProtocolFees()
        external
        override
        nonReentrant
        onlyProtocolFeeRecipient
        returns (bytes32 collectedProtocolFees)
    {
        bytes32 protocolFees = _protocolFees;

        (uint128 x, uint128 y) = protocolFees.decode();
        bytes32 ones = uint128(x > 0 ? 1 : 0).encode(uint128(y > 0 ? 1 : 0));

        collectedProtocolFees = protocolFees.sub(ones);

        if (collectedProtocolFees != 0) {
            _protocolFees = ones;
            _reserves = _reserves.sub(collectedProtocolFees);

            collectedProtocolFees.transfer(_tokenX(), _tokenY(), msg.sender);

            emit CollectedProtocolFees(msg.sender, collectedProtocolFees);
        }
    }
    function increaseOracleLength(uint16 newLength) external override {
        bytes32 parameters = _parameters;

        uint16 oracleId = parameters.getOracleId();

        // activate the oracle if it is not active yet
        if (oracleId == 0) {
            oracleId = 1;
            _parameters = parameters.setOracleId(oracleId);
        }

        _oracle.increaseLength(oracleId, newLength);

        emit OracleLengthIncreased(msg.sender, newLength);
    }
    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external override onlyFactory {
        _setStaticFeeParameters(
            _parameters,
            baseFactor,
            filterPeriod,
            decayPeriod,
            reductionFactor,
            variableFeeControl,
            protocolShare,
            maxVolatilityAccumulator
        );
    }
    function forceDecay() external override onlyFactory {
        bytes32 parameters = _parameters;

        _parameters = parameters.updateIdReference().updateVolatilityReference();

        emit ForcedDecay(msg.sender, parameters.getIdReference(), parameters.getVolatilityReference());
    }
    function _getNextNonEmptyBin(bool swapForY, uint24 id) internal view returns (uint24) {
        return swapForY ? _tree.findFirstRight(id) : _tree.findFirstLeft(id);
    }
    function _getFlashLoanFees(bytes32 amounts) private view returns (bytes32) {
        uint128 fee = uint128(_factory.getFlashLoanFee());
        (uint128 x, uint128 y) = amounts.decode();

        unchecked {
            uint256 precisionSubOne = Constants.PRECISION - 1;
            x = ((uint256(x) * fee + precisionSubOne) / Constants.PRECISION).safe128();
            y = ((uint256(y) * fee + precisionSubOne) / Constants.PRECISION).safe128();
        }

        return x.encode(y);
    }
    function _setStaticFeeParameters(
        bytes32 parameters,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) internal {
        if (
            baseFactor == 0 && filterPeriod == 0 && decayPeriod == 0 && reductionFactor == 0 && variableFeeControl == 0
                && protocolShare == 0 && maxVolatilityAccumulator == 0
        ) {
            revert LBPair__InvalidStaticFeeParameters();
        }

        parameters = parameters.setStaticFeeParameters(
            baseFactor,
            filterPeriod,
            decayPeriod,
            reductionFactor,
            variableFeeControl,
            protocolShare,
            maxVolatilityAccumulator
        );

        {
            uint16 binStep = _binStep();
            bytes32 maxParameters = parameters.setVolatilityAccumulator(maxVolatilityAccumulator);
            uint256 totalFee = maxParameters.getBaseFee(binStep) + maxParameters.getVariableFee(binStep);
            if (totalFee > _MAX_TOTAL_FEE) {
                revert LBPair__MaxTotalFeeExceeded();
            }
        }

        _parameters = parameters;

        emit StaticFeeParametersSet(
            msg.sender,
            baseFactor,
            filterPeriod,
            decayPeriod,
            reductionFactor,
            variableFeeControl,
            protocolShare,
            maxVolatilityAccumulator
            );
    }
    function _mintBins(
        bytes32[] calldata liquidityConfigs,
        bytes32 amountsReceived,
        address to,
        MintArrays memory arrays
    ) private returns (bytes32 amountsLeft) {
        uint16 binStep = _binStep();

        bytes32 parameters = _parameters;
        uint24 activeId = parameters.getActiveId();

        amountsLeft = amountsReceived;

        for (uint256 i; i < liquidityConfigs.length;) {
            (bytes32 maxAmountsInToBin, uint24 id) = liquidityConfigs[i].getAmountsAndId(amountsReceived);
            (uint256 shares, bytes32 amountsIn, bytes32 amountsInToBin) =
                _updateBin(binStep, activeId, id, maxAmountsInToBin, parameters);

            amountsLeft = amountsLeft.sub(amountsIn);

            arrays.ids[i] = id;
            arrays.amounts[i] = amountsInToBin;
            arrays.liquidityMinted[i] = shares;

            _mint(to, id, shares);

            unchecked {
                ++i;
            }
        }
    }
    function _updateBin(uint16 binStep, uint24 activeId, uint24 id, bytes32 maxAmountsInToBin, bytes32 parameters)
        internal
        returns (uint256 shares, bytes32 amountsIn, bytes32 amountsInToBin)
    {
        bytes32 binReserves = _bins[id];

        uint256 price = id.getPriceFromId(binStep);
        uint256 supply = totalSupply(id);

        (shares, amountsIn) = binReserves.getSharesAndEffectiveAmountsIn(maxAmountsInToBin, price, supply);
        amountsInToBin = amountsIn;

        if (id == activeId) {
            parameters = parameters.updateVolatilityParameters(id);

            bytes32 fees = binReserves.getCompositionFees(parameters, binStep, amountsIn, supply, shares);

            if (fees != 0) {
                uint256 userLiquidity = amountsIn.sub(fees).getLiquidity(price);
                uint256 binLiquidity = binReserves.getLiquidity(price);

                shares = userLiquidity.mulDivRoundDown(supply, binLiquidity);
                bytes32 protocolCFees = fees.scalarMulDivBasisPointRoundDown(parameters.getProtocolShare());

                if (protocolCFees != 0) {
                    amountsInToBin = amountsInToBin.sub(protocolCFees);
                    _protocolFees = _protocolFees.add(protocolCFees);
                }

                parameters = _oracle.update(parameters, id);
                _parameters = parameters;

                emit CompositionFees(msg.sender, id, fees, protocolCFees);
            }
        } else {
            amountsIn.verifyAmounts(activeId, id);
        }

        if (shares == 0 || amountsInToBin == 0) revert LBPair__ZeroShares(id);

        if (supply == 0) _tree.add(id);

        _bins[id] = binReserves.add(amountsInToBin);
    }
}
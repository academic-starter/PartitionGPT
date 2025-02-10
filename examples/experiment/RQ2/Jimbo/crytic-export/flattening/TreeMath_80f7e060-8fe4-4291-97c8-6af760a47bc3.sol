pragma solidity 0.8.10;
library BitMath {
    /**
     * @dev Returns the index of the closest bit on the right of x that is non null
     * @param x The value as a uint256
     * @param bit The index of the bit to start searching at
     * @return id The index of the closest non null bit on the right of x.
     * If there is no closest bit, it returns max(uint256)
     */
    function closestBitRight(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            uint256 shift = 255 - bit;
            x <<= shift;

            // can't overflow as it's non-zero and we shifted it by `_shift`
            return (x == 0) ? type(uint256).max : mostSignificantBit(x) - shift;
        }
    }

    /**
     * @dev Returns the index of the closest bit on the left of x that is non null
     * @param x The value as a uint256
     * @param bit The index of the bit to start searching at
     * @return id The index of the closest non null bit on the left of x.
     * If there is no closest bit, it returns max(uint256)
     */
    function closestBitLeft(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            x >>= bit;

            return (x == 0) ? type(uint256).max : leastSignificantBit(x) + bit;
        }
    }

    /**
     * @dev Returns the index of the most significant bit of x
     * This function returns 0 if x is 0
     * @param x The value as a uint256
     * @return msb The index of the most significant bit of x
     */
    function mostSignificantBit(uint256 x) internal pure returns (uint8 msb) {
        assembly {
            if gt(x, 0xffffffffffffffffffffffffffffffff) {
                x := shr(128, x)
                msb := 128
            }
            if gt(x, 0xffffffffffffffff) {
                x := shr(64, x)
                msb := add(msb, 64)
            }
            if gt(x, 0xffffffff) {
                x := shr(32, x)
                msb := add(msb, 32)
            }
            if gt(x, 0xffff) {
                x := shr(16, x)
                msb := add(msb, 16)
            }
            if gt(x, 0xff) {
                x := shr(8, x)
                msb := add(msb, 8)
            }
            if gt(x, 0xf) {
                x := shr(4, x)
                msb := add(msb, 4)
            }
            if gt(x, 0x3) {
                x := shr(2, x)
                msb := add(msb, 2)
            }
            if gt(x, 0x1) { msb := add(msb, 1) }
        }
    }

    /**
     * @dev Returns the index of the least significant bit of x
     * This function returns 255 if x is 0
     * @param x The value as a uint256
     * @return lsb The index of the least significant bit of x
     */
    function leastSignificantBit(uint256 x) internal pure returns (uint8 lsb) {
        assembly {
            let sx := shl(128, x)
            if iszero(iszero(sx)) {
                lsb := 128
                x := sx
            }
            sx := shl(64, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 64)
            }
            sx := shl(32, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 32)
            }
            sx := shl(16, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 16)
            }
            sx := shl(8, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 8)
            }
            sx := shl(4, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 4)
            }
            sx := shl(2, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 2)
            }
            if iszero(iszero(shl(1, x))) { lsb := add(lsb, 1) }

            lsb := sub(255, lsb)
        }
    }
}
library TreeMath {
    using BitMath for uint256;

    struct TreeUint24 {
        bytes32 level0;
        mapping(bytes32 => bytes32) level1;
        mapping(bytes32 => bytes32) level2;
    }

    /**
     * @dev Returns true if the tree contains the id
     * @param tree The tree
     * @param id The id
     * @return True if the tree contains the id
     */
    function contains(TreeUint24 storage tree, uint24 id) internal view returns (bool) {
        bytes32 leaf2 = bytes32(uint256(id) >> 8);

        return tree.level2[leaf2] & bytes32(1 << (id & type(uint8).max)) != 0;
    }

    /**
     * @dev Adds the id to the tree and returns true if the id was not already in the tree
     * It will also propagate the change to the parent levels.
     * @param tree The tree
     * @param id The id
     * @return True if the id was not already in the tree
     */
    function add(TreeUint24 storage tree, uint24 id) internal returns (bool) {
        bytes32 key2 = bytes32(uint256(id) >> 8);

        bytes32 leaves = tree.level2[key2];
        bytes32 newLeaves = leaves | bytes32(1 << (id & type(uint8).max));

        if (leaves != newLeaves) {
            tree.level2[key2] = newLeaves;

            if (leaves == 0) {
                bytes32 key1 = key2 >> 8;
                leaves = tree.level1[key1];

                tree.level1[key1] = leaves | bytes32(1 << (uint256(key2) & type(uint8).max));

                if (leaves == 0) tree.level0 |= bytes32(1 << (uint256(key1) & type(uint8).max));
            }

            return true;
        }

        return false;
    }

    /**
     * @dev Removes the id from the tree and returns true if the id was in the tree.
     * It will also propagate the change to the parent levels.
     * @param tree The tree
     * @param id The id
     * @return True if the id was in the tree
     */
    function remove(TreeUint24 storage tree, uint24 id) internal returns (bool) {
        bytes32 key2 = bytes32(uint256(id) >> 8);

        bytes32 leaves = tree.level2[key2];
        bytes32 newLeaves = leaves & ~bytes32(1 << (id & type(uint8).max));

        if (leaves != newLeaves) {
            tree.level2[key2] = newLeaves;

            if (newLeaves == 0) {
                bytes32 key1 = key2 >> 8;
                leaves = tree.level1[key1];

                tree.level1[key1] = leaves & ~bytes32(1 << (uint256(key2) & type(uint8).max));

                if (leaves == 0) tree.level0 &= ~bytes32(1 << (uint256(key1) & type(uint8).max));
            }

            return true;
        }

        return false;
    }

    /**
     * @dev Returns the first id in the tree that is lower than or equal to the given id.
     * It will return type(uint24).max if there is no such id.
     * @param tree The tree
     * @param id The id
     * @return The first id in the tree that is lower than or equal to the given id
     */
    function findFirstRight(TreeUint24 storage tree, uint24 id) internal view returns (uint24) {
        bytes32 leaves;

        bytes32 key2 = bytes32(uint256(id) >> 8);
        uint8 bit = uint8(id & type(uint8).max);

        if (bit != 0) {
            leaves = tree.level2[key2];
            uint256 closestBit = _closestBitRight(leaves, bit);

            if (closestBit != type(uint256).max) return uint24(uint256(key2) << 8 | closestBit);
        }

        bytes32 key1 = key2 >> 8;
        bit = uint8(uint256(key2) & type(uint8).max);

        if (bit != 0) {
            leaves = tree.level1[key1];
            uint256 closestBit = _closestBitRight(leaves, bit);

            if (closestBit != type(uint256).max) {
                key2 = bytes32(uint256(key1) << 8 | closestBit);
                leaves = tree.level2[key2];

                return uint24(uint256(key2) << 8 | uint256(leaves).mostSignificantBit());
            }
        }

        bit = uint8(uint256(key1) & type(uint8).max);

        if (bit != 0) {
            leaves = tree.level0;
            uint256 closestBit = _closestBitRight(leaves, bit);

            if (closestBit != type(uint256).max) {
                key1 = bytes32(closestBit);
                leaves = tree.level1[key1];

                key2 = bytes32(uint256(key1) << 8 | uint256(leaves).mostSignificantBit());
                leaves = tree.level2[key2];

                return uint24(uint256(key2) << 8 | uint256(leaves).mostSignificantBit());
            }
        }

        return type(uint24).max;
    }

    /**
     * @dev Returns the first id in the tree that is higher than or equal to the given id.
     * It will return 0 if there is no such id.
     * @param tree The tree
     * @param id The id
     * @return The first id in the tree that is higher than or equal to the given id
     */
    function findFirstLeft(TreeUint24 storage tree, uint24 id) internal view returns (uint24) {
        bytes32 leaves;

        bytes32 key2 = bytes32(uint256(id) >> 8);
        uint8 bit = uint8(id & type(uint8).max);

        if (bit != type(uint8).max) {
            leaves = tree.level2[key2];
            uint256 closestBit = _closestBitLeft(leaves, bit);

            if (closestBit != type(uint256).max) return uint24(uint256(key2) << 8 | closestBit);
        }

        bytes32 key1 = key2 >> 8;
        bit = uint8(uint256(key2) & type(uint8).max);

        if (bit != type(uint8).max) {
            leaves = tree.level1[key1];
            uint256 closestBit = _closestBitLeft(leaves, bit);

            if (closestBit != type(uint256).max) {
                key2 = bytes32(uint256(key1) << 8 | closestBit);
                leaves = tree.level2[key2];

                return uint24(uint256(key2) << 8 | uint256(leaves).leastSignificantBit());
            }
        }

        bit = uint8(uint256(key1) & type(uint8).max);

        if (bit != type(uint8).max) {
            leaves = tree.level0;
            uint256 closestBit = _closestBitLeft(leaves, bit);

            if (closestBit != type(uint256).max) {
                key1 = bytes32(closestBit);
                leaves = tree.level1[key1];

                key2 = bytes32(uint256(key1) << 8 | uint256(leaves).leastSignificantBit());
                leaves = tree.level2[key2];

                return uint24(uint256(key2) << 8 | uint256(leaves).leastSignificantBit());
            }
        }

        return 0;
    }

    /**
     * @dev Returns the first bit in the given leaves that is strictly lower than the given bit.
     * It will return type(uint256).max if there is no such bit.
     * @param leaves The leaves
     * @param bit The bit
     * @return The first bit in the given leaves that is strictly lower than the given bit
     */
    function _closestBitRight(bytes32 leaves, uint8 bit) private pure returns (uint256) {
        unchecked {
            return uint256(leaves).closestBitRight(bit - 1);
        }
    }

    /**
     * @dev Returns the first bit in the given leaves that is strictly higher than the given bit.
     * It will return type(uint256).max if there is no such bit.
     * @param leaves The leaves
     * @param bit The bit
     * @return The first bit in the given leaves that is strictly higher than the given bit
     */
    function _closestBitLeft(bytes32 leaves, uint8 bit) private pure returns (uint256) {
        unchecked {
            return uint256(leaves).closestBitLeft(bit + 1);
        }
    }
}

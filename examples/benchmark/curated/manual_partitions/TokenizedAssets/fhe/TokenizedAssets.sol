// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.20;

import "fhevm/lib/TFHE.sol";

contract TokenizedAssets {
    struct Asset {
        euint32 encryptedData;
        address owner;
    }

    mapping(uint256 => Asset) public assets;
    uint256 public assetCounter;

    event AssetTokenized(uint256 assetId, bytes encryptedData, address owner);
    event AssetTransferred(uint256 assetId, address from, address to);

    function tokenizeAsset(bytes calldata encryptedData) public {
        require(encryptedData.length == 8412, "Invalid ciphertext size"); // Check ciphertext size
        euint32 data = TFHE.asEuint32(encryptedData);
        assetCounter++;
        assets[assetCounter] = Asset(data, msg.sender);
        emit AssetTokenized(assetCounter, encryptedData, msg.sender);
    }

    function transferAsset(uint256 assetId, address newOwner) public {
        require(assets[assetId].owner == msg.sender, "Only the owner can transfer the asset.");
        address previousOwner = assets[assetId].owner;
        assets[assetId].owner = newOwner;
        emit AssetTransferred(assetId, previousOwner, newOwner);
    }

    function getAsset(uint256 assetId, bytes32 publicKey) public view returns (bytes memory) {
        require(assets[assetId].owner == msg.sender, "Only the owner can view the asset.");
        return TFHE.reencrypt(assets[assetId].encryptedData, publicKey);
    }
}

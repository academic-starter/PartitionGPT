// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.20;


contract TokenizedAssets {
    struct Asset {
        uint32 encryptedData;
        address owner;
    }

    mapping(uint256 => Asset) public assets;
    uint256 public assetCounter;

    event AssetTokenized(uint256 assetId, uint32 encryptedData, address owner);
    event AssetTransferred(uint256 assetId, address from, address to);

    function tokenizeAsset(uint32 encryptedData) public {
        assetCounter++;
        assets[assetCounter] = Asset(encryptedData, msg.sender);
        emit AssetTokenized(assetCounter, encryptedData, msg.sender);
    }

    function transferAsset(uint256 assetId, address newOwner) public {
        require(assets[assetId].owner == msg.sender, "Only the owner can transfer the asset.");
        address previousOwner = assets[assetId].owner;
        assets[assetId].owner = newOwner;
        emit AssetTransferred(assetId, previousOwner, newOwner);
    }

    function getAsset(uint256 assetId) public view returns (uint32) {
        require(assets[assetId].owner == msg.sender, "Only the owner can view the asset.");
        return assets[assetId].encryptedData;
    }
}
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
        tokenizeAsset_priv(msg.sender, encryptedData);
    }

    function tokenizeAsset_priv(address sender, uint32 encryptedData) internal {
        assets[assetCounter] = Asset(encryptedData, sender);
        emit AssetTokenized(assetCounter, encryptedData, sender);
    }
    

    function transferAsset(uint256 assetId, address newOwner) public {
        transferAsset_priv(msg.sender, assetId, newOwner);
    }
    function transferAsset_priv(address sender, uint256 assetId, address newOwner) internal {
        require(assets[assetId].owner == sender, "Only the owner can transfer the asset.");
        address previousOwner = assets[assetId].owner;
        assets[assetId].owner = newOwner;
        emit AssetTransferred(assetId, previousOwner, newOwner);
    }

    function getAsset(uint256 assetId) public view returns (uint32) {
        uint32 voteData = getAsset_priv(msg.sender, assetId);
        return getAsset_callback(voteData);
    }
    function getAsset_priv(address sender, uint256 assetId) internal view returns (uint32) {
        require(assets[assetId].owner == sender, "Only the owner can view the asset.");
        return assets[assetId].encryptedData;
    }
    function getAsset_callback(uint32 voteData) internal pure returns (uint32) {
        return voteData;
    }
}
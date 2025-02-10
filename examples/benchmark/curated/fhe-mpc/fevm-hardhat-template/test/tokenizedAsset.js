const { expect } = require("chai");
const { ethers } = require("hardhat");
const crypto = require("crypto");

describe("TokenizedAssets", function () {
  let TokenizedAssets, tokenizedAssets, owner, newOwner;

  beforeEach(async () => {
    [owner, newOwner] = await ethers.getSigners();
    TokenizedAssets = await ethers.getContractFactory("TokenizedAssets");
    tokenizedAssets = await TokenizedAssets.connect(owner).deploy();
    await tokenizedAssets.waitForDeployment();

    console.log("Contract deployed to:", tokenizedAssets.address);
  });

  it("Should tokenize and transfer an asset", async function () {
    // const plaintextData = 12345;

    // Generate a dummy 8412-byte ciphertext for testing
    const encryptedData = crypto.randomBytes(8412);
    console.log("Generated encrypted data:", encryptedData);

    // Tokenize asset
    await tokenizedAssets.connect(owner).tokenizeAsset(encryptedData);
    const asset = await tokenizedAssets.assets(1);
    console.log("Tokenized asset:", asset);

    expect(asset.owner).to.equal(owner.address);

    // Transfer asset
    await tokenizedAssets.connect(owner).transferAsset(1, newOwner.address);
    const transferredAsset = await tokenizedAssets.assets(1);
    console.log("Transferred asset:", transferredAsset);

    expect(transferredAsset.owner).to.equal(newOwner.address);
  });
});

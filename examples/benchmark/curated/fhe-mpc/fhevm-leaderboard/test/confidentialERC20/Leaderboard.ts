import { expect } from "chai";
import { ethers } from "hardhat";

import { createInstances } from "../instance";
import { getSigners, initSigners } from "../signers";
import { deployEncryptedERC20Fixture } from "./Leaderboard.fixture";

describe("Leaderboard", function () {
  before(async function () {
    await initSigners();
    this.signers = await getSigners();
  });

  beforeEach(async function () {
    const contract = await deployEncryptedERC20Fixture();
    this.contractAddress = await contract.getAddress();
    this.leaderboard = contract;
    this.instances = await createInstances(this.contractAddress, ethers, this.signers);
  });

  it("should add a new player", async function () {
    const score = this.instances.alice.encrypt32(1337);
    const transaction = await this.leaderboard.addPlayer(this.signers.alice.address, score);
    await transaction.wait();
    const player = await this.leaderboard.players(this.signers.alice.address);

    //const decryptedScore = this.instances.alice.decrypt(this.contractAddress, player.score);
    //console.log(decryptedScore);
    // Decrypt the total supply
    //expect(decryptedScore).to.equal(1337);
  });

  it("should add multiple players", async function () {
    let score = this.instances.alice.encrypt32(10);
    var transaction = await this.leaderboard.addPlayer(this.signers.alice.address, score);
    await transaction.wait();

    score = this.instances.bob.encrypt32(100);
    transaction = await this.leaderboard.addPlayer(this.signers.bob.address, score);
    await transaction.wait();

    score = this.instances.carol.encrypt32(70);
    transaction = await this.leaderboard.addPlayer(this.signers.carol.address, score);
    await transaction.wait();

    score = this.instances.dave.encrypt32(4);
    transaction = await this.leaderboard.addPlayer(this.signers.dave.address, score);
    await transaction.wait();

    score = this.instances.eve.encrypt32(7);
    transaction = await this.leaderboard.addPlayer(this.signers.eve.address, score);
    await transaction.wait();

    let relativeScore = await this.leaderboard.getScoreRelativeToHighestScore();
    console.log(relativeScore);
    
  });



});
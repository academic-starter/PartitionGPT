import { ethers } from "hardhat";

import type { ConfidentialERC20, Leaderboard } from "../../types";
import { getSigners } from "../signers";

export async function deployEncryptedERC20Fixture(): Promise<Leaderboard> {
  const signers = await getSigners();

  const contractFactory = await ethers.getContractFactory("Leaderboard");
  const contract = await contractFactory.connect(signers.alice).deploy();
  await contract.waitForDeployment();

  return contract;
}

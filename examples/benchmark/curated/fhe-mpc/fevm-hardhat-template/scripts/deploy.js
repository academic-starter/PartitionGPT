async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const TokenizedAssetsContractFactory = await ethers.getContractFactory("TokenizedAssets");
  const myContract = (await TokenizedAssetsContractFactory.connect(deployer).deploy());

  await myContract.waitForDeployment();

  // const tokenizedAssets = await TokenizedAssetsContractFactory.deploy();

  console.log("Awaiting deployment...");
  // await tokenizedAssets.waitForDeployment();

  const myContractDeployedAddress = await myContract.getAddress();

  console.log("TokenizedAssets deployed to:", myContractDeployedAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

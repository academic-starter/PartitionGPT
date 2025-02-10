import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const ConfidentialERC20Deployed = await deploy("ConfidentialERC20", {
    from: deployer,
    args: ["Naraggara", "NARA"],
    log: true,
  });

  const LeaderboardDeployed = await deploy("Leaderboard", {
    from: deployer,
    log: true,
  });

  console.log(`ConfidentialERC20 contract: `, ConfidentialERC20Deployed.address);
  console.log(`LeaderboardDeployed contract: `, LeaderboardDeployed.address);
};
export default func;
func.id = "deploy_confidentialERC20"; // id required to prevent reexecution
func.tags = ["ConfidentialERC20"];

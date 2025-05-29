const { ethers, upgrades } = require("hardhat");

async function main() {
  // Configuration
  const wallet1 = "0x39c8e3807B864A633bd83C34995d7A3a18d0b7e8"; // Gnosis Safe
  const initialFee = 50; // 0.5% fee for DAAR transfers (in basis points)
  const epochDuration = 7 * 24 * 60 * 60; // 1 week in seconds for DAARDistributor

  // Deploy DAAR proxy
  console.log("Deploying DAAR...");
  const DAAR = await ethers.getContractFactory("DAAR");
  const daar = await upgrades.deployProxy(DAAR, [], { initializer: false });
  await daar.waitForDeployment();
  const daarAddress = await daar.getAddress();
  console.log("DAAR deployed at:", daarAddress);

  // Deploy DAARION proxy
  console.log("Deploying DAARION...");
  const DAARION = await ethers.getContractFactory("DAARION");
  const daarion = await upgrades.deployProxy(DAARION, [], { initializer: false });
  await daarion.waitForDeployment();
  const daarionAddress = await daarion.getAddress();
  console.log("DAARION deployed at:", daarionAddress);

  // Deploy DAARDistributor proxy
  console.log("Deploying DAARDistributor...");
  const DAARDistributor = await ethers.getContractFactory("DAARDistributor");
  const distributor = await upgrades.deployProxy(DAARDistributor, [], { initializer: false });
  await distributor.waitForDeployment();
  const distributorAddress = await distributor.getAddress();
  console.log("DAARDistributor deployed at:", distributorAddress);

  // Deploy APRStaking proxy (walletR)
  console.log("Deploying APRStaking (walletR)...");
  const APRStaking = await ethers.getContractFactory("APRStaking");
  const staking = await upgrades.deployProxy(APRStaking, [], { initializer: false });
  await staking.waitForDeployment();
  const stakingAddress = await staking.getAddress();
  console.log("APRStaking (walletR) deployed at:", stakingAddress);

  // Initialize all contracts with the correct addresses
  try {
    console.log("Initializing DAAR...");
    await daar.initialize(distributorAddress, initialFee, wallet1, stakingAddress);
    console.log("DAAR initialized");
  } catch (error) {
    console.error("Error initializing DAAR:", error);
    throw error;
  }

  try {
    console.log("Initializing DAARION...");
    await daarion.initialize(wallet1, distributorAddress, stakingAddress);
    console.log("DAARION initialized");
  } catch (error) {
    console.error("Error initializing DAARION:", error);
    throw error;
  }

  try {
    console.log("Initializing DAARDistributor...");
    await distributor.initialize(daarAddress, daarionAddress, wallet1, epochDuration);
    console.log("DAARDistributor initialized");
  } catch (error) {
    console.error("Error initializing DAARDistributor:", error);
    throw error;
  }

  try {
    console.log("Initializing APRStaking...");
    await staking.initialize(daarAddress, daarionAddress, wallet1);
    console.log("APRStaking initialized");
  } catch (error) {
    console.error("Error initializing APRStaking:", error);
    throw error;
  }

  console.log("All contracts deployed and initialized successfully");
  console.log("Summary:");
  console.log("- DAAR:", daarAddress);
  console.log("- DAARION:", daarionAddress);
  console.log("- DAARDistributor (walletD):", distributorAddress);
  console.log("- APRStaking (walletR):", stakingAddress);
}

main().catch((error) => {
  console.error("Deployment failed:", error);
  process.exitCode = 1;
});
// Import necessary functions and artifacts
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades'); // OpenZeppelin upgrades plugin functions
const DAARDistributor = artifacts.require("DAARDistributor"); // DAARDistributor contract artifact
const APRStaking = artifacts.require("APRStaking"); // APRStaking contract artifact
const DAAR = artifacts.require("DAAR");  // DAAR token contract artifact
const DAARION = artifacts.require("DAARION");  // DAARION token contract artifact
const Web3 = require('web3'); // Web3 library for blockchain interactions

module.exports = async function (deployer, network, accounts) {
  try {
    // Define the owner address (Gnosis Safe Wallet)
    const ownerAddress = '0x39c8e3807B864A633bd83C34995d7A3a18d0b7e8';

    // Existing DAAR and DAARION contract addresses
    const daarAddress = '0x0C2F6a057D9086BA96F612fEfEaC5353d5D48E13'; // DAAR contract address
    const daarionAddress = '0xDC818BC212BEC15726626eA0b15a147795399E32'; // DAARION contract address

    // Initialize Web3 with the provider from deployer
    const web3 = new Web3(deployer.provider);

    // Retrieve unlocked accounts from the provider
    const unlockedAccounts = await web3.eth.getAccounts();
    const deployerAccount = unlockedAccounts[0]; // The account used for deployment

    // Ensure ownerAddress is among unlocked accounts or accessible for signing transactions
    if (!unlockedAccounts.map(a => a.toLowerCase()).includes(ownerAddress.toLowerCase())) {
      console.warn(`Warning: ownerAddress ${ownerAddress} is not among the unlocked accounts. Transactions requiring signatures from ownerAddress may fail.`);
    }

    // Declare variables to hold contract instances
    let daarDistributor; // DAARDistributor contract instance
    let aprStaking; // APRStaking contract instance
    let daarContract; // DAAR contract instance
    let daarionContract; // DAARION contract instance

    // Attempt to retrieve existing DAARDistributor proxy contract to maintain the same address
    try {
      // Get the address of the existing proxy from the OpenZeppelin upgrades manifest
      const ProxyAdmin = artifacts.require('@openzeppelin/contracts-upgradeable/proxy/ProxyAdmin.sol');
      const proxyAdmin = await ProxyAdmin.deployed();
      const daarDistributorAddress = await proxyAdmin.getProxyAddress(DAARDistributor.contractName);

      if (daarDistributorAddress) {
        // If proxy exists, get the deployed instance
        daarDistributor = await DAARDistributor.at(daarDistributorAddress);
        console.log(`DAARDistributor already deployed at: ${daarDistributor.address}`);
      } else {
        // If proxy doesn't exist, deploy a new one
        throw new Error('DAARDistributor proxy not found');
      }
    } catch (error) {
      // Deploy a new proxy contract with initialization parameters
      daarDistributor = await deployProxy(DAARDistributor, [daarAddress, daarionAddress, 2592000], { deployer, initializer: 'initialize' });
      console.log(`DAARDistributor deployed at: ${daarDistributor.address}`);
    }

    // Attempt to retrieve existing APRStaking proxy contract to maintain the same address
    try {
      const ProxyAdmin = artifacts.require('@openzeppelin/contracts-upgradeable/proxy/ProxyAdmin.sol');
      const proxyAdmin = await ProxyAdmin.deployed();
      const aprStakingAddress = await proxyAdmin.getProxyAddress(APRStaking.contractName);

      if (aprStakingAddress) {
        aprStaking = await APRStaking.at(aprStakingAddress);
        console.log(`APRStaking already deployed at: ${aprStaking.address}`);
      } else {
        throw new Error('APRStaking proxy not found');
      }
    } catch (error) {
      aprStaking = await deployProxy(APRStaking, [daarAddress, daarionAddress, ownerAddress, 500, 400], { deployer, initializer: 'initialize' });
      console.log(`APRStaking deployed at: ${aprStaking.address}`);
    }

    // Get instances of existing DAAR and DAARION contracts
    daarContract = await DAAR.at(daarAddress);
    daarionContract = await DAARION.at(daarionAddress);

    // Set wallets in DAAR contract
    try {
      // The from address must be the current owner of the DAAR contract
      await daarContract.setWallets(ownerAddress, daarDistributor.address, aprStaking.address, { from: deployerAccount });
      console.log("DAAR wallets set successfully.");
    } catch (error) {
      console.error("Error setting wallets in DAAR:", error);
      throw error;
    }

    // Set wallets in DAARION contract
    try {
      await daarionContract.setWallets(ownerAddress, daarDistributor.address, aprStaking.address, { from: deployerAccount });
      console.log("DAARION wallets set successfully.");
    } catch (error) {
      console.error("Error setting wallets in DAARION:", error);
      throw error;
    }

    // Set WalletD role to DAARDistributor contract in DAAR contract
    try {
      await daarContract.setWalletD(daarDistributor.address, { from: deployerAccount });
      console.log("DAARDistributor set as WalletD in DAAR.");
    } catch (error) {
      console.error("Error setting WalletD in DAAR:", error);
      throw error;
    }

    // Transfer ownership to Gnosis Safe Wallet
    try {
      // Transfer ownership of DAAR contract
      await daarContract.transferOwnership(ownerAddress, { from: deployerAccount });
      console.log("DAAR ownership transferred.");
    } catch (error) {
      console.error("Error transferring ownership of DAAR:", error);
      throw error;
    }

    try {
      // Transfer ownership of DAARION contract
      await daarionContract.transferOwnership(ownerAddress, { from: deployerAccount });
      console.log("DAARION ownership transferred.");
    } catch (error) {
      console.error("Error transferring ownership of DAARION:", error);
      throw error;
    }

    try {
      // Transfer ownership of DAARDistributor contract
      await daarDistributor.transferOwnership(ownerAddress, { from: deployerAccount });
      console.log("DAARDistributor ownership transferred.");
    } catch (error) {
      console.error("Error transferring ownership of DAARDistributor:", error);
      throw error;
    }

    try {
      // Transfer ownership of APRStaking contract
      await aprStaking.transferOwnership(ownerAddress, { from: deployerAccount });
      console.log("APRStaking ownership transferred.");
    } catch (error) {
      console.error("Error transferring ownership of APRStaking:", error);
      throw error;
    }

    console.log(`Contracts deployed and configured successfully.`);
  } catch (error) {
    console.error('Error during migration:', error);
  }
};

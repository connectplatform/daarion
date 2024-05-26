const DAAR = artifacts.require("DAAR");
const DAARION = artifacts.require("DAARION");

module.exports = async function(deployer, network, accounts) {
    const [wallet1, walletD, daarToken, initialOwner] = accounts;

    // Deploy DAAR contract
    await deployer.deploy(DAAR, walletD, initialOwner);

    // Deploy DAARION contract
    await deployer.deploy(DAARION, wallet1, walletD, daarToken, initialOwner);
};

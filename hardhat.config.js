require('@nomicfoundation/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
require('@nomiclabs/hardhat-etherscan');
require('dotenv').config({ path: '.env.local' });

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const INFURA_KEY = process.env.INFURA_KEY;
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY;

module.exports = {
  solidity: {
    version: "0.8.26",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: "./contracts",
    artifacts: "./artifacts",
    cache: "./cache",
    imports: "./node_modules" // Explicitly point to node_modules
  },
  networks: {
    amoy: {
      url: "https://rpc-amoy.polygon.technology/",
      accounts: [PRIVATE_KEY],
      chainId: 80002,
      gas: 5500000,
      gasPrice: 30000000000,
      confirmations: 2,
      timeout: 10000,
    },
    polygon: {
      url: `https://polygon-mainnet.infura.io/v3/${INFURA_KEY}`,
      accounts: [PRIVATE_KEY],
      chainId: 137,
      gas: 5500000,
      gasPrice: 30100000000,
      confirmations: 2,
      timeout: 1000000,
    },
    development: {
      url: "http://127.0.0.1:8545",
      chainId: 1337,
      accounts: [PRIVATE_KEY],
    },
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true,
    only: ['DAAR', 'DAARION'],
  },
  etherscan: {
    apiKey: {
      polygon: POLYGONSCAN_API_KEY,
      polygonAmoy: POLYGONSCAN_API_KEY,
    },
    customChains: [
      {
        network: "polygonAmoy",
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com",
        },
      },
    ],
  },
};
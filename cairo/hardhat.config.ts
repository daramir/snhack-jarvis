import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@shardlabs/starknet-hardhat-plugin";
import "@typechain/hardhat";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import { task } from "hardhat/config";

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config = {
  mocha: {
    timeout: 1000000
  },
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 300,
      },
    },
  },
  networks: {
    // L2
    devnet: {
      url: "http://localhost:5000",
    },
    testnet: {
      url: "https://alpha4.starknet.io",
      // timeout: 180000,
    },
    hackathon4: {
      url: "http://hackathon-4.starknet.io/",
      // timeout: 180000,
    },
    // L1
    ganache: {
      url: "http://0.0.0.0:8545",
    },
    goerli: {
      url: "https://eth-goerli.alchemyapi.io/v2/8ZcvipWs2SZPZIVVGxMYM0_DjtvVfbdF",
      accounts: [
        "0xf87608affeedff9d74df1985f17821a8cdc1711722392645c8a00176efd9d263", // ams-sn-h-1
      ]
    },
  },
  starknet: {
    // The default in this version of the plugin
    dockerizedVersion: "0.8.1-arm", // append "-arm" if running on ARM architecture (e.g. M1)
    wallets: {
      MyWallet: {
        accountName: "OpenZeppelin",
        modulePath: "starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount",
        accountPath: "~/.starknet_accounts"
      },
    }
  },
  namedAccounts: {
    deployer: 0,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false,
    gasPrice: 100,
    currency: "USD",
  },
  typechain: {
    outDir: "src/types",
    target: "ethers-v5",
  },
};

export default config;

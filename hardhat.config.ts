import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.17",


  networks: {
    hardhat: {
    },
    goerli: {
      url: process.env.GOERLI_RPC,
      //@ts-ignore
      accounts: [process.env.PRIVATE_KEY, process.env.PRIVATE_KEY2],
    },

    sepolia: {
      url: process.env.SEPOLIA_RPC,
      //@ts-ignore
      accounts: [process.env.PRIVATE_KEY, process.env.PRIVATE_KEY2],
    }
  },
  etherscan:{
    apiKey: process.env.API_KEY,
  },
};

export default config;

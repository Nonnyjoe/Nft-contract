import { ethers, hardhatArguments, network } from "hardhat";
const hre = require("hardhat");
import { Contract } from "hardhat/internal/hardhat-network/stack-traces/model";

async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => resolve(), ms);
    });
}

async function main() {
    const [owner, owner2] = await ethers.getSigners();
    const address = "0xeDceC4Bce45bB9eEEc775e4d1D65E63751C79003";
  //deploy Random Number Generating Script
  const randomNumber = await ethers.getContractFactory("Lottery");
  const amount = ethers.utils.parseEther('10')
  const RandomNumber = await randomNumber.deploy(amount, 15, address );
  await RandomNumber.deployed();

  console.log('CONTRACT DEPLOYED')

  console.log(`contract address is ${RandomNumber.address}`);

  await sleep(45 * 1000);
  await hre.run("verify:verify", {
    address: RandomNumber.address,
    constructorArguments: [],
  });

console.log('CONTRACT VERIFIED')

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
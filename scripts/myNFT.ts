import { ethers } from "hardhat";

async function main() {
    console.log("script started.........");
    const [owner, owner2] = await ethers.getSigners();

    console.log("Gotten signers........")
    const mynft = await ethers.getContractFactory("EthersFuture");
    console.log("Contract bytecode obtained........")
    const Mynft = await mynft.deploy("Ethers Future", "ETF");
    console.log(`Mynft is ${Mynft}`);
    await Mynft.deployed()
    console.log("contract deployed.........");
    const contractAddress = Mynft.address;
    console.log(`My contractAddress is ${contractAddress}`);
//////////////////////////////////////////////////
    const mint = await Mynft.safeMint(owner.address, "Qmb73Tx9QSkvj638nJ5FzCpss6BH2acEdiWbRHPGU8TMX1");
    console.log(`minted ${mint}`);
    let minting = await (await mint.wait()).events[0].args[2];
    console.log(minting);
    
    //const uri = await Mynft.tokenURI()

}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
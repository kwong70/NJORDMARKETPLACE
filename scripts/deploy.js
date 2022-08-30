const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("0");
  const [deployer] = await ethers.getSigners();
  console.log("1");
  const balance = await deployer.getBalance();
  console.log("2");
  const Marketplace = await hre.ethers.getContractFactory("NFTMarketplace");
  console.log("3");
  const marketplace = await Marketplace.deploy();
  console.log("4");
  await marketplace.deployed();
  console.log("5");
  const data = {
    address: marketplace.address,
    abi: JSON.parse(marketplace.interface.format('json'))
  }

  //This writes the ABI and address to the mktplace.json
  fs.writeFileSync('./src/Marketplace.json', JSON.stringify(data))
  console.log("6");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

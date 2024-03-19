import { ethers } from "hardhat";
import airdropList from '../airdrops';

let holders: any[] = [];
let counts: any[] = [];

airdropList.map((account : any[]) => {
  holders.push(account[0]);
  counts.push(account[1]);
})

async function main() {
 
  const Lock = await ethers.getContractFactory("NoBuddies");
  const lock = await Lock.deploy();

  await lock.deployed();

  console.log(`NoBuddies deployed to ${lock.address}`);

  console.log('Airdrop Diamond NFTs...');
  await lock.airdropNFTs(holders, counts);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

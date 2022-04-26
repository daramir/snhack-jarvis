// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");


async function main() {

  // await network.provider.send("evm_setIntervalMining", [5000]);
  let oneDay = 86400;

  await ethers.provider.send('evm_increaseTime', [oneDay * 100]); // Increase time by one day 
  await ethers.provider.send('evm_mine') // Force mine to update block timestamp

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

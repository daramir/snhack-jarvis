// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, network } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const MagicMoneyPortal = await ethers.getContractFactory("MagicMoneyPortal");
  const magicmoneyportal = await MagicMoneyPortal.deploy("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
  console.log("Magic Money Portal deployed to:", magicmoneyportal.address);

  // We send USDC and ETH to deployer for testing
  const USDC = await ethers.getContractFactory("USDC");
  const usdc = await USDC.attach("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");

  let signers = await ethers.getSigners()
  await signers[0].sendTransaction({
    to: "0x54CF8930796e1e0c7366c6F04D1Ea6Ad6FA5B708",
    value: ethers.utils.parseEther("4")
  })
  console.log("Ether sent to Deployer");
  await usdc.connect(await impersonate("0x55FE002aefF02F77364de339a1292923A15844B8"))
  .transfer("0x54CF8930796e1e0c7366c6F04D1Ea6Ad6FA5B708", ethers.utils.parseUnits("10000000", 6));
  console.log("USDC sent to Deployer");
}

async function impersonate(address: any) {
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [address],
  });
  const newSigner = await ethers.getSigner(address)
  return newSigner
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

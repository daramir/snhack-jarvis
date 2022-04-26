import { starknet } from "hardhat";
import { expect } from "chai";
import { StarknetContract } from "hardhat/types";
import { uint256, shortString } from "starknet";

const main = async () => {
  let contract: StarknetContract;
  
  const counterFactory = await starknet.getContractFactory("YB_ERC20");

  const SELF_ADDRESS = "0x5d6d57a7ac4ef4c27d0b78eeef9bd00f7c92bbb75ac22a6e908f69f150e03e6";

  const account = await starknet.getAccountFromAddress(
    SELF_ADDRESS,
    // process.env.PRIVATE_KEY,
    // DO NOT PUSH BELOW LINE,
    "0x408e61f59d7c476cd467282f214b39c12913ffb094f502ab5ee95fc3920af1b",
    "OpenZeppelin");

  let tokenName = shortString.encodeShortString("YieldBridgeUSDC");
  let tokenSymbol = shortString.encodeShortString("YBUSDC");
  contract = await counterFactory.deploy({ name : tokenName, 
  symbol : tokenSymbol, 
  decimals : 18, minter_address : BigInt(SELF_ADDRESS)});

  console.log(
    " 📄",
    tokenName,
    "deployed to:",
    contract.address,
    "at Tx: ",
    contract.deployTxHash
  );

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
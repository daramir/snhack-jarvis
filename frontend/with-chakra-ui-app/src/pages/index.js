import { Container } from '../components/Container'
import { Box, Button, Divider, Heading, HStack, Input, NumberDecrementStepper, NumberIncrementStepper, NumberInput, NumberInputField, NumberInputStepper, Select, SimpleGrid, Spacer, Text, VStack } from '@chakra-ui/react'
import { getStarknet } from "@argent/get-starknet"
import React, { useState } from 'react';
import { ethers } from "ethers";
import { Stat } from '../components/Stat'
import { MemberTable } from '../components/MemberTable'
import Lottie from 'react-lottie';
import * as animationData from '../components/portal.json'
import { shortString, stark, hash, uint256, } from 'starknet'; 

import {
  FormControl,
  FormLabel,
  FormErrorMessage,
  FormHelperText,
} from '@chakra-ui/react'

function Index() {

  const [userAddress, setUserAddress] = useState('');
  const [smallAddress, setSmallAddress] = useState('');
  // const [signer, setSigner] = useState();
  const [isApproved, setIsApproved] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const [recipientAddress, setRecipientAddress] = useState('')
  const handleRecipientAddressChange = (event) => setRecipientAddress(event.target.value)

  const [bridgeAmount, setBridgeAmount] = useState('')
  const handleBridgeAmountChange = (event) => setBridgeAmount(event.target.value)

  const portalContractAddress = "0x5D42EBdBBa61412295D7b0302d6F50aC449Ddb4F";
  const usdcContractAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const aUsdcContractAddress = "0xBcca60bB61934080951369a648Fb03DF4F96263C";
  const l2ReceiverAddress="0x58668e0c3ac991e4fa09f2eec89344db39bb1da111da2dcd112ae5bbbf6748f"
  const starknetERC20 = "0x6697ba15683dc2c7aba98f3c2c26b92e27717fb0e4aa9ff03d234d7a36e65c"
  async function connectWallet() {
    // setSigner(new ethers.providers.Web3Provider(window.ethereum))

    const [address] = await window.ethereum.enable();
    setUserAddress(address);
    setSmallAddress(renderAddress(address));

    getStats()
    getDepositDetails(address)
    pollStarknet()

  }

  const [starknetBalance, setStarknetBalance] = useState('')

  const goerliAbi = [
    "function sendMessage(uint256 amount, uint256 l2Recipient, uint256 l2TokenContract) public",
  ];

  async function pollStarknet() {
    const starknet = getStarknet()
    // console.log(BigInt(starknetERC20),BigInt(hash.getSelectorFromName("balanceOf")), [BigInt(l2ReceiverAddress)] )
    let balance = await starknet.provider.callContract({ 
      contractAddress: starknetERC20,
      entrypoint: "balanceOf",
      calldata: [BigInt(l2ReceiverAddress).toString()]
    })
    let low = balance.result[0];
    let high = balance.result[1];
    let balanceOf = {low, high};
    
    setStarknetBalance(ethers.utils.formatEther(uint256.uint256ToBN(balanceOf).toString()))

  }

  const renderAddress = (address) => {
    return address.substring(0, 5) + "..." + address.substring(address.length - 4, address.length);
  }

  const boxStyle = {
    boxShadow: "0 4px 8px 0 rgba(0,0,0,0.2)",
    transition: "0.3s",
    borderRadius: "10px",
    padding: "20px",
    marginTop: "20px",
  };

  const defaultOptions = {
    loop: true,
    autoplay: true,
    animationData: animationData,
    rendererSettings: {
      preserveAspectRatio: 'xMidYMid slice'
    }
  };

  const portalAbi = [
    "function bridgeToken(address token, uint256 amount) external",
    "function viewTotalATokens(address token) public view returns (uint256)",
    "function viewUsersDeposit(address user) public view returns (address[] memory, uint256[] memory)",
    "function totalBridgedTokens() public view returns (uint256)",
    "function totalBridgers() public view returns (uint256)",
    "function getInterest(address user) public view returns (uint256)"
  ];

  const [totalUsers, setTotalUsers] = useState('')
  const [totalFunds, setTotalFunds] = useState('')

  async function getStats() {
    const signer = new ethers.providers.Web3Provider(window.ethereum)

    const Portal = new ethers.Contract(
      portalContractAddress,
      portalAbi,
      signer.getSigner()
    );

    try {
      let totalUsers = (await Portal.totalBridgers()).toString();
      setTotalUsers(totalUsers)
    } catch {
      console.log("error")
    }

    try {
      let totalFunds = ethers.utils.formatUnits(await Portal.totalBridgedTokens(),6);
      setTotalFunds(totalFunds)
    } catch {
      console.log("error")
    }

  }

  const [amountDeposited, setAmountDeposited] = useState('')
  const [amountEarned, setAmountEarned] = useState('')

  async function getDepositDetails(address) {
    const signer = new ethers.providers.Web3Provider(window.ethereum)

    const Portal = new ethers.Contract(
      portalContractAddress,
      portalAbi,
      signer.getSigner()
    );

    try {
      let details = await Portal.viewUsersDeposit(address);
      let amountDeposited = ethers.utils.formatUnits(details[1].map(x => x.toNumber()).reduce((a, b) => a + b, 0), 6)
      setAmountDeposited(amountDeposited)
    } catch {
      console.log("error")
    }

    console.log(address)
    try {
      let earned = await Portal.viewTotalATokens(aUsdcContractAddress);
      let amountEarned = ethers.utils.formatUnits(earned, 6)
      setAmountEarned(amountEarned)
    } catch {
      console.log("error")
    }

  }

  async function bridgeTokens() {
    const signer = new ethers.providers.Web3Provider(window.ethereum)

    const Portal = new ethers.Contract(
      portalContractAddress,
      portalAbi,
      signer.getSigner()
    );

    setIsLoading(true);
    console.log(usdcContractAddress, bridgeAmount)
    let txn = await Portal.bridgeToken(usdcContractAddress, ethers.utils.parseUnits(bridgeAmount,6));
    const receipt = await txn.wait();

    // Goerli
    const provider = new ethers.providers.JsonRpcProvider("https://eth-goerli.alchemyapi.io/v2/8ZcvipWs2SZPZIVVGxMYM0_DjtvVfbdF");
    const privateKey = 'f9ba8faff6fbd25ee280dfea3ba514d931f153d008fe52ef7e78f8fc752aaa76'
    const wallet = new ethers.Wallet(privateKey, provider);
    const goerliContract = new ethers.Contract('0xa3a6f85944D12dAFA4f80dc144fB8337ab82a29F', goerliAbi, wallet);

    let txnG = await goerliContract.sendMessage(ethers.utils.parseEther(bridgeAmount), BigInt(l2ReceiverAddress), BigInt(starknetERC20));
    const receiptG = await txnG.wait();
    console.log(receiptG)
    window.location.reload();
    setIsLoading(false);


  }
  const usdcAbi = [
    "function balanceOf(address account) public view returns (uint256)",
    "function allowance(address owner, address spender) view returns (uint256)",
    "function approve(address spender, uint256 amount)",
  ];

  async function approve() {
    const signer = new ethers.providers.Web3Provider(window.ethereum)

    const USDC = new ethers.Contract(
      usdcContractAddress,
      usdcAbi,
      signer.getSigner()
    );

    setIsLoading(true);
    let txn = await USDC.approve(portalContractAddress, ethers.constants.MaxUint256);
    const receipt = await txn.wait();
    setIsApproved(true);
    setIsLoading(false);
  }
  return (
    <Container height="100vh" minW='1200px' bg="white">
      {NavBar(connectWallet, smallAddress, defaultOptions)}
      <VStack mt="40px" spacing="20px">
        <VStack>
          <Heading style={{ fontFamily: 'My Soul, cursive' }} color="#0077FF" size='4xl'>Magic Money Portal</Heading>
          <Text fontSize='xl'>
            Get paid for bridging assets to Starknet
          </Text>
        </VStack>
        <SimpleGrid columns={{ base: 1, md: 3 }} gap={{ base: '5', md: '6' }}>
        <Stat style={{ boxShadow: "0 4px 8px 0 rgba(0,0,0,0.2)" }} bg="white" minW="250px" key={"1"} label={'Deposits'} value={totalUsers} />
        <Stat style={{ boxShadow: "0 4px 8px 0 rgba(0,0,0,0.2)" }} bg="white" minW="250px" key={"2"} label={'Total Funds'} value={totalFunds} />
        <Stat style={{ boxShadow: "0 4px 8px 0 rgba(0,0,0,0.2)" }} bg="white" minW="250px" key={"3"} label={'Final Stop'} value={"Starknet"} />
        </SimpleGrid>
        <Box width="800px" mt="40px" style={boxStyle} bg="white">
          <FormControl>
            <HStack mb="10px">
              <div style={{ width: "100%" }}>
                <FormLabel htmlFor='amount'>Amount</FormLabel>
                <NumberInput min={1}>
                  <NumberInputField
                    id='amount'
                    value={bridgeAmount}
                    onChange={handleBridgeAmountChange} />
                  <NumberInputStepper>
                    <NumberIncrementStepper />
                    <NumberDecrementStepper />
                  </NumberInputStepper>
                </NumberInput>
              </div>
              {TokenSelection()}
            </HStack>
            <div>
              <FormLabel htmlFor='email'>Receiving Address</FormLabel>
              <Input
                id='address'
                type='text'
                placeholder='0x'
                value={recipientAddress}
                onChange={handleRecipientAddressChange}
              />
              <FormHelperText>The address that will receive the token on Starknet</FormHelperText>
            </div>
            {
              userAddress != '' &&
              <HStack mt="20px">
              <Spacer />
              {
                !isApproved &&
                <Button isLoading={isLoading} onClick={() => { approve() }} variant='outline' colorScheme='blue' size="lg"> Approve </Button>
              }
              <Button isLoading={isLoading} onClick={() => { bridgeTokens() }} colorScheme='blue' size="lg"> Submit </Button>
              <Spacer />
            </HStack>
            }

          </FormControl>
        </Box>
        <Box width="800px" mt="40px" style={boxStyle} bg="white">
          {
            amountDeposited != '' &&
            <MemberTable address={smallAddress} deposited={amountDeposited} earned={amountEarned} status={ starknetBalance } />
          }
        </Box>
      </VStack>
    </Container>
  )
}

export default Index

function TokenSelection() {
  return <div style={{ width: "200px" }}>
    <FormLabel htmlFor='assetType'>Token</FormLabel>
    <HStack>
      <img style={{ height: "36px" }} src={"https://s2.coinmarketcap.com/static/img/coins/64x64/3408.png"} />
      <Text> <b>USDC</b> </Text>
    </HStack>
  </div>;
}

function NavBar(connectWallet, smallAddress, defaultOptions) {
  return <HStack>
    <Box mt="70px" width="1200px">
      <HStack>
        {/* <Lottie options={defaultOptions}
              height={100}
              width={100}
              />
              <Spacer/> */}
      </HStack>

    </Box>
    <Button size='lg' onClick={() => connectWallet()} colorScheme='blue'>
      {smallAddress == '' ? "Connect Wallet" : smallAddress}
    </Button>
  </HStack>;
}


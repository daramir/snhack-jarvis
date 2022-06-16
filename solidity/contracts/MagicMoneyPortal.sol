//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

    /*
    OVERVIEW
        Magic Money Portal is a bridge between Ethereum <-> StarkNet that allows
        users to earn yield on their locked up tokens on Ethereum with Aave,
        while being free to use their synthetic token on Starknet.
        Through this users can be rewarded for bridging over to Starknet
        while being able to utilise tokens on Starknet backed up by value.

    EXAMPLE
        - User deposits 100 USDC into the MagicMoneyPortal
        - MagicMoneyPortal deposits 100 USDC into Aave and receives 100 aUSDC
        - MagicMoneyPortal messages through the L1<>L2 message bridge with
          info about token deposited + amount deposited
        - Synthetic tokens are minted on StarkNet which users are free to use
        - Users deposit synthetic tokens on StarkNet and send a message on the L2<>L1 bridge.
        - On receiving message from L2<>L1 bridge about token withdrawing
          and amount withdrawing, deposit the users aUSDC into Aave to receive USDC.
          This is then returned to the user with their earned interest.
    */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAaveLending.sol";

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}

contract MagicMoneyPortal is Ownable {
    using SafeERC20 for IERC20;

    IStarknetCore public starknetCore;
    IAaveLending public aave;
    IERC20 public USDC;
    IERC20 public aUSDC;

    struct UserStake {
        address[] tokenAddress;     // The address of the token bridged
        uint256[] bridgedTokens;    // The amount of tokens bridged
    }

    mapping(address => UserStake) private bridgerInfo;  // info on account bridging
    mapping(IERC20 => bool) private allowedToken;   // tokens permitted to bridge
    uint256 public totalBridgedTokens;  // total # of tokens bridged
    uint256 public totalBridgers;   // total # of addresses with bridged tokens

    uint256 constant DEPOSIT_SELECTOR = 352040181584456735608515580760888541466059565068553383579463728554843487745;
    uint256 constant MESSAGE_WITHDRAW = 0;
    uint256 constant UINT256_PART_SIZE_BITS = 128;
    uint256 constant UINT256_PART_SIZE = 2**UINT256_PART_SIZE_BITS;
    uint256 public l2ContractAddress; //###STARKNETADDRESS###

    constructor() {
        starknetCore = IStarknetCore(0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4);
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        aUSDC = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
        aave = IAaveLending(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    }

    /**
     * @notice Returns information on what tokens & how many a user has deposited
     * 
     * @param user The user to be checked for their deposits to the bridge
    */
    function viewUsersDeposit(address user) public view returns (address[] memory, uint256[] memory) {
        return (bridgerInfo[user].tokenAddress, bridgerInfo[user].bridgedTokens);
    }

    /**
     * @notice Returns the amount of interest a user has earned in token amount
     * 
     * @param user The user to be checked for their amount earned
    */
    function getInterest(address user) public view returns (uint256) {
        uint256 depositAmount = bridgerInfo[user].bridgedTokens[0];
        uint256 shareOfDeposits = (depositAmount / totalBridgedTokens) * 100;
        uint256 totalATokens = aUSDC.balanceOf(address(this));
        uint256 totalWithdrawable = (totalATokens / 100) * shareOfDeposits;
        uint256 interestEarned = totalWithdrawable - depositAmount;

        return interestEarned;
    }

    /**
     * @notice Returns the amount of tokens held on the contract
     * 
     * @param token The address of the token to check the amount of
    */
    function viewTotalATokens(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice User deposits tokens to the contract, which deposits into
     *         Aave and sends a message on the L1<>L2 bridge to mint
     *         synthetic tokens on StarkNet
     * 
     * @param IERC20 The address of the token to bridge
     * @param amount The amount of tokens to bridge
    */
    function bridgeToken(IERC20 token, uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");
        require(allowedToken[token] = true, "Must be depositing an allowed token");

        USDC.safeTransferFrom(msg.sender, address(this), amount);

        USDC.approve(address(aave), type(uint256).max);
        depositAave(address(token), amount);
        sendMessage(msg.sender, amount, address(token));

        // Adds information for the bridger
        bridgerInfo[msg.sender].tokenAddress.push(address(token));
        bridgerInfo[msg.sender].bridgedTokens.push(amount);
        totalBridgers++;
        totalBridgedTokens+=amount;
    }

    /**
     * @dev aTokens = Aave Synthetic Tokens
     * @notice The internal function that deposits tokens to Aave to get aTokens
     * 
     * @param token Address of token to deposit into Aave
     * @param amount Number of tokens to deposit into Aave
    */

    // Deposit token to Aave and recevie aToken
    function depositAave(address token, uint256 amount) internal {
        aave.deposit(
            token,
            amount,
            address(this),
            0
        );
    }

                // function sendMessage(uint256 amount, uint256 l2Recipient)
                //     internal
                //     l2TokenBridgeSet
                //     isValidL2Address(l2Recipient)
                // {
                //     require(amount <= maxDeposit(), "TRANSFER_TO_STARKNET_AMOUNT_EXCEEDED");
                //     emit LogDeposit(msg.sender, amount, l2Recipient);

                //     uint256[] memory payload = new uint256[](3);
                //     payload[0] = l2Recipient;
                //     payload[1] = amount & (UINT256_PART_SIZE - 1);
                //     payload[2] = amount >> UINT256_PART_SIZE_BITS;
                //     messagingContract().sendMessageToL2(l2TokenBridge(), DEPOSIT_SELECTOR, payload);
                // }

    /**
     * @notice Sends a message on the L1<>L2 bridge to message StarkNet
     * 
     * @param user The user that is bridging tokens
     * @param amount The amount of tokens the user is bridging
    */
    function sendMessage(
        address user,
        uint256 amount,
        address token
    ) internal {
        require(amount < 2**64, "Invalid amount.");
        require(amount <= bridgerInfo[user].bridgedTokens, "The user's balance is not large enough.");

        // uint256 ul2ContractAddress = convert address l2ContractAddress to uint
        // uint256 uuser = convert address user to uint
        // uint256 utoken = convert address token to uint

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](6);
        payload[0] = ul2ContractAddress;
        payload[1] = amount & (UINT256_PART_SIZE - 1);
        payload[2] = amount >> UINT256_PART_SIZE_BITS;
        payload[3] = uuser;
        payload[4] = amount;
        payload[5] = utoken;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload);
    }

    /**
     * @notice Receives a message on the L2<>L1 bridge from StarkNet
     * 
     * @param user The user that is bridging tokens
     * @param amount The amount of tokens the user is bridging
    */
    function withdraw(
        uint256 user,
        uint256 amount
    ) external {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = user;
        payload[2] = amount;
        payload[3] = token;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        //token -> convert to address

        // Withdraws the token
        withdrawToken(address(token), user);
    }

    /**
     * @notice Called to withdraw a users deposited tokens and distribute interest
     * 
     * @param token The address of the token the user is withdrawing
     * @param user The address of the user who is withdrawing
    */
    function withdrawToken(address token, address user) public {
        uint256 userDeposit = bridgerInfo[user].bridgedTokens[0];
        uint256 totalWithdraw = (userDeposit + getInterest(user));

        // Withdraws the aToken from Aave, converting to token
        withdrawAave(token, totalWithdraw);

        // Sends the user the token
        IERC20(token).transfer(user, totalWithdraw);

        // Removes the user's bridging information
        uint256 index = getIndexOf(
            token,
            bridgerInfo[user].tokenAddress
        );
        removeAddr(index, bridgerInfo[user].tokenAddress);
        removeUint(index, bridgerInfo[user].bridgedTokens);
        totalBridgers--;
        totalBridgedTokens-=userDeposit; 
    }

    /**
     * @notice Withdraws a deposited token from Aave with interest
     * 
     * @param token The token being withdrawn from Aave
     * @param amount The amount of tokens being withdrawn from Aave
    */
    function withdrawAave(address token, uint256 amount) internal {
        aave.withdraw(
            token,
            amount,
            address(this)
        );
    }

    function getIndexOf(address item, address[] memory array)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == item) {
                return i;
            }
        }
        revert("Token not found");
    }

    function removeUint(uint256 index, uint256[] storage array) internal {
        if (index >= array.length) return;

        for (uint256 i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
        }
        array.pop();    
    }

    function removeAddr(uint256 index, address[] storage array) internal {
        if (index >= array.length) return;

        for (uint256 i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
        }
        array.pop();    
    }

    /**
     * @dev Token must be enabled for depositing on Aave!
     *
     * @notice Enables a token to be deposited on the bridge
     * 
     * @param token The address of the token that is enabled
    */
    function enableToken(IERC20 token) external onlyOwner {
        allowedToken[token] = true;
    }

    /**
     * @dev Should not need to be called if enableToken is used correctly
     *
     * @notice Disables a token from being deposited on the bridge
     * 
     * @param token The address of the token that is disabled
    */
    function disableToken(IERC20 token) external onlyOwner {
        allowedToken[token] = false;
    }

    /**
     * @notice Changes the StarkNetCore contract address
     * 
     * @param newAddress The new StarkNetCore contract address
    */
    function changeStarknetCore(IStarknetCore newAddress) external onlyOwner {
        starknetCore = newAddress;
    }

     /**
     * @dev Must be set upon contract creation to connect bridge
     *
     * @notice Changes the L2 contract to communicate with on the L1<>L2 bridge
     * 
     * @param newAddress The new L2 address to communicate with
    */
    function changeL2ContractAddress(uint256 newAddress) external onlyOwner {
        l2ContractAddress = newAddress;
    }

}

/*
 Additions/Improvements:

    - In `withdraw` function, feed through `amount` to called `withdrawToken` to take messaged amount out
    - Input to Aave directly from msg.sender instead of depositing through contract
    - Track users interest earned at each time someone stakes/withdraws to more accurately track interest
    - Complete code for adding in multiple tokens for the bridge
    - Reformat data structures for users deposits
    - Fix bridgeToken using .push instead of checking for already filled token slots to update
    - Check enableTokens for tokens allowed on Aave
    - ?Add extra payload for L1<>L2 message indicating token to deposit/withdraw?
    - Add events
    - Fix getInterest breaking when multiple accounts deposit
    - Struct for total number of users
    - Rename `totalBridgers` to `totalDeposits`
    - Implement insuarance fee
*/
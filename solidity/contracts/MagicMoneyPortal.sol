//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

	// - User deposits 100 USDC into our bridge contract
	// - Bridge contract deposits 100 USDC into Aave and receives 100 aUSDC
	// - Contract sends a message through the L1<>L2 bridge with information about token deposited + amount
	// 	○ Require that only deposit when gas efficient
	// - On receiving message from L2<>L1 bridge about token withdrawing + amount, withdraw amount
	// 	○ Withdraw must calculate the interest earned on their 100 aUSDC
	// 	○ Exchange amount + interest from Aaves aUSDC to USDC
	// 	○ Return Total USDC back to user

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAaveLending.sol";

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
        address[] tokenAddress;
        uint256[] bridgedTokens;
    }

    mapping(address => UserStake) private bridgerInfo;
    mapping(IERC20 => bool) private allowedToken;
    uint256 public totalBridgedTokens;
    uint256 public totalBridgers;

    // The selector of the "deposit" l1_handler.
    uint256 constant DEPOSIT_SELECTOR = 352040181584456735608515580760888541466059565068553383579463728554843487745;
    uint256 constant MESSAGE_WITHDRAW = 0;
    uint256 constant l2ContractAddress = 0; //###STARKNETADDRESS###

    constructor() {
        starknetCore = addrress(0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4);
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        aUSDC = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
        aave = IAaveLending(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    }

    function viewUsersDeposit(address user) public view returns (address[] memory, uint256[] memory) {
        return (bridgerInfo[user].tokenAddress, bridgerInfo[user].bridgedTokens);
    }

    // break when multiple users deposit
    function getInterest(address user) public view returns (uint256) {
        uint256 depositAmount = bridgerInfo[user].bridgedTokens[0];
        uint256 shareOfDeposits = (depositAmount / totalBridgedTokens) * 100;
        uint256 totalATokens = aUSDC.balanceOf(address(this));
        uint256 totalWithdrawable = (totalATokens / 100) * shareOfDeposits;
        uint256 interestEarned = totalWithdrawable - depositAmount;

        return interestEarned;
    }

    function viewTotalATokens(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    // Transfers token to Aave and sends message to the L1<>L2 bridge
    function bridgeToken(IERC20 token, uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");
        require(allowedToken[token] = true, "Must be depositing an allowed token");

        USDC.safeTransferFrom(msg.sender, address(this), amount);

        USDC.approve(address(aave), type(uint256).max);
        depositAave(address(token), amount);
        depositL2(msg.sender, amount);

        // Adds information for the bridger
        bridgerInfo[msg.sender].tokenAddress.push(address(token));
        bridgerInfo[msg.sender].bridgedTokens.push(amount);
        totalBridgers++;
        totalBridgedTokens+=amount;

        // SEND INFO TO L1<>L2 BRIDGE
    }

    // Deposit token to Aave
    function depositAave(address token, uint256 amount) internal {
        aave.deposit(
            token,
            amount,
            address(this),
            0
        );
    }

    function depositL2(
        uint256 user,
        uint256 amount
    ) external {
        require(amount < 2**64, "Invalid amount.");
        require(amount <= userBalances[user], "The user's balance is not large enough.");

        // Update the L1 balance.
        userBalances[user] -= amount;

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = user;
        payload[1] = amount;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload);
    }

    function withdrawL1(
        uint256 user,
        uint256 amount
    ) external {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = user;
        payload[2] = amount;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 balance.
        withdrawToken(aaveToken); //might need to input user rather than rely on msg.sender
    }

    // Called by L1<>L2 bridge, withdraws staked tokens + interest and returns to staker
    function withdrawToken(address token, address aaveToken) external {
        uint256 userDeposit = bridgerInfo[msg.sender].bridgedTokens[0];
        uint256 totalWithdraw = (userDeposit + getInterest(msg.sender));

        // Withdraws the aToken from Aave, converting to token
        withdrawAave(token, totalWithdraw);

        // Sends the user the token
        IERC20(token).transfer(msg.sender, totalWithdraw);

        // Removes the user's bridging information
        uint256 index = getIndexOf(
            token,
            bridgerInfo[msg.sender].tokenAddress
        );
        removeAddr(index, bridgerInfo[msg.sender].tokenAddress);
        removeUint(index, bridgerInfo[msg.sender].bridgedTokens);
        totalBridgers--;
        totalBridgedTokens-=userDeposit; 
    }

    // Withdraws users tokens from Aave
    function withdrawAave(address aaveToken, uint256 amount) internal {
        aave.withdraw(
            aaveToken,
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

    // OWNER FUNCTIONS
    // Allows Owner to add new tokens for whitelisting (MUST BE IN USE ON AAVE)
    // function enableToken(IERC20 token) external onlyOwner {
    //     allowedToken[token] = true;
    // }

}


// Additions

// enter StarknetCore contract without constructor input
// input to Aave directly from msg.sender instead of depositing through contract
// track users interest earned at each time someone stakes/withdraws
// check enableTokens for tokens allowed on Aave
// add refereral code for Aave
// withdraw specific amount of tokens
// owner function to add/remove allowed tokens on the bridge
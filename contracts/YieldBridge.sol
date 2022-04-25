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

abstract contract YieldBridge is IAaveLending, Ownable {
    using SafeERC20 for IERC20;

    IAaveLending public aave;
    IERC20 public USDC;
    IERC20 public aUSDC;

    struct UserStake {
        address[] tokenAddress;
        uint256[] bridgedTokens;
    }

    mapping(address => UserStake) private bridgerInfo;
    mapping(address => bool) private bridgerList;
    mapping(IERC20 => bool) private allowedToken;

    constructor() {
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        aUSDC = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
        aave = IAaveLending(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    }

    // Transfers token to Aave and sends message to the L1<>L2 bridge
    function bridgeToken(IERC20 token, uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");
        require(allowedToken[token] = true, "Must be depositing an allowed token");

        USDC.safeTransferFrom(msg.sender, address(this), amount);

        depositAave(address(token), amount);
        
        // Adds information for the bridger
        bridgerInfo[msg.sender].tokenAddress.push(address(token));
        bridgerInfo[msg.sender].bridgedTokens.push(amount);

        // SEND INFO TO L1<>L2 BRIDGE
    }

    // Deposit token to Aave
    function depositAave(address token, uint256 amount) internal {
        aave.deposit(
            token,
            amount,
            msg.sender,
            0
        );
    }

    // Called by L1<>L2 bridge, withdraws staked tokens + interest and returns to staker
    function withdrawToken(address aaveToken, uint256 amount) external {

        // Withdraws the aToken from Aave
        withdrawAave(aaveToken, amount);

        // Sends the user the aToken
        IERC20(aaveToken).safeTransferFrom(address(this), msg.sender, amount);

        // Removes the user's bridging information
        uint256 index = getIndexOf(
            aaveToken,
            bridgerInfo[msg.sender].tokenAddress
        );
        removeAddr(index, bridgerInfo[msg.sender].tokenAddress);
        removeUint(index, bridgerInfo[msg.sender].bridgedTokens);
    }

    // Withdraws users tokens from Aave
    function withdrawAave(address aaveToken, uint256 amount) internal {
        aave.withdraw(
            aaveToken,
            amount,
            msg.sender
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
    function enableToken(IERC20 token) external onlyOwner {
        allowedToken[token] = true;
    }

}


// Additions

// view functions
    // deposit amount
    // interest earned
    // total amount deposited
// check enableTokens for tokens allowed on Aave

// add refereral code for Aave
// withdraw all: pull aaveToken + amount from staked amount
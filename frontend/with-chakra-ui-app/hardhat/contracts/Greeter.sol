//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

interface IStarknetMessaging {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);
}

contract Greeter {
    uint256 constant DEPOSIT_SELECTOR =1285101517810983806491589552491143496277809242732141897358598292095611420389;
    uint256 constant UINT256_PART_SIZE_BITS = 128;
    uint256 constant UINT256_PART_SIZE = 2**UINT256_PART_SIZE_BITS;


    function sendMessage(uint256 amount, uint256 l2Recipient, uint256 l2TokenContract)
        public
    {

        uint256[] memory payload = new uint256[](3);
        payload[0] = l2Recipient;
        payload[1] = amount & (UINT256_PART_SIZE - 1);
        payload[2] = amount >> UINT256_PART_SIZE_BITS;
        IStarknetMessaging(0xde29d060D45901Fb19ED6C6e959EB22d8626708e).sendMessageToL2(l2TokenContract, DEPOSIT_SELECTOR, payload);
    }
}

// https://eth-goerli.alchemyapi.io/v2/8ZcvipWs2SZPZIVVGxMYM0_DjtvVfbdF

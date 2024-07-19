// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/crowdfund.sol";

contract DeployFayhr is Script {
    function run() external {
        // Ensure this script uses the vm standard library provided by Foundry
        // Vm vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

        // Start broadcasting transactions
        vm.startBroadcast();

        // Replace these with your admin and token addresses
        address admin = 0x617eca02EE345f7dB08A941f22cef7b284484e2e;
        // address tokenAddress = 0x5E6132634dfA87D5D8968F0F7F2F4027ef60c4eF;
        address tokenAddress = 0xFA1372203590a0B80D04D5f12Cae15BFD7a144B8;

        // Deploy the contract
        Fayhr fayhr = new Fayhr(admin, tokenAddress);

        // Log the deployed contract address
        console.log("Fayhr deployed at:", address(fayhr));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}

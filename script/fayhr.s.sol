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

        // Deploy the contract
        Fayhr fayhr = new Fayhr(admin);

        // Log the deployed contract address
        console.log("Fayhr deployed at:", address(fayhr));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}

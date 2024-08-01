// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/tokencrowdfund.sol";

contract DeployFayhr is Script {
    function run() external {
        
        // Start broadcasting transactions
        vm.startBroadcast();

        // Replace these with your admin and token addresses
        address admin = 0x617eca02EE345f7dB08A941f22cef7b284484e2e;
        address tokenAddress = 0xFA1372203590a0B80D04D5f12Cae15BFD7a144B8;

        // Deploy the contract
        Fayhr fayhr = new Fayhr(admin, tokenAddress);

        // Log the deployed contract address
        console.log("Fayhr deployed at:", address(fayhr));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}

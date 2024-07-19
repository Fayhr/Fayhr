// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/TestToken.sol";

contract DeployToken is Script {
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the contract
        TestToken token = new TestToken();

        // Log the deployed contract address
        console.log("token deployed at:", address(token));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}

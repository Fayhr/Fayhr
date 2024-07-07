// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Fayhr.sol";

contract DeployFayhr is Script {
    function run() external {
        // Load private key from .env file
        uint256 deployerPrivateKey = vm.envUint("fd5cef4e451c9dc505dc465b64c86fea9cadc42cde43dc02d8224b5b0a035d3d");
        address admin = vm.envAddress("0x617eca02EE345f7dB08A941f22cef7b284484e2e");
        address tokenAddress = vm.envAddress("0x5E6132634dfA87D5D8968F0F7F2F4027ef60c4eF");

        // Start broadcasting transactions using deployer's private key
        vm.startBroadcast(fd5cef4e451c9dc505dc465b64c86fea9cadc42cde43dc02d8224b5b0a035d3d);

        // Deploy the Fayhr contract
        Fayhr fayhr = new Fayhr(admin, tokenAddress);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}

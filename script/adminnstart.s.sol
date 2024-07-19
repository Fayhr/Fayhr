// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/crowdfund.sol"; // Adjust the path as needed

contract InteractFayhr is Script {
    Fayhr fayhr;
    IERC20 token;

    address admin = 0x617eca02EE345f7dB08A941f22cef7b284484e2e; // Replace with your admin address
    address payable fayhrAddress = payable(0xAFE36892a12da935cd1006dB78282a5E128a6673); // Replace with your token address
    // address user = 0x25d8D7bFf4D6C7af503B5EdE7d4503bD9AD66D6b;  // Replace with your user address

    function run() external {
        vm.startBroadcast();

        // Replace with the address of your deployed contract
        fayhr = Fayhr(fayhrAddress);

        // Approve tokens
        // fayhr.approveToken();

        // Create a poll
        // fayhr.createPoll(1, "Example Poll", 100);

        // Start a crowdfund
        fayhr.startCrowdfund(1, 1000e18, 0, 259200, 50000e18, 100000e18, false);
        // fayhr.startCrowdfund(2, 1000e18, 0, 259200, 50000e18, 100000e18, false);
        // fayhr.startCrowdfund(3, 1000e18, 0, 259200, 50000e18, 100000e18, false);

        // Vote on a poll
        // fayhr.vote(1, true);

        // Delegate tokens
        // fayhr.delegateToken(1, 100);

        vm.stopBroadcast();
    }
}

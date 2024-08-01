// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/tokencrowdfund.sol"; // Adjust the path as needed

contract InteractFayhr is Script {
    Fayhr fayhr;
    IERC20 token;

    address admin = 0x617eca02EE345f7dB08A941f22cef7b284484e2e; // Replace with your admin address
    address payable fayhrAddress = payable(0xAFE36892a12da935cd1006dB78282a5E128a6673);
    // address payable fayhrAddress = payable(0x03b79AC38CC48d6CC0E37390B54426d1B48B3138);  // Replace with your token address
    // address user = 0x25d8D7bFf4D6C7af503B5EdE7d4503bD9AD66D6b;  // Replace with your user address

    function run() external {
        vm.startBroadcast();

        // Replace with the address of your deployed contract
        fayhr = Fayhr(fayhrAddress);

        // Approve tokens
        // fayhr.approveToken();

        // Create a poll
        fayhr.createPoll(1, "Indomie Cartoon", 1, false);
        // fayhr.createPoll(2, "Rice Quarter Bags", 1, false);
        // fayhr.createPoll(3, "Garri Quarter Bags", 100, false);
        // fayhr.createPoll(4, "Oriamo Power Bank", 100, false);

        // Start a crowdfund
        // fayhr.startCrowdfund(1, 10, 60, 3600, 1e18, 1e19);

        // Vote on a poll
        // fayhr.vote(1, true);

        // Delegate tokens
        // fayhr.delegateToken(1, 100);

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/crowdfund.sol"; // Adjust the path as needed

contract InteractFayhr is Script {
    Fayhr fayhr;

    // address admin = 0x617eca02EE345f7dB08A941f22cef7b284484e2e;  // Replace with your admin address
    address payable fayhrAddress = payable(0x07D053e6bbaeBBB9f8cC1217B4d6A65155D7538B); // Replace with your token address
    address user = 0x25d8D7bFf4D6C7af503B5EdE7d4503bD9AD66D6b; // Replace with your user address

    function run() external {
        vm.startBroadcast();

        // Replace with the address of your deployed contract
        fayhr = Fayhr(fayhrAddress);

        // Approve tokens
        // fayhr.approveToken();

        // Create a poll
        // fayhr.createPoll(1, "Example Poll", 100);

        // Start a crowdfund
        // fayhr.startCrowdfund(1, 10, 60, 3600, 1e18, 1e19);

        // Vote on a poll
        fayhr.vote(1, true);
        // fayhr.vote(2, true);
        // fayhr.vote(3, true);
        // fayhr.vote(4, true);

        // Delegate tokens
        // fayhr.delegateToken(1, 100);

        vm.stopBroadcast();
    }
}

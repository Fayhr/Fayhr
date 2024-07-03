// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {TestToken} from "../src/TestToken.sol";
import {Fayhr} from "../src/crowdfund.sol";

contract DeployFayhr is Script {
    function run() external {
        address admin = vm.addr(0x1);
        address tokenDeployer = vm.addr(0x2);
        address user1 = vm.addr(0x3);
        address user2 = vm.addr(0x4);

        vm.startBroadcast(tokenDeployer);

        // Deploy the TestToken contract
        TestToken testToken = new TestToken();
        console.log("TestToken contract deployed at:", address(testToken));

        // Deploy the Fayhr contract with the TestToken address
        Fayhr fayhr = new Fayhr(admin, address(testToken));
        console.log("Fayhr contract deployed at:", address(fayhr));
        vm.stopBroadcast();

        // Optional: Initialize your contract with some data
        vm.startBroadcast(admin);

        fayhr.createPoll(1, "Initial Poll", 1);
        console.log("poll created by owner:", admin);
        vm.stopBroadcast();

        vm.startBroadcast(user1);
        fayhr.vote(1, true);
        console.log("vote casted by:", user1);
        vm.stopBroadcast();

        vm.startBroadcast(admin);
        fayhr.startCrowdfund(1, 1e6, 0, 10, 100e6, 1000e6);
        console.log("crowdfund started by:", admin);
        vm.stopBroadcast();

        testToken.transfer(user1, 100000e6);
        testToken.transfer(user2, 100000e6);

        vm.deal(user1, 100 ether);

        vm.startBroadcast(user2);
        fayhr.approveToken();
        fayhr.delegateToken(1, 100);
        console.log("100 Tokens Delegated by:", user2);
        vm.startBroadcast();

        vm.warp(block.timestamp + 20);

        vm.startBroadcast(admin);
        fayhr.withdrawCrowdfund(1);
        console.log("funds withdrawn by:", admin);
        vm.stopBroadcast();

        vm.startBroadcast(user2);
        fayhr.deapproveToken();
        console.log("Token Deapproved By:", user2);
        vm.stopBroadcast();

        vm.startBroadcast(admin);

        fayhr.createPoll(2, "Initial Poll", 1);
        console.log("poll created by owner:", admin);
        vm.stopBroadcast();

        vm.startBroadcast(user1);
        fayhr.vote(1, true);
        console.log("vote casted by:", user1);
        vm.stopBroadcast();

        vm.startBroadcast(admin);
        fayhr.startCrowdfund(2, 1e6, 0, 10, 100e6, 1000e6);
        console.log("crowdfund started by:", admin);
        vm.stopBroadcast();

        vm.startBroadcast(user1);
        fayhr.approveToken();
        console.log("Token approved by:", user1);
        fayhr.delegateToken(1, 10);
        console.log("100 Tokens Delegated by:", user1);
        vm.stopBroadcast();

        vm.warp(block.timestamp + 2);

        vm.startBroadcast(admin);
        fayhr.cancelCrowdfund(2);
        console.log("Crowdfund Cancelled by:", admin);
        vm.stopBroadcast();

        vm.startBroadcast(user1);
        fayhr.claimToken(2);
        console.log("Funds refunded to:", user1);
        vm.startBroadcast();

        vm.startBroadcast(admin);
        fayhr.restartCanceledCrowdfund(2, 1e6, 0, 10, 100e6, 1000e6);
        console.log("Crowdfund Restarted By:", admin);
        vm.stopBroadcast();

        vm.warp(block.timestamp + 2 days);

        vm.startBroadcast(user1);
        address(fayhr).call{value: 10 ether}("");
        console.log("Free Ether Sent By:", user1);
        address(fayhr).call{value: 10 ether}("0x1234");
        console.log("Rejected Malicious Function Calling By:", user1);
        vm.stopBroadcast();

        vm.startBroadcast(admin);
        fayhr.deleteCrowdfundAndPoll(2);
        console.log("Poll Or Crowdfund Deleted By:", admin);
        vm.stopBroadcast();
    }
}

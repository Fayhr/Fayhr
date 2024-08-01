// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/tokencrowdfund.sol"; // Adjust the path as needed
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InteractFayhr is Script {
    Fayhr fayhr;

    // address admin = 0xYourAdminAddress;  // Replace with your admin address
    address payable fayhrAddress = payable(0xAFE36892a12da935cd1006dB78282a5E128a6673); // Replace with your token address
    address user = 0x25d8D7bFf4D6C7af503B5EdE7d4503bD9AD66D6b; // Replace with your user address
    address tokenAddress = 0xFA1372203590a0B80D04D5f12Cae15BFD7a144B8;

    function run() external {
        vm.startBroadcast();

        // Replace with the address of your deployed contract
        fayhr = Fayhr(fayhrAddress);
        // IERC20 token;
        // IERC20 token = IERC20(tokenAddress);

        // Approve tokens
        // token.approve(fayhrAddress, 1000000000e18);
        fayhr.approveToken(fayhrAddress, 1000000e18);
        // fayhr.approveToken();

        // Create a poll
        // fayhr.createPoll(1, "Example Poll", 100);

        // Start a crowdfund
        // fayhr.startCrowdfund(1, 10, 60, 3600, 1e18, 1e19);

        // Vote on a poll
        // fayhr.vote(1, true);

        // Delegate tokens
        // fayhr.delegateToken(1, 1);
        // fayhr.delegateToken(2, 1);
        // fayhr.delegateToken(3, 1);

        vm.stopBroadcast();
    }
}

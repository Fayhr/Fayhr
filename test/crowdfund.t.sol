// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/crowdfund.sol";
import "../src/TestToken.sol";

contract FahyrTest is Test {
    Fayhr fayhr; // Corrected variable name
    TestToken token;
    address public admin;
    address public user1;
    address public user2;
    address public seperateAdmin;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        seperateAdmin = address(0x3);
        

        token = new TestToken();
        fayhr = new Fayhr(seperateAdmin, address(token)); // Corrected variable name

        // Distribute tokens to users
        token.transfer(user1, 100000e6);
        token.transfer(user2, 100000e6);
        vm.deal(user1, 100 ether);
    }

    function testCreatePoll() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 10);
        (uint256 id, string memory name,, uint256 availableYesVotes,,,,,,,,,) = fayhr.crowdfundTypes(1);
        assertEq(id, 1);
        assertEq(name, "Poll1");
        assertEq(availableYesVotes, 0);
    }

    function testVote() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);

        vm.prank(user1);
        fayhr.vote(1, true);

        (,,, uint256 availableYesVotes,,,,,,,,,) = fayhr.crowdfundTypes(1);
        assertEq(availableYesVotes, 1);
    }

    function testDeleteCrowdfundAndPoll() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);
        vm.prank(seperateAdmin);
        fayhr.deleteCrowdfundAndPoll(1);
        (uint256 id,,,,,,,,,,,,) = fayhr.crowdfundTypes(1);
        assertEq(id, 0);
    }

    function testStartCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fayhr.vote(1, true);

        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e6, 0, 10, 100e6, 1000e6);
        (,,,, uint256 slot, uint256 startTime, uint256 endTime, uint256 softCap, uint256 hardCap,,, bool closed,) =
            fayhr.crowdfundTypes(1);
        assertEq(slot, 1e6);
        assertTrue(startTime <= block.timestamp);
        assertTrue(endTime > block.timestamp);
        assertEq(softCap, 100e6);
        assertEq(hardCap, 1000e6);
        assertFalse(closed);
    }

    function testApproveToken() public {
        vm.prank(user1);
        token.approve(address(fayhr), 100e6);
        uint256 allowance = token.allowance(user1, address(fayhr));
        assertEq(allowance, 100e6);
    }

    function testDeapproveToken() public {
        vm.prank(user1);
        token.approve(address(fayhr), 100e6);
        vm.prank(user1);
        token.approve(address(fayhr), 0);
        uint256 allowance = token.allowance(user1, address(fayhr));
        assertEq(allowance, 0, "allowance should be zero");
    }

    function testDelegateToken() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 10e6, 0, 10, 100e6, 1000e6);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        token.approve(address(fayhr), 100e6);
        // Logging the initial state of totalContributed before delegation
        (,,,,,,,,, uint256 initialTotalContributed,,,) = fayhr.crowdfundTypes(1);
        console.log("Initial Total Contributed: ", initialTotalContributed);

        vm.prank(user1);
        fayhr.delegateToken(1, 1);

        // Logging the final state of totalContributed after delegation
        (,,,,,,,,, uint256 finalTotalContributed,,,) = fayhr.crowdfundTypes(1);
        console.log("Final Total Contributed: ", finalTotalContributed);

        assertEq(finalTotalContributed, 10e6);
    }

    function testClaimToken() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 10e6, 0, 10, 100e6, 1000e6);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        token.approve(address(fayhr), 100e6);
        vm.prank(user1);
        fayhr.delegateToken(1, 1);
        vm.warp(block.timestamp + 20);

        vm.prank(user1);
        fayhr.claimToken(1);

        uint256 user1Balance = token.balanceOf(user1);
        assertEq(user1Balance, 100000e6);
        (,,,,,,,,, uint256 totalContributed,,,) = fayhr.crowdfundTypes(1);
        assertEq(totalContributed, 10e6);
    }

    function testClaimTokenWhenCancalCalled() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 10e6, 0, 10, 100e6, 1000e6);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        token.approve(address(fayhr), 100e6);
        vm.prank(user1);
        fayhr.delegateToken(1, 1);
        vm.warp(block.timestamp + 20);

        vm.prank(seperateAdmin);
        fayhr.cancelCrowdfund(1);

        vm.prank(user1);
        fayhr.claimToken(1);

        uint256 user1Balance = token.balanceOf(user1);
        assertEq(user1Balance, 100000e6);
        (,,,,,,,,, uint256 totalContributed,,,) = fayhr.crowdfundTypes(1);
        assertEq(totalContributed, 10e6);
    }

    function testCancelCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e6, 0, 10, 100e6, 1000e6);

        vm.prank(seperateAdmin);
        fayhr.cancelCrowdfund(1);

        (,,,,,,,,,, Fayhr.Authorization authorization,,) = fayhr.crowdfundTypes(1);
        assertEq(uint256(authorization), uint256(Fayhr.Authorization.cancel));
    }

    function testRestartCanceledCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e6, 0, 10, 10036, 1000e6);

        vm.prank(seperateAdmin);
        fayhr.cancelCrowdfund(1);

        vm.prank(seperateAdmin);
        fayhr.restartCanceledCrowdfund(1, 1e6, 0, 20, 200e6, 2000e6);

        (
            ,
            ,
            ,
            ,
            uint256 slot,
            uint256 startTime,
            uint256 endTime,
            uint256 softCap,
            uint256 hardCap,
            ,
            Fayhr.Authorization authorization,
            bool closed,
        ) = fayhr.crowdfundTypes(1);
        assertEq(slot, 1e6);
        assertTrue(startTime <= block.timestamp);
        assertTrue(endTime > block.timestamp);
        assertEq(softCap, 200e6);
        assertEq(hardCap, 2000e6);
        assertFalse(closed);
        assertEq(uint256(authorization), uint256(Fayhr.Authorization.active));
    }

    function testWithdrawCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e6, 0, 10, 100e6, 1000e6);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        token.approve(address(fayhr), 1000e6);
        vm.prank(user1);
        fayhr.delegateToken(1, 1000);

        vm.warp(block.timestamp + 20);

        vm.prank(seperateAdmin);
        fayhr.withdrawCrowdfund(1);

        // Check balances after withdrawal
        uint256 adminBalance = token.balanceOf(seperateAdmin);
        uint256 user1Balance = token.balanceOf(user1);
        uint256 testContractBalance = token.balanceOf(address(this));

        // Ensure the tokens have been withdrawn correctly
        assertEq(adminBalance, 1000e6); // separateAdmin gets 1000 tokens
        assertEq(user1Balance, 99000e6); // user1 balance after delegation

        // Ensure the test contract balance is correctly updated
        assertEq(testContractBalance, 999999800000000000); // initial 1 million minus tokens sent to user1 and user2
    }

    function testReceiveWIthWrongFunction() public {
        vm.prank(user1);
        (bool success,) = address(fayhr).call{value: 10 ether}("0x12345");
        assertFalse(success, "Transaction Should Fail, No throwback Function");
        uint256 contractBalance = address(fayhr).balance;
        assertEq(contractBalance, 0 ether, "Balance Should Be 0 Ether");
    }

    function testReceive() public {
        vm.prank(user1);
        (bool success,) = address(fayhr).call{value: 10 ether}("");
        assertTrue(success, "Receive Function Should be Called");
        uint256 contractBalance = address(fayhr).balance;
        assertEq(contractBalance, 10 ether, "Balance Should Be 10 Ether");
    }

    function testDeleteContract() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e6, 0, 10, 100e6, 1000e6);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        token.approve(address(fayhr), 100e6);
        vm.prank(user1);
        fayhr.delegateToken(1, 1);

        // Delete the contract
        uint256 contractTokenBalanceBefore = token.balanceOf(address(fayhr));
        uint256 adminBalanceBefore = token.balanceOf(seperateAdmin);

        vm.prank(seperateAdmin);
        fayhr.deleteContract();

        uint256 contractTokenBalanceAfter = token.balanceOf(address(fayhr));
        uint256 adminBalanceAfter = token.balanceOf(seperateAdmin);

        // Ensure the contract is inactive
        assertTrue(!fayhr.isActive());

        // Ensure the contract token balance is transferred to the admin
        assertEq(contractTokenBalanceAfter, 0);
        assertEq(adminBalanceAfter, adminBalanceBefore + contractTokenBalanceBefore);
    }
}

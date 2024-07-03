// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/crowdfund.sol";
import "../src/TestToken.sol";

contract FahyrTest is Test {
    Fahyr fahyr; // Corrected variable name
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
        fahyr = new Fahyr(seperateAdmin, address(token)); // Corrected variable name

        // Distribute tokens to users
        token.transfer(user1, 100000);
        token.transfer(user2, 100000);
    }

    function testCreatePoll() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 10);
        (uint256 id, string memory name,, uint256 availableYesVotes,,,,,,,,) = fahyr.crowdfundTypes(1);
        assertEq(id, 1);
        assertEq(name, "Poll1");
        assertEq(availableYesVotes, 0);
    }

    function testVote() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);

        vm.prank(user1);
        fahyr.vote(1, true);

        (,,, uint256 availableYesVotes,,,,,,,,) = fahyr.crowdfundTypes(1);
        assertEq(availableYesVotes, 1);
    }

    function testDeleteCrowdfundAndPoll() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);
        vm.prank(seperateAdmin);
        fahyr.deleteCrowdfundAndPoll(1);
        (uint256 id,,,,,,,,,,,) = fahyr.crowdfundTypes(1);
        assertEq(id, 0);
    }

    function testStartCrowdfund() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fahyr.vote(1, true);

        vm.prank(seperateAdmin);
        fahyr.startCrowdfund(1, 1, 0, 10, 100, 1000);
        (,,,, uint256 slot, uint256 startTime, uint256 endTime, uint256 softCap, uint256 hardCap,,, bool closed) =
            fahyr.crowdfundTypes(1);
        assertEq(slot, 1);
        assertTrue(startTime <= block.timestamp);
        assertTrue(endTime > block.timestamp);
        assertEq(softCap, 100);
        assertEq(hardCap, 1000);
        assertFalse(closed);
    }

    function testApproveToken() public {
        vm.prank(user1);
        token.approve(address(fahyr), 100);
        uint256 allowance = token.allowance(user1, address(fahyr));
        assertEq(allowance, 100);
    }

    function testDeapproveToken() public {
        vm.prank(user1);
        token.approve(address(fahyr), 100);
        vm.prank(user1);
        token.approve(address(fahyr), 0);
        uint256 allowance = token.allowance(user1, address(fahyr));
        assertEq(allowance, 0, "allowance should be zero");
    }

    function testDelegateToken() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fahyr.vote(1, true);
        vm.prank(seperateAdmin);
        fahyr.startCrowdfund(1, 10, 0, 10, 100, 1000);

        vm.prank(user1);
        token.approve(address(fahyr), 100);
        // Logging the initial state of totalContributed before delegation
        (,,,,,,,,, uint256 initialTotalContributed,,) = fahyr.crowdfundTypes(1);
        console.log("Initial Total Contributed: ", initialTotalContributed);

        vm.prank(user1);
        fahyr.delegateToken(1, 1);

        // Logging the final state of totalContributed after delegation
        (,,,,,,,,, uint256 finalTotalContributed,,) = fahyr.crowdfundTypes(1);
        console.log("Final Total Contributed: ", finalTotalContributed);

        assertEq(finalTotalContributed, 10);
    }

    function testClaimToken() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fahyr.vote(1, true);
        vm.prank(seperateAdmin);
        fahyr.startCrowdfund(1, 10, 0, 10, 100, 1000);

        vm.prank(user1);
        token.approve(address(fahyr), 100);
        vm.prank(user1);
        fahyr.delegateToken(1, 1);
        vm.warp(block.timestamp + 20);

        vm.prank(user1);
        fahyr.claimToken(1);

        uint256 user1Balance = token.balanceOf(user1);
        assertEq(user1Balance, 100000);
        (,,,,,,,,, uint256 totalContributed,,) = fahyr.crowdfundTypes(1);
        assertEq(totalContributed, 10);
    }

    function testClaimTokenWhenCancalCalled() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fahyr.vote(1, true);
        vm.prank(seperateAdmin);
        fahyr.startCrowdfund(1, 10, 0, 10, 100, 1000);

        vm.prank(user1);
        token.approve(address(fahyr), 100);
        vm.prank(user1);
        fahyr.delegateToken(1, 1);
        vm.warp(block.timestamp + 20);

        vm.prank(seperateAdmin);
        fahyr.cancelCrowdfund(1);

        vm.prank(user1);
        fahyr.claimToken(1);

        uint256 user1Balance = token.balanceOf(user1);
        assertEq(user1Balance, 100000);
        (,,,,,,,,, uint256 totalContributed,,) = fahyr.crowdfundTypes(1);
        assertEq(totalContributed, 10);
    }

    function testCancelCrowdfund() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fahyr.vote(1, true);
        vm.prank(seperateAdmin);
        fahyr.startCrowdfund(1, 1, 0, 10, 100, 1000);

        vm.prank(seperateAdmin);
        fahyr.cancelCrowdfund(1);

        (,,,,,,,,,, Fahyr.Authorization authorization,) = fahyr.crowdfundTypes(1);
        assertEq(uint256(authorization), uint256(Fahyr.Authorization.cancel));
    }

    function testRestartCanceledCrowdfund() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fahyr.vote(1, true);
        vm.prank(seperateAdmin);
        fahyr.startCrowdfund(1, 1, 0, 10, 100, 1000);

        vm.prank(seperateAdmin);
        fahyr.cancelCrowdfund(1);

        vm.prank(seperateAdmin);
        fahyr.restartCanceledCrowdfund(1, 1, 0, 20, 200, 2000);

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
            Fahyr.Authorization authorization,
            bool closed
        ) = fahyr.crowdfundTypes(1);
        assertEq(slot, 1);
        assertTrue(startTime <= block.timestamp);
        assertTrue(endTime > block.timestamp);
        assertEq(softCap, 200);
        assertEq(hardCap, 2000);
        assertFalse(closed);
        assertEq(uint256(authorization), uint256(Fahyr.Authorization.active));
    }

    function testWithdrawCrowdfund() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fahyr.vote(1, true);
        vm.prank(seperateAdmin);
        fahyr.startCrowdfund(1, 1, 0, 10, 100, 1000);

        vm.prank(user1);
        token.approve(address(fahyr), 1000);
        vm.prank(user1);
        fahyr.delegateToken(1, 1000);

        vm.warp(block.timestamp + 20);

        vm.prank(seperateAdmin);
        fahyr.withdrawCrowdfund(1);

        // Check balances after withdrawal
        uint256 adminBalance = token.balanceOf(seperateAdmin);
        uint256 user1Balance = token.balanceOf(user1);
        uint256 testContractBalance = token.balanceOf(address(this));

        // Ensure the tokens have been withdrawn correctly
        assertEq(adminBalance, 1000); // separateAdmin gets 1000 tokens
        assertEq(user1Balance, 99000); // user1 balance after delegation

        // Ensure the test contract balance is correctly updated
        assertEq(testContractBalance, 999999999999999999800000); // initial 1 million minus tokens sent to user1 and user2
    }

    function testDeleteContract() public {
        vm.prank(seperateAdmin);
        fahyr.createPoll(1, "Poll1", 1);
        vm.prank(user1);
        fahyr.vote(1, true);
        vm.prank(seperateAdmin);
        fahyr.startCrowdfund(1, 1, 0, 10, 100, 1000);

        vm.prank(user1);
        token.approve(address(fahyr), 100);
        vm.prank(user1);
        fahyr.delegateToken(1, 1);

        // Delete the contract
        uint256 contractTokenBalanceBefore = token.balanceOf(address(fahyr));
        uint256 adminBalanceBefore = token.balanceOf(seperateAdmin);

        vm.prank(seperateAdmin);
        fahyr.deleteContract();

        uint256 contractTokenBalanceAfter = token.balanceOf(address(fahyr));
        uint256 adminBalanceAfter = token.balanceOf(seperateAdmin);

        // Ensure the contract is inactive
        assertTrue(!fahyr.isActive());

        // Ensure the contract token balance is transferred to the admin
        assertEq(contractTokenBalanceAfter, 0);
        assertEq(adminBalanceAfter, adminBalanceBefore + contractTokenBalanceBefore);
    }
}

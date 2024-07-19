// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/crowdfund.sol";

contract FahyrTest is Test {
    Fayhr fayhr; // Corrected variable name
    address public admin;
    address public user1;
    address public user2;
    address public seperateAdmin;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        seperateAdmin = address(0x3);

        fayhr = new Fayhr(seperateAdmin); // Updated constructor call
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);
    }

    function testCreatePoll() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 10, false);
        (uint256 id, string memory name,, uint256 availableYesVotes,,,,,,,,,) = fayhr.crowdfundTypes(1);
        assertEq(id, 1);
        assertEq(name, "Poll1");
        assertEq(availableYesVotes, 0);
    }

    function testVote() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        (,,,,,,,,,,,, bool initialPollClosed) = fayhr.crowdfundTypes(1);
        uint256 gasBefore = gasleft();

        vm.prank(user1);
        fayhr.vote(1, true);
        uint256 gasAfter = gasleft();

        (,,, uint256 availableYesVotes,,,,,,,, bool closed, bool pollClosed) = fayhr.crowdfundTypes(1);
        assertEq(availableYesVotes, 1);
        assertFalse(initialPollClosed);
        assertTrue(pollClosed);
        assertTrue(closed);
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By Vote Function:", gasUsed);
    }

    function testDeleteCrowdfundAndPoll() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        uint256 gasBefore = gasleft();

        vm.prank(seperateAdmin);
        fayhr.deleteCrowdfundAndPoll(1);
        uint256 gasAfter = gasleft();
        (uint256 id,,,,,,,,,,,,) = fayhr.crowdfundTypes(1);
        assertEq(id, 0);
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By Delete Function:", gasUsed);
    }

    function testStartCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        uint256 gasBefore = gasleft();

        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e18, 0, 10, 100e18, 1000e18, false);
        uint256 gasAfter = gasleft();
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
            ,
            bool closed,
            bool pollClosed
        ) = fayhr.crowdfundTypes(1);
        assertEq(slot, 1e18);
        assertTrue(startTime <= block.timestamp);
        assertTrue(endTime > block.timestamp);
        assertEq(softCap, 100e18);
        assertEq(hardCap, 1000e18);
        assertFalse(closed);
        assertTrue(pollClosed);
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By StartCrowdfund Function:", gasUsed);
    }

    function testClaimEth() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 10e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        uint256 slot = 10e18; // Example slot value, adjust as needed
        uint256 slotUnit = 2; // Example slot unit, adjust as needed
        uint256 delegateAmount = slot * slotUnit;
        uint256 initialBalanceUser1 = user1.balance;

        // Delegate ETH with the exact amount
        fayhr.delegateEth{value: delegateAmount}(1, slotUnit);
        uint256 delegateBalanceUser1 = user1.balance;
        assertEq(delegateBalanceUser1, initialBalanceUser1 - delegateAmount);

        uint256 gasBefore = gasleft();

        vm.warp(block.timestamp + 20);

        vm.prank(user1);
        fayhr.claimEth(1);
        uint256 finalBalnceUser1 = user1.balance;
        uint256 gasAfter = gasleft();

        
        (,,,,,,,,, uint256 totalContributed,,,) = fayhr.crowdfundTypes(1);
        assertEq(totalContributed, 20e18);
        assertEq(finalBalnceUser1, initialBalanceUser1);
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By ClaimEth Function:", gasUsed);
    }

    function testDelegateEth() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 10e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        uint256 slot = 10e18; // Example slot value, adjust as needed
        uint256 slotUnit = 1; // Example slot unit, adjust as needed
        uint256 delegateAmount = slot * slotUnit;
        // Check initial ETH balance of the user and contract
        uint256 initialUserBalance = user1.balance;
        uint256 initialContractBalance = address(fayhr).balance;

        // Delegate ETH to the crowdfund
        fayhr.delegateEth{value: delegateAmount}(1, slotUnit);

        // Check the final ETH balance of the user and contract
        uint256 finalUserBalance = user1.balance;
        uint256 finalContractBalance = address(fayhr).balance;

        // Verify the ETH amount sent and balances
        assertEq(finalUserBalance, initialUserBalance - delegateAmount);
        assertEq(finalContractBalance, initialContractBalance + delegateAmount);

        // Verify the contributions and total contributed
        (,,,,,,,,, uint256 totalContributed,,,) = fayhr.crowdfundTypes(1);
        uint256 userContribution = fayhr.contributions(1, user1);

        assertEq(totalContributed, delegateAmount);
        assertEq(userContribution, delegateAmount);
    }

    function testClaimEthWhenCancelCalled() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 10e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        uint256 slot = 10e18; // Example slot value, adjust as needed
        uint256 slotUnit = 1; // Example slot unit, adjust as needed
        uint256 delegateAmount = slot * slotUnit;

        // Delegate ETH with the exact amount
        fayhr.delegateEth{value: delegateAmount}(1, slotUnit);
        uint256 initialBalance = user1.balance;

        vm.warp(block.timestamp + 20);

        vm.prank(seperateAdmin);
        fayhr.cancelCrowdfund(1);
        uint256 gasBefore = gasleft();

        vm.prank(user1);
        fayhr.claimEth(1);
        uint256 gasAfter = gasleft();

        uint256 user1Balance = user1.balance;
        assertEq(user1Balance, initialBalance + 10e18); // User should get their ETH back
        (,,,,,,,,, uint256 totalContributed,,,) = fayhr.crowdfundTypes(1);
        assertEq(totalContributed, 10e18);
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By Claim Function after Cancelled:", gasUsed);
    }

    function testCancelCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e18, 0, 10, 100e18, 1000e18, false);
        uint256 gasBefore = gasleft();

        vm.prank(seperateAdmin);
        fayhr.cancelCrowdfund(1);
        uint256 gasAfter = gasleft();

        (,,,,,,,,,, Fayhr.Authorization authorization,,) = fayhr.crowdfundTypes(1);
        assertEq(uint256(authorization), uint256(Fayhr.Authorization.cancel));
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By CancelCrowdfund:", gasUsed);
    }

    function testRestartCanceledCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e18, 0, 10, 100e18, 1000e18, false);

        vm.prank(seperateAdmin);
        fayhr.cancelCrowdfund(1);
        uint256 gasBefore = gasleft();

        vm.prank(seperateAdmin);
        fayhr.restartCanceledCrowdfund(1, 1e18, 0, 20, 200e18, 2000e18, false);
        uint256 gasAfter = gasleft();

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
        assertEq(slot, 1e18);
        assertTrue(startTime <= block.timestamp);
        assertTrue(endTime > block.timestamp);
        assertEq(softCap, 200e18);
        assertEq(hardCap, 2000e18);
        assertFalse(closed);
        assertEq(uint256(authorization), uint256(Fayhr.Authorization.active));
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By RestartCrowdfund Function:", gasUsed);
    }

    function testWithdrawCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        uint256 slot = 1e18; // Example slot value, adjust as needed
        uint256 slotUnit = 1000; // Example slot unit, adjust as needed
        uint256 delegateAmount = slot * slotUnit;

        // Delegate ETH with the exact amount
        fayhr.delegateEth{value: delegateAmount}(1, slotUnit);

        uint256 gasBefore = gasleft();

        vm.warp(block.timestamp + 20);

        vm.prank(seperateAdmin);
        fayhr.withdrawCrowdfund(1);
        uint256 gasAfter = gasleft();

        uint256 adminBalance = seperateAdmin.balance;
        assertEq(adminBalance, 1000e18); // Adjust this check based on the expected behavior of the withdraw function
        (,,,,,,,,, uint256 totalContributed,,,) = fayhr.crowdfundTypes(1);
        assertEq(totalContributed, 0);
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By Withdraw Function:", gasUsed);
    }

    function testRestartCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        uint256 gasBefore = gasleft();

        vm.prank(seperateAdmin);
        fayhr.restartCrowdfund(1, 1e18, 0, 20, 200e18, 2000e18, false);
        uint256 gasAfter = gasleft();

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
            ,
            bool closed,
            bool pollClosed
        ) = fayhr.crowdfundTypes(1);
        assertEq(slot, 1e18);
        assertTrue(startTime <= block.timestamp);
        assertTrue(endTime > block.timestamp);
        assertEq(softCap, 200e18);
        assertEq(hardCap, 2000e18);
        assertFalse(closed);
        assertTrue(pollClosed);
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By RestartCrowdfund Function:", gasUsed);
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
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        // Calculate the delegate amount based on slot and _slotUnit
        uint256 slot = 1e18; // Example slot value, adjust as needed
        uint256 slotUnit = 2; // Example slot unit, adjust as needed
        uint256 delegateAmount = slot * slotUnit;

        // Delegate ETH with the exact amount
        vm.prank(user1);
        fayhr.delegateEth{value: delegateAmount}(1, slotUnit);
        uint256 adminInitialBalance = seperateAdmin.balance;

        uint256 gasBefore = gasleft();

        // Delete the contract
        vm.prank(seperateAdmin);
        fayhr.deleteContract();
        uint256 adminFinalBalance = seperateAdmin.balance;
        uint256 gasAfter = gasleft();

        // Ensure the contract is inactive
        assertTrue(!fayhr.isActive());
        assertEq(adminFinalBalance, adminInitialBalance + delegateAmount);

        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By Delete Function:", gasUsed);
    }

    function testGetAdmin() public {
        vm.prank(user1);
        address returnedAdmin = fayhr.getAdmin();
        assertEq(returnedAdmin, seperateAdmin, "Admin address should match");
    }

    function testGetCrowdfund() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user2);
        Fayhr.CrowdfundType memory crowdfund = fayhr.getCrowdfund(1);
        assertEq(crowdfund.id, 1, "Initial crowdfund ID should be 1");
    }

    function testGetContribution() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        uint256 slot = 1e18; // Example slot value, adjust as needed
        uint256 slotUnit = 1000; // Example slot unit, adjust as needed
        uint256 delegateAmount = slot * slotUnit;

        // Delegate ETH with the exact amount
        fayhr.delegateEth{value: delegateAmount}(1, slotUnit);
        // fayhr.delegateEth(1, 1000);
        vm.prank(user1);
        uint256 contribution = fayhr.getContribution(1, user1);
        assertEq(contribution, 1000e18, "Initial contribution should be 1000e18");
    }

    function testHasUserVoted() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user2);
        fayhr.vote(1, true);
        vm.prank(user2);
        bool voted = fayhr.hasUserVoted(1, user2);
        assertTrue(voted, "User should not have voted initially");
    }
}

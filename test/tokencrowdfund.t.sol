// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/tokencrowdfund.sol";
import "../src/TestToken.sol";

contract FahyrTest is Test {
    Fayhr fayhr; // Corrected variable name
    TestToken token;
    address public admin;
    address public user1;
    address public user2;
    address public seperateAdmin;
    address public fayhrAddress;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        seperateAdmin = address(0x3);

        token = new TestToken();
        fayhr = new Fayhr(seperateAdmin, address(token)); // Corrected variable name
        fayhrAddress = address(fayhr);

        // Distribute tokens to users
        token.transfer(user1, 10000000e18);
        token.transfer(user2, 10000000e18);
        vm.deal(user1, 100 ether);
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
        (,,,,,,,,,,,, bool initialpollClosed) = fayhr.crowdfundTypes(1);
        uint256 gasBefore = gasleft();

        vm.prank(user1);
        fayhr.vote(1, true);
        uint256 gasAfter = gasleft();

        (,,, uint256 availableYesVotes,,,,,,,, bool closed, bool pollClosed) = fayhr.crowdfundTypes(1);
        assertEq(availableYesVotes, 1);
        assertFalse(initialpollClosed);
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

    function testApproveToken() public {
        vm.prank(user1);
        // fayhr.approveToken(address(fayhr), 1000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);
        token.approve(address(fayhr), 1000000e18);
        // uint256 allowance = token.allowance(address(fayhr), address(fayhr));
        uint256 allowance = token.allowance(user1, address(fayhr));
        assertEq(allowance, 1000000e18);
    }

    function testDeapproveToken() public {
        vm.prank(user1);
        token.approve(fayhrAddress, 1000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);
        uint256 gasBefore = gasleft();
        vm.prank(user1);
        token.approve(fayhrAddress, 0);
        // fayhr.approveToken(fayhrAddress, 0);
        uint256 gasAfter = gasleft();
        uint256 allowance = token.allowance(user1, address(fayhr));
        assertEq(allowance, 0, "allowance should be zero");
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By Deapprove Function:", gasUsed);
    }

    function testDelegateToken() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 10e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        token.approve(fayhrAddress, 1000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);
        uint256 gasBefore = gasleft();
        // Logging the initial state of totalContributed before delegation
        // (,,,,,,,,, uint256 initialTotalContributed,,,) = fayhr.crowdfundTypes(1);
        // console.log("Initial Total Contributed: ", initialTotalContributed);

        vm.prank(user1);
        fayhr.delegateToken(1, 1);
        uint256 gasAfter = gasleft();
        uint256 contractBalance = token.balanceOf(address(fayhr));

        // Logging the final state of totalContributed after delegation
        (,,,,,,,,, uint256 finalTotalContributed,,,) = fayhr.crowdfundTypes(1);
        console.log("Final Total Contributed: ", finalTotalContributed);

        assertEq(finalTotalContributed, 10e18);
        assertEq(contractBalance, 10e18);
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By DelegateToken Function:", gasUsed);
    }

    function testClaimToken() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 10e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        token.approve(fayhrAddress, 1000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);
        vm.prank(user1);
        fayhr.delegateToken(1, 1);
        uint256 gasBefore = gasleft();

        vm.warp(block.timestamp + 20);

        vm.prank(user1);
        fayhr.claimToken(1);
        uint256 gasAfter = gasleft();

        uint256 user1Balance = token.balanceOf(user1);
        assertEq(user1Balance, 10000000e18);
        (,,,,,,,,, uint256 totalContributed,,,) = fayhr.crowdfundTypes(1);
        assertEq(totalContributed, 10e18);
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By ClaimToken Function:", gasUsed);
    }

    function testClaimTokenWhenCancelCalled() public {
        vm.prank(seperateAdmin);
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 10e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        token.approve(fayhrAddress, 1000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);
        vm.prank(user1);
        fayhr.delegateToken(1, 1);
        vm.warp(block.timestamp + 20);

        vm.prank(seperateAdmin);
        fayhr.cancelCrowdfund(1);
        uint256 gasBefore = gasleft();

        vm.prank(user1);
        fayhr.claimToken(1);
        uint256 gasAfter = gasleft();

        uint256 user1Balance = token.balanceOf(user1);
        assertEq(user1Balance, 10000000e18);
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
        token.approve(fayhrAddress, 1000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);
        vm.prank(user1);
        fayhr.delegateToken(1, 1000);
        uint256 gasBefore = gasleft();

        vm.warp(block.timestamp + 20);

        vm.prank(seperateAdmin);
        fayhr.withdrawCrowdfund(1);
        uint256 gasAfter = gasleft();

        // Check balances after withdrawal
        uint256 adminBalance = token.balanceOf(seperateAdmin);
        uint256 user1Balance = token.balanceOf(user1);
        uint256 testContractBalance = token.balanceOf(address(this));

        // Ensure the tokens have been withdrawn correctly
        assertEq(adminBalance, 1000e18); // separateAdmin gets 1000 tokens
        assertEq(user1Balance, 9999000e18); // user1 balance after delegation

        // Ensure the test contract balance is correctly updated
        assertEq(testContractBalance, 999980000000e18); // initial 1 million minus tokens sent to user1 and user2
        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas Used By WithdrawCrowdfund Function:", gasUsed);
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
        fayhr.createPoll(1, "Poll1", 1, false);
        vm.prank(user1);
        fayhr.vote(1, true);
        vm.prank(seperateAdmin);
        fayhr.startCrowdfund(1, 1e18, 0, 10, 100e18, 1000e18, false);

        vm.warp(block.timestamp + 2);

        vm.prank(user1);
        token.approve(fayhrAddress, 1000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);
        vm.prank(user1);
        fayhr.delegateToken(1, 1);
        uint256 gasBefore = gasleft();

        // Delete the contract
        uint256 contractTokenBalanceBefore = token.balanceOf(address(fayhr));
        uint256 adminBalanceBefore = token.balanceOf(seperateAdmin);

        vm.prank(seperateAdmin);
        fayhr.deleteContract();
        uint256 gasAfter = gasleft();

        uint256 contractTokenBalanceAfter = token.balanceOf(address(fayhr));
        uint256 adminBalanceAfter = token.balanceOf(seperateAdmin);

        // Ensure the contract is inactive
        assertTrue(!fayhr.isActive());

        // Ensure the contract token balance is transferred to the admin
        assertEq(contractTokenBalanceAfter, 0);
        assertEq(adminBalanceAfter, adminBalanceBefore + contractTokenBalanceBefore);
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
        token.approve(fayhrAddress, 1000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);
        vm.prank(user1);
        fayhr.delegateToken(1, 1000);
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

    function testReceiveToken() public {
        vm.prank(user1);
        token.approve(fayhrAddress, 1000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);

        vm.prank(user1);
        fayhr.receiveToken(1000e18);
        // uint256 tokenAllowance = token.allowance(user1, address(fayhr));
        uint256 contractBalance = token.balanceOf(address(fayhr));
        // assertEq(tokenAllowance, 10000000e18);
        assertEq(contractBalance, 1000e18);
    }

    function testTokenFaucet() public {
        vm.prank(user1);
        token.approve(fayhrAddress, 2000000e18);
        // fayhr.approveToken(fayhrAddress, 1000000e18);

        vm.prank(user1);
        fayhr.receiveToken(2000000e18);
        uint256 initailBalance = token.balanceOf(address(fayhr));
        // uint256 initialAllowance = token.allowance(user1, address(fayhr));

        vm.prank(user1);
        fayhr.tokenFaucet();
        // uint256 tokenAllowance = token.allowance(user1, address(fayhr));
        uint256 contractBalance = token.balanceOf(address(fayhr));
        assertEq(initailBalance, 2000000e18);
        // assertEq(initialAllowance, 10000000e18);
        // assertEq(tokenAllowance, 9000000e18);
        assertEq(contractBalance, 1000000e18);
    }
}

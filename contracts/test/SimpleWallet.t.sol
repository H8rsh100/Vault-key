// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";

/// @title  SimpleWalletTest
/// @notice Foundry unit tests for the Day 1 SimpleWallet contract.
///         Covers: owner access control, ETH send, deposit via receive(), balance checks.
contract SimpleWalletTest is Test {
    // ──────────────────────────────────────────────────────────────────────────
    // Actors & contract under test
    // ──────────────────────────────────────────────────────────────────────────

    SimpleWallet internal wallet;

    address internal owner     = makeAddr("owner");
    address internal notOwner  = makeAddr("notOwner");
    address internal recipient = makeAddr("recipient");

    uint256 internal constant INITIAL_BALANCE = 1 ether;

    // ──────────────────────────────────────────────────────────────────────────
    // Setup
    // ──────────────────────────────────────────────────────────────────────────

    function setUp() public {
        wallet = new SimpleWallet(owner);
        // Seed the wallet with 1 ETH so send tests have funds to work with
        vm.deal(address(wallet), INITIAL_BALANCE);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Constructor
    // ──────────────────────────────────────────────────────────────────────────

    function test_OwnerSetCorrectly() public view {
        assertEq(wallet.owner(), owner, "owner mismatch");
    }

    // ──────────────────────────────────────────────────────────────────────────
    // send()
    // ──────────────────────────────────────────────────────────────────────────

    function test_OwnerCanSend() public {
        vm.prank(owner);
        wallet.send(payable(recipient), 0.5 ether);

        assertEq(recipient.balance, 0.5 ether,          "recipient did not receive ETH");
        assertEq(wallet.getBalance(), 0.5 ether,        "wallet balance not reduced");
    }

    function test_NonOwnerCannotSend() public {
        vm.prank(notOwner);
        vm.expectRevert(SimpleWallet.NotOwner.selector);
        wallet.send(payable(recipient), 0.1 ether);
    }

    function test_SendRevertsOnInsufficientBalance() public {
        vm.prank(owner);
        vm.expectRevert(SimpleWallet.InsufficientBalance.selector);
        // Try to send more than the 1 ETH we seeded
        wallet.send(payable(recipient), 2 ether);
    }

    function test_SendEmitsWithdrawnEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(wallet));
        emit SimpleWallet.Withdrawn(recipient, 0.3 ether);
        wallet.send(payable(recipient), 0.3 ether);
    }

    function test_SendEntireBalance() public {
        vm.prank(owner);
        wallet.send(payable(recipient), INITIAL_BALANCE);

        assertEq(wallet.getBalance(), 0,               "wallet should be empty");
        assertEq(recipient.balance, INITIAL_BALANCE,   "recipient should have full balance");
    }

    // ──────────────────────────────────────────────────────────────────────────
    // receive() — ETH deposit
    // ──────────────────────────────────────────────────────────────────────────

    function test_CanReceiveETH() public {
        vm.deal(notOwner, 2 ether);
        vm.prank(notOwner);
        // Plain ETH transfer triggers receive()
        (bool ok,) = address(wallet).call{value: 1 ether}("");
        assertTrue(ok, "ETH transfer rejected");
        assertEq(wallet.getBalance(), INITIAL_BALANCE + 1 ether, "balance did not increase");
    }

    function test_ReceiveEmitsDepositedEvent() public {
        vm.deal(notOwner, 1 ether);
        vm.expectEmit(true, false, false, true, address(wallet));
        emit SimpleWallet.Deposited(notOwner, 0.5 ether);
        vm.prank(notOwner);
        (bool ok,) = address(wallet).call{value: 0.5 ether}("");
        assertTrue(ok);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // getBalance()
    // ──────────────────────────────────────────────────────────────────────────

    function test_GetBalance_ReturnsCorrectValue() public view {
        assertEq(wallet.getBalance(), INITIAL_BALANCE, "getBalance mismatch");
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Fuzz — send arbitrary valid amounts
    // ──────────────────────────────────────────────────────────────────────────

    /// @notice Fuzz: owner can always send any amount ≤ wallet balance.
    function testFuzz_OwnerCanSendValidAmount(uint256 amount) public {
        // Bound amount to [0, INITIAL_BALANCE]
        amount = bound(amount, 0, INITIAL_BALANCE);

        vm.prank(owner);
        wallet.send(payable(recipient), amount);

        assertEq(recipient.balance, amount,                 "recipient balance wrong");
        assertEq(wallet.getBalance(), INITIAL_BALANCE - amount, "wallet balance wrong");
    }
}

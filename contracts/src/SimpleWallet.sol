// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title  SimpleWallet
/// @notice Day 1 warm-up contract — a plain ETH wallet with no ERC-4337 complexity.
///         Holds ETH and lets the owner send funds.
///         This is intentionally simple so we can focus on Foundry workflows and
///         Base Sepolia deploys before layering in account abstraction on Days 3-4.
/// @dev    Production smart-account logic lives in VaultKey.sol (Days 3-4).
contract SimpleWallet {
    // ──────────────────────────────────────────────────────────────────────────
    // State
    // ──────────────────────────────────────────────────────────────────────────

    /// @notice The address that owns this wallet and may initiate sends.
    address public owner;

    // ──────────────────────────────────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────────────────────────────────

    /// @notice Emitted whenever ETH is deposited into this wallet.
    /// @param sender The address that sent ETH.
    /// @param amount The amount of ETH deposited (in wei).
    event Deposited(address indexed sender, uint256 amount);

    /// @notice Emitted whenever the owner withdraws ETH.
    /// @param to     The recipient address.
    /// @param amount The amount of ETH sent (in wei).
    event Withdrawn(address indexed to, uint256 amount);

    // ──────────────────────────────────────────────────────────────────────────
    // Errors
    // ──────────────────────────────────────────────────────────────────────────

    /// @notice Reverts when a non-owner calls a restricted function.
    error NotOwner();

    /// @notice Reverts when the requested send amount exceeds the wallet balance.
    error InsufficientBalance();

    /// @notice Reverts when the low-level ETH transfer fails.
    error TransferFailed();

    // ──────────────────────────────────────────────────────────────────────────
    // Modifiers
    // ──────────────────────────────────────────────────────────────────────────

    /// @dev Restricts function access to the wallet owner.
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Constructor
    // ──────────────────────────────────────────────────────────────────────────

    /// @notice Deploys a new SimpleWallet and sets the initial owner.
    /// @param _owner The address that will control this wallet.
    constructor(address _owner) {
        owner = _owner;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Receive
    // ──────────────────────────────────────────────────────────────────────────

    /// @notice Accepts plain ETH transfers (e.g. direct sends, faucet drops).
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // External functions
    // ──────────────────────────────────────────────────────────────────────────

    /// @notice Sends ETH from the wallet to a recipient address.
    /// @dev    Only the owner can call this. Uses a low-level call so any
    ///         gas stipend issues surface as a TransferFailed revert rather
    ///         than a silent failure.
    /// @param _to     The recipient of the ETH.
    /// @param _amount Amount to send in wei.
    function send(address payable _to, uint256 _amount) external onlyOwner {
        if (address(this).balance < _amount) revert InsufficientBalance();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = _to.call{value: _amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(_to, _amount);
    }

    /// @notice Returns the current ETH balance of this wallet.
    /// @return balance The balance in wei.
    function getBalance() external view returns (uint256 balance) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";

/// @notice Deploys SimpleWallet to Base Sepolia (Day 1 deploy).
///
/// Usage (from WSL, inside contracts/):
///   forge script script/Deploy.s.sol \
///     --rpc-url $BASE_SEPOLIA_RPC_URL \
///     --private-key $PRIVATE_KEY \
///     --broadcast \
///     --verify \
///     --etherscan-api-key $BASESCAN_API_KEY \
///     -vvvv
///
/// After deploy, save the printed address in docs/deployed-addresses.md.
contract DeploySimpleWallet is Script {
    function run() external {
        // Read private key from env — never hardcode secrets
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address :", deployer);
        console.log("Deployer balance  :", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        SimpleWallet wallet = new SimpleWallet(deployer);

        vm.stopBroadcast();

        console.log("--------------------------------------------------");
        console.log("SimpleWallet deployed at :", address(wallet));
        console.log("Owner                    :", wallet.owner());
        console.log("--------------------------------------------------");
        console.log("Save this address in docs/deployed-addresses.md");
    }
}

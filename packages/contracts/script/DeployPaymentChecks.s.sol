// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {PaymentChecksLegacy} from "../src/PaymentChecksLegacy.sol";

/// @notice Deploys the legacy PaymentChecks contract (escrow held in the contract).
/// @dev This script is legacy-only. Use DeployAndSmokePCHK6551 for the ERC-6551 build.
/// Expects PRIVATE_KEY to be set in the environment.
contract DeployPaymentChecks is Script {
    uint256 internal constant AMOY_CHAIN_ID = 80002;

    string internal constant NAME = "Payment Checks (Legacy)";
    string internal constant SYMBOL = "pCHECK";
    string internal constant BASE_URI = "https://checks.xyz/metadata/payment-checks/";

    event Deployed(address indexed paymentChecksLegacy);

    function run() external returns (PaymentChecksLegacy checks) {
        require(block.chainid == AMOY_CHAIN_ID, "Wrong chain: expected Polygon Amoy (80002)");

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerKey);

        checks = new PaymentChecksLegacy(NAME, SYMBOL, BASE_URI);

        vm.stopBroadcast();

        console2.log("PaymentChecksLegacy deployed at:", address(checks));
        emit Deployed(address(checks));
    }
}

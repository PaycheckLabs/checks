// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { PaymentChecks } from "../src/PaymentChecks.sol";

/// @notice Deploys the PaymentChecks contract.
/// @dev Expects PRIVATE_KEY to be set in the environment.
/// Example:
/// forge script script/DeployPaymentChecks.s.sol:DeployPaymentChecks --rpc-url $AMOY_RPC_URL --broadcast
contract DeployPaymentChecks is Script {
    uint256 internal constant AMOY_CHAIN_ID = 80002;

    string internal constant NAME = "Payment Checks";
    string internal constant SYMBOL = "pCHECK";
    string internal constant BASE_URI = "https://checks.xyz/metadata/payment-checks/";

    event Deployed(address indexed paymentChecks);

    function run() external returns (PaymentChecks checks) {
        require(block.chainid == AMOY_CHAIN_ID, "Wrong chain: expected Polygon Amoy (80002)");

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerKey);
        checks = new PaymentChecks(NAME, SYMBOL, BASE_URI);
        vm.stopBroadcast();

        console2.log("PaymentChecks deployed at:", address(checks));
        emit Deployed(address(checks));
    }
}

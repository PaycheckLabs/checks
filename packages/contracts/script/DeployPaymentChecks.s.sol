// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { PaymentChecks } from "../src/PaymentChecks.sol";

contract DeployPaymentChecks is Script {
    event Deployed(address indexed paymentChecks);

    function run() external returns (PaymentChecks checks) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        checks = new PaymentChecks(
            "Payment Checks",
            "pCHECK",
            "https://checks.xyz/metadata/payment-checks/"
        );

        vm.stopBroadcast();

        emit Deployed(address(checks));
    }
}

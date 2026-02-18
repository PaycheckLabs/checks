// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {PaymentChecks} from "../src/PaymentChecks.sol";

interface Vm {
    function envUint(string calldata name) external returns (uint256);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

contract DeployPaymentChecks {
    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

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

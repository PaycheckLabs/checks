// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { PaymentChecks } from "../src/PaymentChecks.sol";
import { MockERC20 } from "../test/MockERC20.sol";

contract DeployAndSmoke is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // 1) Deploy contracts
        PaymentChecks checks = new PaymentChecks(
            "Payment Checks",
            "pCHECK",
            "https://checks.xyz/metadata/payment-checks/"
        );

        // 2) Deploy a test token and fund deployer
        MockERC20 token = new MockERC20("Test USD", "tUSD", 6);
        token.mint(deployer, 1_000_000e6);

        // 3) Approve and mint a Payment Check
        uint256 amount = 100e6; // 100 tUSD
        token.approve(address(checks), amount);

        address recipient = deployer; // smoke to self
        uint64 claimableAt = uint64(block.timestamp + 1);

        bytes32 referenceId = keccak256(
            abi.encodePacked("smoke:", block.chainid, address(token), recipient, amount)
        );

        uint256 checkId = checks.mintPaymentCheck(
            recipient,
            address(token),
            amount,
            claimableAt,
            referenceId
        );

        vm.stopBroadcast();

        // 4) Minimal logs to confirm outputs
        console2.log("PaymentChecks:", address(checks));
        console2.log("MockERC20:", address(token));
        console2.log("deployer:", deployer);
        console2.log("checkId:", checkId);
    }
}

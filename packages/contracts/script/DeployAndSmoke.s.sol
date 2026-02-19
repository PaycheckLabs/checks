// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {PaymentChecks} from "../src/PaymentChecks.sol";
import {MockERC20} from "../test/MockERC20.sol";

/// @notice Deploy PaymentChecks + a MockERC20, then mint and redeem a check on Polygon Amoy.
contract DeployAndSmoke is Script {
    uint256 internal constant AMOY_CHAIN_ID = 80002;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        require(block.chainid == AMOY_CHAIN_ID, "DeployAndSmoke: wrong chain (expected Amoy)");

        vm.startBroadcast(deployerKey);

        // 1) Deploy protocol + mock token
        PaymentChecks checks = new PaymentChecks(
            "Payment Checks",
            "PCHK",
            "https://checks.example/api/token/"
        );

        MockERC20 token = new MockERC20("Mock USD", "mUSD", 6);

        // 2) Fund deployer with mock tokens and approve the checks contract
        uint256 amount = 100e6; // 100.000000 (6 decimals)
        token.mint(deployer, amount);
        token.approve(address(checks), amount);

        // 3) Mint a payment check
        // IMPORTANT:
        // - claimableAt == 0 tells PaymentChecks to set claimableAt to "now" at mint time.
        // - This avoids InvalidClaimableAt reverts due to block timestamp drift between mined txs.
        uint64 claimableAt = 0;

        bytes32 referenceId = keccak256(
            abi.encodePacked(
                "amoy-smoke",
                block.chainid,
                deployer,
                block.timestamp,
                block.number
            )
        );

        uint256 checkId = checks.mintPaymentCheck(
            deployer,         // recipient (also owner of the NFT)
            address(token),   // token
            amount,           // amount
            claimableAt,      // 0 => now
            referenceId       // unique per run
        );

        // 4) Redeem immediately (should succeed because claimableAt is "now")
        checks.redeemPaymentCheck(checkId);

        // Logs (helpful when running locally with -vvv)
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("PaymentChecks:", address(checks));
        console2.log("MockERC20:", address(token));
        console2.log("checkId:", checkId);
        console2.log("Deployer token balance:", token.balanceOf(deployer));

        vm.stopBroadcast();
    }
}

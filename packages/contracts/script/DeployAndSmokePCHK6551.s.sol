// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MockUSD} from "../src/MockUSD.sol";
import {ChecksAccount} from "../src/ChecksAccount.sol";
import {PaymentChecks} from "../src/PaymentChecks.sol";
import {IERC6551Account} from "../src/vendor/erc6551/IERC6551Account.sol";

contract DeployAndSmokePCHK6551 is Script {
    uint256 internal constant AMOY_CHAIN_ID = 80002;

    // Canonical ERC-6551 registry address
    address internal constant ERC6551_REGISTRY = 0x000000006551c19487814612e58FE06813775758;

    uint256 internal constant AMOUNT = 100e6; // 100.000000 (6 decimals)
    bytes32 internal constant SALT = bytes32(uint256(0));

    function run() external {
        require(block.chainid == AMOY_CHAIN_ID, "DeployAndSmokePCHK6551: wrong chain (expected Amoy)");

        uint256 issuerKey = vm.envUint("PRIVATE_KEY");
        address issuer = vm.addr(issuerKey);

        // Optional: if provided, mint to this wallet and redeem from it.
        uint256 holderKey = _readOptionalEnvUint("SECOND_PRIVATE_KEY");
        address holder = holderKey == 0 ? issuer : vm.addr(holderKey);

        vm.startBroadcast(issuerKey);

        // 1) Deploy TBA implementation + mUSD
        ChecksAccount accountImpl = new ChecksAccount();
        MockUSD musd = new MockUSD();

        // 2) Deploy PaymentChecks bound to ERC-6551 Registry
        PaymentChecks checks = new PaymentChecks(
            "Payment Checks (PCHK)",
            "PCHK",
            ERC6551_REGISTRY,
            address(accountImpl),
            SALT,
            address(musd)
        );

        // 3) Fund issuer with mUSD + approve
        musd.faucet(1_000_000e6);
        musd.approve(address(checks), type(uint256).max);

        bytes32 serial = bytes32("AMOY-DEMO-0001");
        bytes32 title = bytes32("Demo Payment");

        (uint256 checkId, address account) = checks.mintPaymentCheck(
            holder,
            AMOUNT,
            0, // instant claim
            serial,
            title,
            "Amoy MVP smoke mint"
        );

        vm.stopBroadcast();

        console2.log("=== Deployed / Minted (Amoy) ===");
        console2.log("Issuer:", issuer);
        console2.log("Holder:", holder);
        console2.log("ChecksAccount impl:", address(accountImpl));
        console2.log("mUSD:", address(musd));
        console2.log("PaymentChecks:", address(checks));
        console2.log("checkId:", checkId);
        console2.logBytes32(serial);
        console2.log("TBA account:", account);
        console2.log("TBA owner():", IERC6551Account(payable(account)).owner());
        console2.log("TBA mUSD balance:", musd.balanceOf(account));

        // 4) Redeem (from holder)
        if (holderKey != 0) vm.startBroadcast(holderKey);
        else vm.startBroadcast(issuerKey);

        checks.redeemPaymentCheck(checkId);

        vm.stopBroadcast();

        console2.log("Redeemed. Holder mUSD balance:", musd.balanceOf(holder));
        console2.log("TBA mUSD balance after redeem:", musd.balanceOf(account));
    }

    function _readOptionalEnvUint(string memory key) internal returns (uint256 v) {
        try vm.envUint(key) returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }
}

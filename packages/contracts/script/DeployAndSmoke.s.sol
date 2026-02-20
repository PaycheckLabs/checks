// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {PaymentChecks} from "../src/PaymentChecks.sol";
import {IPaymentChecks} from "../src/IPaymentChecks.sol";
import {MockERC20} from "../test/MockERC20.sol";

/// @notice Deploy PaymentChecks + a MockERC20, then run a small smoke suite on Polygon Amoy.
/// @dev Env:
/// - PRIVATE_KEY: required (issuer/deployer)
/// - SECOND_PRIVATE_KEY: optional but recommended (to redeem as a different holder)
contract DeployAndSmoke is Script {
    uint256 internal constant AMOY_CHAIN_ID = 80002;

    uint256 internal constant AMOUNT = 100e6; // 100.000000 (6 decimals)
    uint64 internal constant POSTDATED_SECONDS = 3600; // 1 hour

    function run() external {
        require(block.chainid == AMOY_CHAIN_ID, "DeployAndSmoke: wrong chain (expected Amoy)");

        uint256 issuerKey = vm.envUint("PRIVATE_KEY");
        address issuer = vm.addr(issuerKey);

        // Optional second actor for transfer-before-redeem.
        uint256 holderKey = _readOptionalEnvUint("SECOND_PRIVATE_KEY");
        address holder = holderKey == 0 ? address(0) : vm.addr(holderKey);

        // 1) Deploy protocol + mock token (issuer pays gas)
        vm.startBroadcast(issuerKey);
        PaymentChecks checks = new PaymentChecks("Payment Checks", "PCHK", "https://checks.example/api/token/");
        MockERC20 token = new MockERC20("Mock USD", "mUSD", 6);

        // Fund issuer for multiple checks and approve once.
        uint256 totalNeeded = AMOUNT * 3;
        token.mint(issuer, totalNeeded);
        token.approve(address(checks), type(uint256).max);
        vm.stopBroadcast();

        console2.log("Issuer:", issuer);
        console2.log("Holder (optional):", holder);
        console2.log("Chain ID:", block.chainid);
        console2.log("PaymentChecks:", address(checks));
        console2.log("MockERC20:", address(token));

        // Flow 1: immediate mint + redeem by issuer
        uint256 checkId1 = _mintInstant(checks, token, issuerKey, issuer, AMOUNT, _ref("instant-issuer", issuer));
        _redeem(checks, issuerKey, checkId1, "redeem issuer");

        // Flow 2: transfer-before-redeem (full coverage requires SECOND_PRIVATE_KEY for the redeem step)
        if (holder != address(0)) {
            uint256 checkId2 = _mintInstant(checks, token, issuerKey, issuer, AMOUNT, _ref("instant-transfer", issuer));
            _transfer(checks, issuerKey, issuer, holder, checkId2);

            if (holderKey != 0) {
                _redeem(checks, holderKey, checkId2, "redeem holder");
            } else {
                console2.log("SKIP: set SECOND_PRIVATE_KEY to redeem as a different holder");
            }
        } else {
            console2.log("SKIP: set SECOND_PRIVATE_KEY to test transfer-before-redeem");
        }

        // Flow 3: post-dated redeem should revert, then issuer voids, then redeem should still revert
        uint256 checkId3 = _mintPostdated(checks, token, issuerKey, issuer, AMOUNT, _ref("postdated-void", issuer));
        _expectNotClaimableYet(checks, issuerKey, checkId3, "postdated redeem (issuer) should revert");

        // Optional: show issuer can still void after transfer while post-dated
        if (holder != address(0)) {
            _transfer(checks, issuerKey, issuer, holder, checkId3);
            if (holderKey != 0) {
                _expectNotClaimableYet(checks, holderKey, checkId3, "postdated redeem (holder) should revert");
            }
        }

        _void(checks, issuerKey, checkId3);
        _expectCheckNotActive(checks, issuerKey, checkId3, "redeem after void should revert");

        // Post-condition: escrow should be empty after redeem + void
        require(token.balanceOf(address(checks)) == 0, "escrow should be empty after redeem/void");

        console2.log("Issuer token balance:", token.balanceOf(issuer));
        if (holderKey != 0) console2.log("Holder token balance:", token.balanceOf(holder));
    }

    function _mintInstant(
        PaymentChecks checks,
        MockERC20 token,
        uint256 issuerKey,
        address issuer,
        uint256 amount,
        bytes32 ref
    ) internal returns (uint256 checkId) {
        token; // silence unused warning in some toolchains
        vm.startBroadcast(issuerKey);
        // claimableAt = 0 => normalized to now in-contract
        checkId = checks.mintPaymentCheck(issuer, address(token), amount, 0, ref);
        vm.stopBroadcast();
        console2.log("Mint instant checkId:", checkId);
    }

    function _mintPostdated(
        PaymentChecks checks,
        MockERC20 token,
        uint256 issuerKey,
        address issuer,
        uint256 amount,
        bytes32 ref
    ) internal returns (uint256 checkId) {
        token; // silence unused warning in some toolchains
        uint64 claimableAt = uint64(block.timestamp + POSTDATED_SECONDS);
        vm.startBroadcast(issuerKey);
        checkId = checks.mintPaymentCheck(issuer, address(token), amount, claimableAt, ref);
        vm.stopBroadcast();
        console2.log("Mint postdated checkId:", checkId, "claimableAt:", claimableAt);
    }

    function _redeem(PaymentChecks checks, uint256 key, uint256 checkId, string memory label) internal {
        vm.startBroadcast(key);
        checks.redeemPaymentCheck(checkId);
        vm.stopBroadcast();
        console2.log("OK:", label, "checkId:", checkId);
    }

    function _transfer(PaymentChecks checks, uint256 key, address from, address to, uint256 checkId) internal {
        require(to != address(0), "transfer target is zero");
        vm.startBroadcast(key);
        checks.transferFrom(from, to, checkId);
        vm.stopBroadcast();
        console2.log("Transfer checkId:", checkId, "to:", to);
    }

    function _void(PaymentChecks checks, uint256 issuerKey, uint256 checkId) internal {
        vm.startBroadcast(issuerKey);
        checks.voidPaymentCheck(checkId);
        vm.stopBroadcast();
        console2.log("Void checkId:", checkId);
    }

    function _expectNotClaimableYet(PaymentChecks checks, uint256 key, uint256 checkId, string memory label) internal {
        vm.startBroadcast(key);
        try checks.redeemPaymentCheck(checkId) {
            vm.stopBroadcast();
            revert("expected NotClaimableYet");
        } catch (bytes memory reason) {
            vm.stopBroadcast();
            bytes4 sel = _selector(reason);
            require(sel == IPaymentChecks.NotClaimableYet.selector, "unexpected revert selector");
            console2.log("OK:", label);
        }
    }

    function _expectCheckNotActive(PaymentChecks checks, uint256 key, uint256 checkId, string memory label) internal {
        vm.startBroadcast(key);
        try checks.redeemPaymentCheck(checkId) {
            vm.stopBroadcast();
            revert("expected CheckNotActive");
        } catch (bytes memory reason) {
            vm.stopBroadcast();
            bytes4 sel = _selector(reason);
            require(sel == IPaymentChecks.CheckNotActive.selector, "unexpected revert selector");
            console2.log("OK:", label);
        }
    }

    function _selector(bytes memory revertData) internal pure returns (bytes4 sel) {
        if (revertData.length < 4) return bytes4(0);
        assembly {
            sel := mload(add(revertData, 0x20))
        }
    }

    function _readOptionalEnvUint(string memory key) internal returns (uint256 v) {
        try vm.envUint(key) returns (uint256 out) {
            v = out;
        } catch {
            v = 0;
        }
    }

    function _ref(string memory tag, address issuer) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(tag, block.chainid, issuer, block.timestamp, block.number));
    }
}

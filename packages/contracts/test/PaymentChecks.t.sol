// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {PaymentChecksLegacy} from "../src/PaymentChecksLegacy.sol";
import {IPaymentChecks} from "../src/IPaymentChecks.sol";
import {MockERC20} from "./MockERC20.sol";

contract PaymentChecksTest is Test {
    PaymentChecksLegacy internal checks;
    MockERC20 internal token;

    address internal issuer = address(0xA11CE);
    address internal recipient = address(0xB0B);
    address internal other = address(0xCAFE);

    uint256 internal constant AMOUNT = 100e6; // 100 (6 decimals)
    uint64 internal constant START_TS = 1_800_000_000;

    function setUp() public {
        vm.warp(START_TS);

        token = new MockERC20("Mock USD", "mUSD", 6);
        checks = new PaymentChecksLegacy("Checks Payment (Legacy)", "CHK-PAY", "ipfs://checks/");

        token.mint(issuer, AMOUNT * 10);
        vm.prank(issuer);
        token.approve(address(checks), type(uint256).max);
    }

    function testMintCreatesActiveCheck() public {
        bytes32 ref = keccak256("ref-1");

        vm.prank(issuer);
        uint256 checkId = checks.mintPaymentCheck(recipient, address(token), AMOUNT, 0, ref);

        IPaymentChecks.PaymentCheck memory pc = checks.getPaymentCheck(checkId);

        assertEq(pc.issuer, issuer);
        assertEq(pc.token, address(token));
        assertEq(pc.amount, AMOUNT);
        assertEq(pc.referenceId, ref);
        assertEq(uint256(pc.status), uint256(IPaymentChecks.Status.ACTIVE));

        assertEq(checks.ownerOf(checkId), recipient);
        assertEq(token.balanceOf(address(checks)), AMOUNT);
    }

    function testRedeemInstantPaysHolderAndMarksRedeemed() public {
        vm.prank(issuer);
        uint256 checkId = checks.mintPaymentCheck(recipient, address(token), AMOUNT, 0, bytes32(0));

        uint256 beforeBal = token.balanceOf(recipient);

        vm.prank(recipient);
        checks.redeemPaymentCheck(checkId);

        assertEq(token.balanceOf(recipient), beforeBal + AMOUNT);
        assertEq(token.balanceOf(address(checks)), 0);

        assertEq(uint256(checks.getPaymentCheckStatus(checkId)), uint256(IPaymentChecks.Status.REDEEMED));
    }

    function testRedeemBeforeClaimableAtReverts() public {
        uint64 claimableAt = uint64(START_TS + 1000);

        vm.prank(issuer);
        uint256 checkId = checks.mintPaymentCheck(recipient, address(token), AMOUNT, claimableAt, bytes32(0));

        vm.prank(recipient);
        vm.expectRevert(
            abi.encodeWithSelector(IPaymentChecks.NotClaimableYet.selector, claimableAt, uint64(START_TS))
        );
        checks.redeemPaymentCheck(checkId);
    }

    function testTransferThenRedeemPaysNewOwner() public {
        vm.prank(issuer);
        uint256 checkId = checks.mintPaymentCheck(recipient, address(token), AMOUNT, 0, bytes32(0));

        vm.prank(recipient);
        checks.transferFrom(recipient, other, checkId);

        uint256 beforeBal = token.balanceOf(other);

        vm.prank(other);
        checks.redeemPaymentCheck(checkId);

        assertEq(token.balanceOf(other), beforeBal + AMOUNT);
        assertEq(uint256(checks.getPaymentCheckStatus(checkId)), uint256(IPaymentChecks.Status.REDEEMED));
    }

    function testIssuerCanVoidBeforeClaimableAt() public {
        uint64 claimableAt = uint64(START_TS + 500);

        uint256 issuerBalBeforeMint = token.balanceOf(issuer);

        vm.prank(issuer);
        uint256 checkId = checks.mintPaymentCheck(recipient, address(token), AMOUNT, claimableAt, bytes32(0));

        assertEq(token.balanceOf(address(checks)), AMOUNT);

        vm.prank(issuer);
        checks.voidPaymentCheck(checkId);

        assertEq(uint256(checks.getPaymentCheckStatus(checkId)), uint256(IPaymentChecks.Status.VOID));
        assertEq(token.balanceOf(address(checks)), 0);
        assertEq(token.balanceOf(issuer), issuerBalBeforeMint);
    }
}

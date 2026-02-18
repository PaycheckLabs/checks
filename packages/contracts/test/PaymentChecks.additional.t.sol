// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {PaymentChecks} from "../src/PaymentChecks.sol";
import {IPaymentChecks} from "../src/IPaymentChecks.sol";
import {MockERC20} from "./MockERC20.sol";
import {SafeERC20} from "../src/vendor/openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {NoReturnERC20, FalseReturnERC20, ReentrantERC20} from "./helpers/EdgeCaseERC20s.sol";

contract PaymentChecksAdditionalTest is Test {
    PaymentChecks internal checks;
    MockERC20 internal token;

    address internal issuer = address(0xA11CE);
    address internal recipient = address(0xB0B);
    address internal otherHolder = address(0xCAFE);

    uint256 internal constant AMOUNT = 1_500e6; // 1500 (6 decimals)
    uint64 internal constant START_TS = 1_800_000_000;

    function setUp() public {
        vm.warp(START_TS);

        token = new MockERC20("Mock USDT", "mUSDT", 6);
        checks = new PaymentChecks("Checks Payment", "CHK-PAY", "ipfs://checks/");

        token.mint(issuer, AMOUNT * 10);

        vm.prank(issuer);
        token.approve(address(checks), type(uint256).max);
    }

    function testMintEmitsEventAndStoresReferenceId() public {
        bytes32 ref = keccak256("ref-123");

        vm.expectEmit(true, true, true, true);
        emit IPaymentChecks.PaymentCheckMinted(
            1,
            issuer,
            recipient,
            address(token),
            AMOUNT,
            uint64(START_TS),
            ref
        );

        vm.prank(issuer);
        uint256 checkId = checks.mintPaymentCheck(recipient, address(token), AMOUNT, 0, ref);

        assertEq(checkId, 1);
        IPaymentChecks.PaymentCheck memory pc = checks.getPaymentCheck(checkId);
        assertEq(pc.referenceId, ref);
    }

    function testTokenURIPrefixIsStable() public {
        vm.prank(issuer);
        uint256 checkId = checks.mintPaymentCheck(recipient, address(token), AMOUNT, 0, bytes32(0));

        string memory uri = checks.tokenURI(checkId);
        assertTrue(_startsWith(uri, "ipfs://checks/"));
    }

    function testVoidStillWorksAfterTransferBeforeClaimableAt() public {
        uint64 claimableAt = uint64(START_TS + 500);

        vm.prank(issuer);
        uint256 checkId = checks.mintPaymentCheck(recipient, address(token), AMOUNT, claimableAt, bytes32(0));

        // transfer NFT to someone else
        vm.prank(recipient);
        checks.transferFrom(recipient, otherHolder, checkId);
        assertEq(checks.ownerOf(checkId), otherHolder);

        // issuer can still void while post-dated
        vm.prank(issuer);
        checks.voidPaymentCheck(checkId);

        assertEq(token.balanceOf(address(checks)), 0);
        assertEq(checks.ownerOf(checkId), otherHolder);

        // holder cannot redeem even after claimableAt
        vm.warp(claimableAt + 1);
        vm.prank(otherHolder);
        vm.expectRevert(
            abi.encodeWithSelector(IPaymentChecks.CheckNotActive.selector, checkId, IPaymentChecks.Status.VOID)
        );
        checks.redeemPaymentCheck(checkId);
    }

    function testNoReturnTokenIsSupportedBySafeERC20() public {
        NoReturnERC20 t = new NoReturnERC20(6);
        t.mint(issuer, AMOUNT * 10);

        vm.prank(issuer);
        t.approve(address(checks), type(uint256).max);

        vm.prank(issuer);
        uint256 checkId = checks.mintPaymentCheck(recipient, address(t), AMOUNT, 0, bytes32(0));

        vm.prank(recipient);
        checks.redeemPaymentCheck(checkId);
    }

    function testFalseReturnTokenRevertsSafeERC20FailedOperation() public {
        FalseReturnERC20 t = new FalseReturnERC20(6);
        t.mint(issuer, AMOUNT * 10);

        vm.prank(issuer);
        t.approve(address(checks), type(uint256).max);

        vm.prank(issuer);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(t)));
        checks.mintPaymentCheck(recipient, address(t), AMOUNT, 0, bytes32(0));
    }

    function testReentrancyDuringTransferFromIsBlocked() public {
        ReentrantERC20 t = new ReentrantERC20(6);
        t.mint(issuer, AMOUNT * 10);

        t.setChecks(address(checks));

        vm.prank(issuer);
        t.approve(address(checks), type(uint256).max);

        vm.prank(issuer);
        vm.expectRevert(bytes("ReentrancyGuard: reentrant call"));
        checks.mintPaymentCheck(recipient, address(t), AMOUNT, 0, bytes32(0));
    }

    function _startsWith(string memory s, string memory prefix) internal pure returns (bool) {
        bytes memory a = bytes(s);
        bytes memory b = bytes(prefix);
        if (b.length > a.length) return false;
        for (uint256 i = 0; i < b.length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }
}

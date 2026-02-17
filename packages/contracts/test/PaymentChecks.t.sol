// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {PaymentChecks} from "../src/PaymentChecks.sol";
import {IPaymentChecks} from "../src/IPaymentChecks.sol";
import {MockERC20} from "./MockERC20.sol";

interface Vm {
    function warp(uint256) external;

    function prank(address) external;
    function startPrank(address) external;
    function stopPrank() external;

    function expectRevert(bytes4) external;
    function expectRevert(bytes calldata) external;
}

contract PaymentChecksTest {
    // Foundry cheatcode address.
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    PaymentChecks internal checks;
    MockERC20 internal token;

    address internal issuer = address(0xA11CE);
    address internal recipient = address(0xB0B);
    address internal otherHolder = address(0xCAFE);

    uint256 internal constant AMOUNT = 1_500e6; // 1500 USDT-style (6 decimals)
    uint64 internal constant START_TS = 1_800_000_000; // stable test timestamp

    function setUp() public {
        vm.warp(START_TS);

        token = new MockERC20("Mock USDT", "mUSDT", 6);
        checks = new PaymentChecks("Checks Payment", "CHK-PAY", "ipfs://checks/");

        // Fund issuer with collateral.
        token.mint(issuer, AMOUNT * 10);
    }

    // -------- helpers --------

    function _approveFromIssuer(uint256 amount) internal {
        vm.startPrank(issuer);
        token.approve(address(checks), amount);
        vm.stopPrank();
    }

    function _mintTo(address initialHolder, uint64 claimableAt) internal returns (uint256 checkId) {
        _approveFromIssuer(AMOUNT);

        vm.startPrank(issuer);
        checkId = checks.mintPaymentCheck(initialHolder, address(token), AMOUNT, claimableAt, bytes32(0));
        vm.stopPrank();
    }

    function assertEq(uint256 a, uint256 b, string memory msg_) internal pure {
        require(a == b, msg_);
    }

    function assertEq(address a, address b, string memory msg_) internal pure {
        require(a == b, msg_);
    }

    function assertTrue(bool v, string memory msg_) internal pure {
        require(v, msg_);
    }

    // -------- tests --------

    function testMintInstantClaimAndRedeem() public {
        uint256 issuerBalBefore = token.balanceOf(issuer);

        uint256 checkId = _mintTo(recipient, 0);

        // Escrowed in contract.
        assertEq(token.balanceOf(address(checks)), AMOUNT, "escrow not held");
        assertEq(checks.ownerOf(checkId), recipient, "nft not owned by recipient");

        vm.prank(recipient);
        checks.redeemPaymentCheck(checkId);

        // Funds to recipient, escrow cleared.
        assertEq(token.balanceOf(recipient), AMOUNT, "recipient did not receive funds");
        assertEq(token.balanceOf(address(checks)), 0, "escrow not cleared");

        // Issuer decreased by amount.
        assertEq(token.balanceOf(issuer), issuerBalBefore - AMOUNT, "issuer balance mismatch");

        // Status is REDEEMED.
        IPaymentChecks.Status st = checks.getPaymentCheckStatus(checkId);
        assertTrue(st == IPaymentChecks.Status.REDEEMED, "status not redeemed");
    }

    function testPostDatedCannotRedeemBeforeClaimableAt() public {
        uint64 claimableAt = uint64(START_TS + 100);
        uint256 checkId = _mintTo(recipient, claimableAt);

        vm.prank(recipient);
        vm.expectRevert(
            abi.encodeWithSelector(
                IPaymentChecks.NotClaimableYet.selector,
                claimableAt,
                START_TS
            )
        );
        checks.redeemPaymentCheck(checkId);
    }

    function testVoidBeforeClaimableReturnsToIssuerAndPreventsRedeem() public {
        uint64 claimableAt = uint64(START_TS + 500);
        uint256 issuerBalBefore = token.balanceOf(issuer);

        uint256 checkId = _mintTo(recipient, claimableAt);

        // Void before claimableAt.
        vm.prank(issuer);
        checks.voidPaymentCheck(checkId);

        // Collateral returned to issuer, escrow cleared.
        assertEq(token.balanceOf(address(checks)), 0, "escrow not cleared on void");
        assertEq(token.balanceOf(issuer), issuerBalBefore, "issuer not refunded on void");

        // NFT still exists and stays with recipient.
        assertEq(checks.ownerOf(checkId), recipient, "nft ownership changed on void");

        // Warp past claimableAt and redeem should still fail (VOID).
        vm.warp(claimableAt + 1);

        vm.prank(recipient);
        vm.expectRevert(
            abi.encodeWithSelector(
                IPaymentChecks.CheckNotActive.selector,
                checkId,
                IPaymentChecks.Status.VOID
            )
        );
        checks.redeemPaymentCheck(checkId);

        IPaymentChecks.Status st = checks.getPaymentCheckStatus(checkId);
        assertTrue(st == IPaymentChecks.Status.VOID, "status not void");
    }

    function testCannotVoidAfterClaimableAt() public {
        uint64 claimableAt = uint64(START_TS + 200);
        uint256 checkId = _mintTo(recipient, claimableAt);

        // At claimableAt, void should be too late.
        vm.warp(claimableAt);

        vm.prank(issuer);
        vm.expectRevert(
            abi.encodeWithSelector(
                PaymentChecks.TooLateToVoid.selector,
                claimableAt,
                claimableAt
            )
        );
        checks.voidPaymentCheck(checkId);
    }

    function testTransferThenRedeemNewOwnerReceivesFunds() public {
        uint256 checkId = _mintTo(recipient, 0);

        // Transfer NFT to otherHolder.
        vm.prank(recipient);
        checks.transferFrom(recipient, otherHolder, checkId);

        assertEq(checks.ownerOf(checkId), otherHolder, "transfer failed");

        // Only new owner can redeem and receives funds.
        vm.prank(otherHolder);
        checks.redeemPaymentCheck(checkId);

        assertEq(token.balanceOf(otherHolder), AMOUNT, "new owner did not receive funds");
    }

    function testOnlyOwnerCanRedeem() public {
        uint256 checkId = _mintTo(recipient, 0);

        vm.prank(issuer);
        vm.expectRevert(
            abi.encodeWithSelector(
                IPaymentChecks.NotOwner.selector,
                issuer
            )
        );
        checks.redeemPaymentCheck(checkId);
    }

    function testOnlyIssuerCanVoid() public {
        uint64 claimableAt = uint64(START_TS + 1000);
        uint256 checkId = _mintTo(recipient, claimableAt);

        vm.prank(recipient);
        vm.expectRevert(
            abi.encodeWithSelector(
                IPaymentChecks.NotIssuer.selector,
                recipient
            )
        );
        checks.voidPaymentCheck(checkId);
    }

    function testInvalidInputs() public {
        _approveFromIssuer(AMOUNT);

        // initialHolder = 0
        vm.startPrank(issuer);
        vm.expectRevert(IPaymentChecks.InvalidHolder.selector);
        checks.mintPaymentCheck(address(0), address(token), AMOUNT, 0, bytes32(0));
        vm.stopPrank();

        // token = 0
        vm.startPrank(issuer);
        vm.expectRevert(IPaymentChecks.InvalidToken.selector);
        checks.mintPaymentCheck(recipient, address(0), AMOUNT, 0, bytes32(0));
        vm.stopPrank();

        // amount = 0
        _approveFromIssuer(0);
        vm.startPrank(issuer);
        vm.expectRevert(IPaymentChecks.InvalidAmount.selector);
        checks.mintPaymentCheck(recipient, address(token), 0, 0, bytes32(0));
        vm.stopPrank();

        // claimableAt in the past
        _approveFromIssuer(AMOUNT);
        vm.startPrank(issuer);
        vm.expectRevert(
            abi.encodeWithSelector(
                IPaymentChecks.InvalidClaimableAt.selector,
                uint64(START_TS - 1)
            )
        );
        checks.mintPaymentCheck(recipient, address(token), AMOUNT, uint64(START_TS - 1), bytes32(0));
        vm.stopPrank();
    }

    function testNonexistentCheckReverts() public {
        vm.prank(recipient);
        vm.expectRevert(
            abi.encodeWithSelector(
                IPaymentChecks.CheckNotFound.selector,
                uint256(9999)
            )
        );
        checks.redeemPaymentCheck(9999);
    }
}

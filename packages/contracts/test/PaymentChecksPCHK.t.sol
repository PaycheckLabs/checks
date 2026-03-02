// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {PaymentChecksPCHK} from "../src/PaymentChecksPCHK.sol";
import {ChecksAccount} from "../src/ChecksAccount.sol";
import {MockUSD} from "../src/MockUSD.sol";
import {IERC6551Account} from "../src/vendor/erc6551/IERC6551Account.sol";
import {ERC6551Registry} from "./ERC6551Registry.sol";

interface Vm {
    function warp(uint256) external;
    function prank(address) external;
    function startPrank(address) external;
    function stopPrank() external;
    function expectRevert(bytes4) external;
    function expectRevert(bytes calldata) external;
}

contract PaymentChecksPCHKTest {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    ERC6551Registry internal registry;
    ChecksAccount internal accountImpl;
    MockUSD internal musd;
    PaymentChecksPCHK internal pchk;

    address internal issuer = address(0xA11CE);
    address internal recipient = address(0xB0B);
    address internal otherHolder = address(0xCAFE);

    uint256 internal constant AMOUNT = 1_500e6;
    uint64 internal constant START_TS = 1_800_000_000;

    bytes32 internal constant SALT = bytes32(uint256(0));

    function setUp() public {
        vm.warp(START_TS);

        registry = new ERC6551Registry();
        accountImpl = new ChecksAccount();
        musd = new MockUSD();

        // fund issuer
        vm.startPrank(issuer);
        musd.mint(issuer, AMOUNT * 10);
        vm.stopPrank();

        pchk = new PaymentChecksPCHK(
            "Payment Checks (ERC6551)",
            "PCHK",
            address(registry),
            address(accountImpl),
            SALT,
            address(musd)
        );
    }

    // --- helpers ---
    function assertEq(uint256 a, uint256 b, string memory msg_) internal pure { require(a == b, msg_); }
    function assertEq(address a, address b, string memory msg_) internal pure { require(a == b, msg_); }
    function assertEq(bytes32 a, bytes32 b, string memory msg_) internal pure { require(a == b, msg_); }
    function assertTrue(bool v, string memory msg_) internal pure { require(v, msg_); }

    function _approveFromIssuer(uint256 amount) internal {
        vm.startPrank(issuer);
        musd.approve(address(pchk), amount);
        vm.stopPrank();
    }

    function _mintTo(address initialHolder, uint64 claimableAt, bytes32 serial) internal returns (uint256 checkId, address account) {
        _approveFromIssuer(AMOUNT);
        vm.startPrank(issuer);
        (checkId, account) = pchk.mintPaymentCheck(
            initialHolder,
            AMOUNT,
            claimableAt,
            serial,
            bytes32("Test Title"),
            "Test memo"
        );
        vm.stopPrank();
    }

    // --- tests ---
    function testMintFundsTBAAndRedeem() public {
        bytes32 serial = bytes32("SERIAL-0001");

        (uint256 checkId, address account) = _mintTo(recipient, 0, serial);

        // TBA address is deterministic + deployed
        assertEq(account, pchk.accountOf(checkId), "accountOf mismatch");
        assertTrue(account.code.length > 0, "TBA not deployed");

        // Funds are held in TBA (not in PCHK)
        assertEq(musd.balanceOf(account), AMOUNT, "TBA not funded");
        assertEq(musd.balanceOf(address(pchk)), 0, "PCHK should not hold escrow");

        // NFT owned by recipient
        assertEq(pchk.ownerOf(checkId), recipient, "nft owner mismatch");

        // TBA owner() reflects NFT owner
        assertEq(IERC6551Account(payable(account)).owner(), recipient, "tba owner mismatch");

        // redeem as recipient
        vm.prank(recipient);
        pchk.redeemPaymentCheck(checkId);

        assertEq(musd.balanceOf(recipient), AMOUNT, "recipient did not receive");
        assertEq(musd.balanceOf(account), 0, "tba not drained");
    }

    function testPostDatedCannotRedeemBeforeClaimableAtThenSucceeds() public {
        bytes32 serial = bytes32("SERIAL-0002");
        uint64 claimableAt = uint64(START_TS + 100);

        (uint256 checkId, ) = _mintTo(recipient, claimableAt, serial);

        vm.prank(recipient);
        vm.expectRevert(abi.encodeWithSelector(PaymentChecksPCHK.NotClaimableYet.selector, claimableAt, START_TS));
        pchk.redeemPaymentCheck(checkId);

        vm.warp(claimableAt + 1);

        vm.prank(recipient);
        pchk.redeemPaymentCheck(checkId);

        assertEq(musd.balanceOf(recipient), AMOUNT, "recipient did not receive after claimable");
    }

    function testTransferThenRedeemNewOwnerReceivesFunds() public {
        bytes32 serial = bytes32("SERIAL-0003");
        (uint256 checkId, ) = _mintTo(recipient, 0, serial);

        vm.prank(recipient);
        pchk.transferFrom(recipient, otherHolder, checkId);

        vm.prank(otherHolder);
        pchk.redeemPaymentCheck(checkId);

        assertEq(musd.balanceOf(otherHolder), AMOUNT, "new owner did not receive funds");
    }

    function testVoidBeforeClaimableReturnsToIssuerAndLocksRedeem() public {
        bytes32 serial = bytes32("SERIAL-0004");
        uint64 claimableAt = uint64(START_TS + 500);

        uint256 issuerBalBefore = musd.balanceOf(issuer);

        (uint256 checkId, address account) = _mintTo(recipient, claimableAt, serial);

        vm.prank(issuer);
        pchk.voidPaymentCheck(checkId);

        assertEq(musd.balanceOf(account), 0, "tba not cleared on void");
        assertEq(musd.balanceOf(issuer), issuerBalBefore, "issuer not refunded");

        vm.warp(claimableAt + 1);
        vm.prank(recipient);
        vm.expectRevert(abi.encodeWithSelector(PaymentChecksPCHK.CheckNotActive.selector, checkId, PaymentChecksPCHK.Status.VOID));
        pchk.redeemPaymentCheck(checkId);
    }

    function testOwnerCannotExecuteCallDirectly() public {
        bytes32 serial = bytes32("SERIAL-0005");
        (, address account) = _mintTo(recipient, 0, serial);

        // direct executeCall from recipient must revert because msg.sender != tokenContract (PCHK)
        vm.prank(recipient);
        vm.expectRevert(abi.encodeWithSelector(ChecksAccount.NotTokenContract.selector, recipient));
        IERC6551Account(payable(account)).executeCall(address(musd), 0, abi.encodeWithSignature("transfer(address,uint256)", recipient, 1));
    }

    function testSerialUniqueness() public {
        bytes32 serial = bytes32("SERIAL-DUPE");

        _mintTo(recipient, 0, serial);

        _approveFromIssuer(AMOUNT);
        vm.startPrank(issuer);
        vm.expectRevert(abi.encodeWithSelector(PaymentChecksPCHK.SerialAlreadyUsed.selector, serial));
        pchk.mintPaymentCheck(recipient, AMOUNT, 0, serial, bytes32("Title"), "memo");
        vm.stopPrank();
    }
}

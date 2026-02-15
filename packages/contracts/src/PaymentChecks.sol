// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IPaymentChecks} from "./IPaymentChecks.sol";

import {ERC721} from "./vendor/openzeppelin/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/utils/ReentrancyGuard.sol";

import {IERC20} from "./vendor/openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/token/ERC20/utils/SafeERC20.sol";

/// @title PaymentChecks
/// @notice NFT-based, ERC20-collateralized payment checks.
/// @dev Locked v1 scope:
/// - Checks are ERC721 NFTs and are transferable.
/// - Owner-only redeem.
/// - Post-dated checks can be voided by issuer before claimableAt. The NFT is never burned.
/// - No expiration in v1.
contract PaymentChecks is ERC721, ReentrancyGuard, IPaymentChecks {
    using SafeERC20 for IERC20;

    /// @dev Thrown when issuer tries to void after claimableAt has been reached.
    error TooLateToVoid(uint64 claimableAt, uint64 nowTs);

    mapping(uint256 => PaymentCheck) private _checks;
    uint256 private _nextId = 1;

    string private _baseTokenURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_
    ) ERC721(name_, symbol_) {
        _baseTokenURI = baseTokenURI_;
    }

    /// @inheritdoc IPaymentChecks
    function mintPaymentCheck(
        address initialHolder,
        address token,
        uint256 amount,
        uint64 claimableAt,
        bytes32 reference
    ) external nonReentrant returns (uint256 checkId) {
        if (initialHolder == address(0)) revert InvalidHolder();
        if (token == address(0)) revert InvalidToken();
        if (amount == 0) revert InvalidAmount();

        uint64 nowTs = uint64(block.timestamp);
        uint64 claimableAtTs = claimableAt == 0 ? nowTs : claimableAt;

        // claimableAt must not be in the past.
        if (claimableAtTs < nowTs) revert InvalidClaimableAt(claimableAtTs);

        checkId = _nextId++;
        address issuer = msg.sender;

        _checks[checkId] = PaymentCheck({
            issuer: issuer,
            token: token,
            amount: amount,
            createdAt: nowTs,
            claimableAt: claimableAtTs,
            reference: reference,
            status: Status.ACTIVE
        });

        // Escrow collateral.
        IERC20(token).safeTransferFrom(issuer, address(this), amount);

        // Mint and transfer the NFT check to the initial holder.
        _safeMint(initialHolder, checkId);

        emit PaymentCheckMinted(checkId, issuer, initialHolder, token, amount, claimableAtTs, reference);
    }

    /// @inheritdoc IPaymentChecks
    function redeemPaymentCheck(uint256 checkId) external nonReentrant {
        PaymentCheck storage pc = _requireCheck(checkId);

        if (pc.status != Status.ACTIVE) revert CheckNotActive(checkId, pc.status);

        address holder = ownerOf(checkId);
        if (holder != msg.sender) revert NotOwner(msg.sender);

        uint64 nowTs = uint64(block.timestamp);
        if (nowTs < pc.claimableAt) revert NotClaimableYet(pc.claimableAt, nowTs);

        pc.status = Status.REDEEMED;

        IERC20(pc.token).safeTransfer(holder, pc.amount);

        emit PaymentCheckRedeemed(checkId, holder, pc.token, pc.amount);
    }

    /// @inheritdoc IPaymentChecks
    function voidPaymentCheck(uint256 checkId) external nonReentrant {
        PaymentCheck storage pc = _requireCheck(checkId);

        if (pc.status != Status.ACTIVE) revert CheckNotActive(checkId, pc.status);
        if (pc.issuer != msg.sender) revert NotIssuer(msg.sender);

        uint64 nowTs = uint64(block.timestamp);
        if (nowTs >= pc.claimableAt) revert TooLateToVoid(pc.claimableAt, nowTs);

        pc.status = Status.VOID;

        IERC20(pc.token).safeTransfer(pc.issuer, pc.amount);

        emit PaymentCheckVoided(checkId, pc.issuer, pc.token, pc.amount);
    }

    /// @inheritdoc IPaymentChecks
    function getPaymentCheck(uint256 checkId) external view returns (PaymentCheck memory) {
        PaymentCheck storage pc = _checks[checkId];
        if (pc.status == Status.NONE) revert CheckNotFound(checkId);
        return pc;
    }

    /// @inheritdoc IPaymentChecks
    function getPaymentCheckStatus(uint256 checkId) external view returns (Status) {
        Status st = _checks[checkId].status;
        if (st == Status.NONE) revert CheckNotFound(checkId);
        return st;
    }

    /// @inheritdoc IPaymentChecks
    function nextCheckId() external view returns (uint256) {
        return _nextId;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _requireCheck(uint256 checkId) internal view returns (PaymentCheck storage pc) {
        pc = _checks[checkId];
        if (pc.status == Status.NONE) revert CheckNotFound(checkId);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

interface IPaymentChecks {
    enum Status {
        NONE,
        ACTIVE,
        REDEEMED,
        VOID
    }

    struct PaymentCheck {
        address issuer;
        address token;
        uint256 amount;
        uint64 createdAt;
        uint64 claimableAt;
        bytes32 referenceId;
        Status status;
    }

    event PaymentCheckMinted(
        uint256 indexed checkId,
        address indexed issuer,
        address indexed initialHolder,
        address token,
        uint256 amount,
        uint64 claimableAt,
        bytes32 referenceId
    );

    event PaymentCheckRedeemed(
        uint256 indexed checkId,
        address indexed redeemer,
        address token,
        uint256 amount
    );

    event PaymentCheckVoided(
        uint256 indexed checkId,
        address indexed issuer,
        address token,
        uint256 amount
    );

    error CheckNotFound(uint256 checkId);
    error CheckNotActive(uint256 checkId, Status status);

    error InvalidHolder();
    error InvalidToken();
    error InvalidAmount();
    error InvalidClaimableAt(uint64 claimableAt);

    error NotOwner(address caller);
    error NotIssuer(address caller);

    error NotClaimableYet(uint64 claimableAt, uint64 nowTs);

    function mintPaymentCheck(
        address initialHolder,
        address token,
        uint256 amount,
        uint64 claimableAt,
        bytes32 referenceId
    ) external returns (uint256 checkId);

    function redeemPaymentCheck(uint256 checkId) external;

    /// @dev NFT is never burned. After VOID, redeem must be impossible.
    function voidPaymentCheck(uint256 checkId) external;

    function getPaymentCheck(uint256 checkId) external view returns (PaymentCheck memory);
    function getPaymentCheckStatus(uint256 checkId) external view returns (Status);
    function nextCheckId() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

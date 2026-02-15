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
        bytes32 reference;
        Status status;
    }

    event PaymentCheckMinted(
        uint256 indexed checkId,
        address indexed issuer,
        address indexed initialHolder,
        address token,
        uint256 amount,
        uint64 claimableAt,
        bytes32 reference
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

    /// @notice Mints an ERC721 check NFT and escrows ERC20 collateral.
    /// @dev Implementations must be ERC721 compatible. checkId is the ERC721 tokenId.
    /// @param initialHolder The address that receives the NFT at mint time.
    /// @param token ERC20 token address used as collateral.
    /// @param amount ERC20 amount escrowed.
    /// @param claimableAt Unix timestamp in seconds. If 0, implementation should treat as block.timestamp.
    /// @param reference Optional bytes32 correlation id for off-chain systems.
    function mintPaymentCheck(
        address initialHolder,
        address token,
        uint256 amount,
        uint64 claimableAt,
        bytes32 reference
    ) external returns (uint256 checkId);

    /// @notice Redeems the check collateral to the current NFT owner.
    /// @dev Owner-only redeem. Caller must be the current owner of the ERC721 tokenId.
    function redeemPaymentCheck(uint256 checkId) external;

    /// @notice Voids a post-dated check before it is claimable. Returns collateral to issuer.
    /// @dev NFT is never burned. After VOID, redeem must be impossible.
    function voidPaymentCheck(uint256 checkId) external;

    function getPaymentCheck(uint256 checkId) external view returns (PaymentCheck memory);

    function getPaymentCheckStatus(uint256 checkId) external view returns (Status);

    function nextCheckId() external view returns (uint256);

    /// @notice Standard ERC721 ownerOf is required for owner-only redeem logic.
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

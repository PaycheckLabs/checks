// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {ERC721} from "./vendor/openzeppelin/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/utils/ReentrancyGuard.sol";
import {IERC20} from "./vendor/openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {IERC6551Registry} from "./vendor/erc6551/IERC6551Registry.sol";
import {IERC6551Account} from "./vendor/erc6551/IERC6551Account.sol";

/// @title PaymentChecksPCHK (ERC-6551)
/// @notice Payment Checks that escrow collateral in a token-bound account (ERC-6551).
contract PaymentChecksPCHK is ERC721, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Status { NONE, ACTIVE, REDEEMED, VOID }

    struct PaymentCheck {
        address issuer;
        uint256 amount;
        uint64 createdAt;
        uint64 claimableAt;
        bytes32 serial;   // <= 32 chars packed as bytes32
        bytes32 title;    // <= 32 chars packed as bytes32
        string memo;      // capped bytes length
        Status status;
    }

    event PaymentCheckMinted(
        uint256 indexed checkId,
        bytes32 indexed serial,
        address indexed issuer,
        address initialHolder,
        address token,
        uint256 amount,
        uint64 claimableAt,
        address account
    );

    event PaymentCheckRedeemed(
        uint256 indexed checkId,
        address indexed redeemer,
        address token,
        uint256 amount,
        address account
    );

    event PaymentCheckVoided(
        uint256 indexed checkId,
        address indexed issuer,
        address token,
        uint256 amount,
        address account
    );

    error CheckNotFound(uint256 checkId);
    error CheckNotActive(uint256 checkId, Status status);
    error NotOwner(address caller);
    error NotIssuer(address caller);
    error NotClaimableYet(uint64 claimableAt, uint64 nowTs);
    error TooLateToVoid(uint64 claimableAt, uint64 nowTs);

    error InvalidHolder();
    error InvalidAmount();
    error InvalidClaimableAt(uint64 claimableAt);
    error SerialRequired();
    error SerialAlreadyUsed(bytes32 serial);
    error TitleRequired();
    error MemoTooLong(uint256 len, uint256 max);

    uint256 public constant MAX_MEMO_BYTES = 160;

    IERC6551Registry public immutable REGISTRY;
    address public immutable ACCOUNT_IMPLEMENTATION; // deployed ChecksAccount implementation address
    bytes32 public immutable ACCOUNT_SALT;
    IERC20 public immutable COLLATERAL_TOKEN;

    mapping(uint256 => PaymentCheck) private _checks;
    mapping(bytes32 => uint256) private _idBySerial;
    uint256 private _nextId = 1;

    constructor(
        string memory name_,
        string memory symbol_,
        address registry_,
        address accountImplementation_,
        bytes32 accountSalt_,
        address collateralToken_
    ) ERC721(name_, symbol_) {
        REGISTRY = IERC6551Registry(registry_);
        ACCOUNT_IMPLEMENTATION = accountImplementation_;
        ACCOUNT_SALT = accountSalt_;
        COLLATERAL_TOKEN = IERC20(collateralToken_);
    }

    function nextCheckId() external view returns (uint256) {
        return _nextId;
    }

    function tokenIdForSerial(bytes32 serial) external view returns (uint256) {
        return _idBySerial[serial];
    }

    function getPaymentCheck(uint256 checkId) external view returns (PaymentCheck memory) {
        PaymentCheck storage pc = _checks[checkId];
        if (pc.status == Status.NONE) revert CheckNotFound(checkId);
        return pc;
    }

    function accountOf(uint256 checkId) public view returns (address) {
        // works even if not created yet (deterministic)
        return REGISTRY.account(
            ACCOUNT_IMPLEMENTATION,
            ACCOUNT_SALT,
            block.chainid,
            address(this),
            checkId
        );
    }

    function mintPaymentCheck(
        address initialHolder,
        uint256 amount,
        uint64 claimableAt,
        bytes32 serial,
        bytes32 title,
        string calldata memo
    ) external nonReentrant returns (uint256 checkId, address account) {
        if (initialHolder == address(0)) revert InvalidHolder();
        if (amount == 0) revert InvalidAmount();
        if (serial == bytes32(0)) revert SerialRequired();
        if (_idBySerial[serial] != 0) revert SerialAlreadyUsed(serial);
        if (title == bytes32(0)) revert TitleRequired();

        if (bytes(memo).length > MAX_MEMO_BYTES) revert MemoTooLong(bytes(memo).length, MAX_MEMO_BYTES);

        uint64 nowTs = uint64(block.timestamp);
        uint64 claimableAtTs = claimableAt == 0 ? nowTs : claimableAt;
        if (claimableAtTs < nowTs) revert InvalidClaimableAt(claimableAtTs);

        checkId = _nextId++;
        _idBySerial[serial] = checkId;

        // 1) Create (deploy) the token-bound account for this NFT.
        account = REGISTRY.createAccount(
            ACCOUNT_IMPLEMENTATION,
            ACCOUNT_SALT,
            block.chainid,
            address(this),
            checkId
        );

        // 2) Fund the TBA directly at mint-time (whitepaper requirement). :contentReference[oaicite:7]{index=7}
        address issuer = msg.sender;
        COLLATERAL_TOKEN.safeTransferFrom(issuer, account, amount);

        // 3) Mint NFT to recipient
        _safeMint(initialHolder, checkId);

        // 4) Persist on-chain check data
        _checks[checkId] = PaymentCheck({
            issuer: issuer,
            amount: amount,
            createdAt: nowTs,
            claimableAt: claimableAtTs,
            serial: serial,
            title: title,
            memo: memo,
            status: Status.ACTIVE
        });

        emit PaymentCheckMinted(
            checkId,
            serial,
            issuer,
            initialHolder,
            address(COLLATERAL_TOKEN),
            amount,
            claimableAtTs,
            account
        );
    }

    function redeemPaymentCheck(uint256 checkId) external nonReentrant {
        PaymentCheck storage pc = _requireCheck(checkId);
        if (pc.status != Status.ACTIVE) revert CheckNotActive(checkId, pc.status);

        address holder = ownerOf(checkId);
        if (holder != msg.sender) revert NotOwner(msg.sender);

        uint64 nowTs = uint64(block.timestamp);
        if (nowTs < pc.claimableAt) revert NotClaimableYet(pc.claimableAt, nowTs);

        address account = accountOf(checkId);

        // Move collateral out of the TBA via the TBA itself.
        // ChecksAccount restricts executeCall so only this NFT contract can move funds.
        IERC6551Account(payable(account)).executeCall(
            address(COLLATERAL_TOKEN),
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, holder, pc.amount)
        );

        pc.status = Status.REDEEMED;
        emit PaymentCheckRedeemed(checkId, holder, address(COLLATERAL_TOKEN), pc.amount, account);
    }

    function voidPaymentCheck(uint256 checkId) external nonReentrant {
        PaymentCheck storage pc = _requireCheck(checkId);
        if (pc.status != Status.ACTIVE) revert CheckNotActive(checkId, pc.status);
        if (pc.issuer != msg.sender) revert NotIssuer(msg.sender);

        uint64 nowTs = uint64(block.timestamp);
        if (nowTs >= pc.claimableAt) revert TooLateToVoid(pc.claimableAt, nowTs);

        address account = accountOf(checkId);

        IERC6551Account(payable(account)).executeCall(
            address(COLLATERAL_TOKEN),
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, pc.issuer, pc.amount)
        );

        pc.status = Status.VOID;
        emit PaymentCheckVoided(checkId, pc.issuer, address(COLLATERAL_TOKEN), pc.amount, account);
    }

    function _requireCheck(uint256 checkId) internal view returns (PaymentCheck storage pc) {
        pc = _checks[checkId];
        if (pc.status == Status.NONE) revert CheckNotFound(checkId);
    }
}

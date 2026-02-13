// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

interface IPaymentChecks {
    event PaymentCheckMinted(
        uint256 indexed checkId,
        address indexed sender,
        address indexed recipient,
        address token,
        uint256 amount
    );

    event PaymentCheckRedeemed(uint256 indexed checkId, address indexed redeemer);

    function mintPaymentCheck(address recipient, address token, uint256 amount) external returns (uint256);
    function redeemPaymentCheck(uint256 checkId) external;
}

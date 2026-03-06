// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {PaymentChecks} from "./PaymentChecks.sol";

/// @title PaymentChecksPCHK (DEPRECATED)
/// @notice Back-compat wrapper for the old contract name.
/// @dev Use `PaymentChecks` (ERC-6551) instead. Delete this once no code imports it.
contract PaymentChecksPCHK is PaymentChecks {
    constructor(
        string memory name_,
        string memory symbol_,
        address registry_,
        address accountImplementation_,
        bytes32 accountSalt_,
        address collateralToken_
    ) PaymentChecks(name_, symbol_, registry_, accountImplementation_, accountSalt_, collateralToken_) {}
}

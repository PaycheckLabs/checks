// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import { IPaymentChecks } from "../../src/IPaymentChecks.sol";

/// @dev ERC20 that returns no data on transfer/transferFrom (USDT-style).
contract NoReturnERC20 {
    uint8 public immutable decimals;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint8 decimals_) {
        decimals = decimals_;
    }

    function mint(address to, uint256 amount) external {
        require(to != address(0), "mint to zero");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // NOTE: public (not external) so derived contracts can call super.*
    function transfer(address to, uint256 amount) public virtual {
        _transfer(msg.sender, to, amount);
    }

    // NOTE: public (not external) so derived contracts can call super.*
    function transferFrom(address from, address to, uint256 amount) public virtual {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance");

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }

        _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "transfer to zero");

        uint256 bal = balanceOf[from];
        require(bal >= amount, "balance");

        unchecked {
            balanceOf[from] = bal - amount;
        }

        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}

/// @dev ERC20 that returns false on transfer/transferFrom.
contract FalseReturnERC20 {
    uint8 public immutable decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint8 decimals_) {
        decimals = decimals_;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address, uint256) external pure returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        return false;
    }
}

/// @dev ERC20 that attempts a reentrant mint during transferFrom to test nonReentrant.
contract ReentrantERC20 is NoReturnERC20 {
    address public checks;
    bool internal reentered;

    constructor(uint8 decimals_) NoReturnERC20(decimals_) {}

    function setChecks(address checks_) external {
        checks = checks_;
    }

    function transferFrom(address from, address to, uint256 amount) public override {
        if (!reentered && checks != address(0)) {
            reentered = true;
            // This should fail due to PaymentChecks nonReentrant.
            IPaymentChecks(checks).mintPaymentCheck(to, address(this), 1, 0, bytes32(0));
        }

        super.transferFrom(from, to, amount);
    }
}

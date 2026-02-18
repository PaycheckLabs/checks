// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {PaymentChecks} from "../src/PaymentChecks.sol";
import {MockERC20} from "../test/MockERC20.sol";

interface Vm {
    function envUint(string calldata name) external returns (uint256);
    function addr(uint256 privateKey) external returns (address);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

contract DeployAndSmoke {
    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    event Deployed(address indexed paymentChecks, address indexed token);
    event Smoked(uint256 redeemCheckId, uint256 voidCheckId);

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // Deploy core contract
        PaymentChecks checks = new PaymentChecks(
            "Payment Checks",
            "pCHECK",
            "https://checks.xyz/metadata/payment-checks/"
        );

        // Deploy a simple mintable ERC20 for smoke testing
        MockERC20 token = new MockERC20("Mock USD", "mUSD", 6);

        // Fund deployer with tokens and approve PaymentChecks
        token.mint(deployer, 1_000 * 1e6); // 1,000 mUSD (6 decimals)
        token.approve(address(checks), type(uint256).max);

        uint64 claimableAt = uint64(block.timestamp);
        uint256 amount = 10 * 1e6; // 10 mUSD

        // 1) Mint then redeem
        uint256 redeemCheckId = checks.mintPaymentCheck(
            deployer,
            address(token),
            amount,
            claimableAt,
            keccak256("smoke-redeem")
        );
        checks.redeemPaymentCheck(redeemCheckId);

        // 2) Mint then void
        uint256 voidCheckId = checks.mintPaymentCheck(
            deployer,
            address(token),
            amount,
            claimableAt,
            keccak256("smoke-void")
        );
        checks.voidPaymentCheck(voidCheckId);

        vm.stopBroadcast();

        emit Deployed(address(checks), address(token));
        emit Smoked(redeemCheckId, voidCheckId);
    }
}

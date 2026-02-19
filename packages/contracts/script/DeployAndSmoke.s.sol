// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {PaymentChecks} from "../src/PaymentChecks.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract DeployAndSmoke is Script {
    function run() external {
        // Accepts:
        // - "0x..." hex private key
        // - or a raw 64-char hex string (we auto-prefix 0x)
        string memory pkStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = _parsePrivateKey(pkStr);
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1) Deploy contracts
        PaymentChecks checks = new PaymentChecks();
        MockERC20 token = new MockERC20();

        // 2) Fund deployer with mock tokens for testing
        uint8 dec = token.decimals();
        uint256 unit = 10 ** uint256(dec);

        // Mint 1,000 tokens to the deployer
        token.mint(deployer, 1000 * unit);

        // 3) Approve checks contract to pull tokens
        uint256 amount = 1 * unit; // 1 token (based on decimals)
        token.approve(address(checks), amount);

        // 4) Mint a PaymentCheck that is immediately claimable
        // Using claimableAt = 0 avoids post-dated validation rules.
        uint64 claimableAt = 0;

        // Unique referenceId per run
        bytes32 referenceId = keccak256(
            abi.encodePacked("amoy-smoke", block.chainid, block.number, deployer, address(token), amount)
        );

        uint256 checkId = checks.mintPaymentCheck(
            deployer,         // recipient/owner
            address(token),   // token
            amount,           // amount
            claimableAt,      // claimableAt (0 = immediate)
            referenceId       // unique ref
        );

        vm.stopBroadcast();

        // Logs for your terminal
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("PaymentChecks:", address(checks));
        console2.log("MockERC20:", address(token));
        console2.log("checkId:", checkId);
    }

    function _parsePrivateKey(string memory pk) internal view returns (uint256) {
        bytes memory b = bytes(pk);

        // If user pasted raw 64-hex characters, prefix it with 0x
        if (b.length == 64) {
            pk = string.concat("0x", pk);
        }

        // vm.parseUint supports 0x-prefixed hex and decimal strings
        return vm.parseUint(pk);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC6551Registry} from "../src/vendor/erc6551/IERC6551Registry.sol";

/// @notice Test-only ERC-6551 registry (reference implementation style).
/// @dev This matches the ERC-6551 spec layout for minimal proxy + appended immutable data.
contract ERC6551Registry is IERC6551Registry {
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address) {
        assembly {
            // Silence unused variable warnings (chainId is part of appended data but not used directly here)
            pop(chainId)

            // Copy bytecode + constant data to memory
            // calldata layout for args after selector:
            // implementation @ 0x04
            // salt          @ 0x24
            // chainId       @ 0x44
            // tokenContract @ 0x64
            // tokenId       @ 0x84
            calldatacopy(0x8c, 0x24, 0x80) // salt, chainId, tokenContract, tokenId
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(0x5d, implementation)                  // implementation
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // constructor + header

            // Copy create2 computation data to memory
            mstore(0x35, keccak256(0x55, 0xb7)) // bytecode hash
            mstore(0x15, salt)                  // salt
            mstore(0x01, shl(96, address()))    // registry address
            mstore8(0x00, 0xff)                 // 0xff

            // Compute account address
            let computed := keccak256(0x00, 0x55)

            // If not deployed, deploy
            if iszero(extcodesize(computed)) {
                let deployed := create2(0, 0x55, 0xb7, salt)
                if iszero(deployed) {
                    mstore(0x00, 0x20188a59) // AccountCreationFailed()
                    revert(0x1c, 0x04)
                }

                // Emit event (store deployed at 0x6c so event payload matches reference)
                mstore(0x6c, deployed)
                log4(
                    0x6c,
                    0x60,
                    0x79f19b3655ee38b1ce526556b7731a20c8f218fbda4a3990b6cc4172fdf88722,
                    implementation,
                    tokenContract,
                    tokenId
                )
                return(0x6c, 0x20)
            }

            // Already deployed: return computed
            mstore(0x00, shr(96, shl(96, computed)))
            return(0x00, 0x20)
        }
    }

    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address) {
        assembly {
            pop(chainId)
            pop(tokenContract)
            pop(tokenId)

            calldatacopy(0x8c, 0x24, 0x80)
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3)
            mstore(0x5d, implementation)
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)

            mstore(0x35, keccak256(0x55, 0xb7))
            mstore(0x15, salt)
            mstore(0x01, shl(96, address()))
            mstore8(0x00, 0xff)

            mstore(0x00, shr(96, shl(96, keccak256(0x00, 0x55))))
            return(0x00, 0x20)
        }
    }
}

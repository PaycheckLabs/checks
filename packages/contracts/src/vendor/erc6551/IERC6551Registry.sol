// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev ERC-6551 Registry interface (singleton at 0x000000006551... on supported chains).
/// Spec: https://eips.ethereum.org/EIPS/eip-6551 :contentReference[oaicite:2]{index=2}
interface IERC6551Registry {
    event ERC6551AccountCreated(
        address account,
        address indexed implementation,
        bytes32 salt,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    error AccountCreationFailed();

    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);

    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address account);
}

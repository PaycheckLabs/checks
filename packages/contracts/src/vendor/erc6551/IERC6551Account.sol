// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev ERC-6551 Account interface (ERC-165 id = 0x6faff5f1)
/// Spec: https://eips.ethereum.org/EIPS/eip-6551 :contentReference[oaicite:3]{index=3}
interface IERC6551Account {
    receive() external payable;

    function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId);
    function owner() external view returns (address);
    function nonce() external view returns (uint256);

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result);
}

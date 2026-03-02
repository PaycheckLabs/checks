// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IERC6551Account} from "./vendor/erc6551/IERC6551Account.sol";
import {IERC165} from "./vendor/openzeppelin/utils/introspection/IERC165.sol";
import {ERC165} from "./vendor/openzeppelin/utils/introspection/ERC165.sol";
import {IERC721} from "./vendor/openzeppelin/token/ERC721/IERC721.sol";

/// @title ChecksAccount
/// @notice ERC-6551 account implementation used as the `implementation` parameter in the ERC-6551 Registry.
/// @dev This implementation intentionally restricts `executeCall` so the NFT owner cannot drain escrow early.
///      Only the bound NFT contract (tokenContract) may execute outbound calls.
contract ChecksAccount is ERC165, IERC6551Account {
    // EIP-1271 magic value
    bytes4 internal constant _ERC1271_MAGICVALUE = 0x1626ba7e;

    error NotTokenContract(address caller);
    error InvalidSignatureLength(uint256 len);
    error CallFailed(bytes data);

    uint256 private _nonce;

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC6551Account
    function nonce() external view returns (uint256) {
        return _nonce;
    }

    /// @inheritdoc IERC6551Account
    function token() public view returns (uint256 chainId, address tokenContract, uint256 tokenId) {
        // Per ERC-6551: appended immutable data at end of the account proxy bytecode:
        // <salt (32)> <chainId (32)> <tokenContract (32)> <tokenId (32)>
        // We read the last 128 bytes of our own bytecode.
        bytes memory data = new bytes(128);
        assembly {
            let size := extcodesize(address())
            // copy last 128 bytes into data
            extcodecopy(address(), add(data, 32), sub(size, 128), 128)
        }

        bytes32 _salt;
        assembly {
            _salt := mload(add(data, 32))            // salt (unused here)
            chainId := mload(add(data, 64))          // chainId
            tokenContract := and(mload(add(data, 96)), 0xffffffffffffffffffffffffffffffffffffffff)
            tokenId := mload(add(data, 128))         // tokenId
        }
    }

    /// @inheritdoc IERC6551Account
    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);
        return IERC721(tokenContract).ownerOf(tokenId);
    }

    /// @inheritdoc IERC6551Account
    function executeCall(address to, uint256 value, bytes calldata data)
        external
        payable
        returns (bytes memory result)
    {
        (, address tokenContract, ) = token();
        if (msg.sender != tokenContract) revert NotTokenContract(msg.sender);

        _nonce++;

        (bool ok, bytes memory ret) = to.call{value: value}(data);
        if (!ok) revert CallFailed(ret);
        return ret;
    }

    /// @notice EIP-1271 signature validation (minimal).
    /// @dev Accepts a standard 65-byte {r,s,v} signature over `hash`.
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {
        if (signature.length != 65) revert InvalidSignatureLength(signature.length);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }

        address recovered = ecrecover(hash, v, r, s);
        if (recovered != address(0) && recovered == owner()) {
            return _ERC1271_MAGICVALUE;
        }
        return 0xffffffff;
    }
}

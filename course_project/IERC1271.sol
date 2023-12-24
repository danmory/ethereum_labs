// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes calldata signature)
        external
        returns (bytes4 magicValue);
}

bytes4 constant MAGICVALUE = 0x1626ba7e;

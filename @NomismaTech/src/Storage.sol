// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {StructDefiner} from "./StructDefiner.sol";

contract Storage {
    StructDefiner.MyStruct[] internal structs;
    error OutOfBounds();

    function push(StructDefiner.MyStruct memory s) public {
        structs.push(s);
    }

    function getEncodedStructByIndex(uint256 index) external view returns (bytes memory payload) {
        if (index > structs.length) revert OutOfBounds();

        bytes32 storageLocation = getStorageLocation(index);

        assembly {
            // Get the position of free memory pointer
            payload := mload(0x40)

            // Defines the length of the bytes array as 96 bytes, one for each storage slot used
            mstore(payload, 0x80)

            let structSlot0 := sload(storageLocation)
            let structSlot1 := sload(add(storageLocation, 0x1))
            let structSlot2 := sload(add(storageLocation, 0x2))

            // Shift left first half 16 bytes
            let firstHalf := shr(0x80, structSlot2)
            // Apply a mask to get rid of the first value
            let secondHalf := and(structSlot2, sub(shl(0x80, 0x1), 0x1))

            // Here I need to convert the single storage slot, holding the two last fields of the struct
            // into two different words of memory, to emulate abi.encode

            mstore(add(payload, 0x20), structSlot0)
            mstore(add(payload, 0x40), structSlot1)
            mstore(add(payload, 0x60), secondHalf)
            mstore(add(payload, 0x80), firstHalf)

            // We should should encode in the same format that ABI returns the value.
            // That means we should revert the order of the two variables
            // mstore(add(payload, 0x60), or(shl(0x80, structSlot2), shr(0x80, structSlot2)))

            // Updates free memory pointer => Why do we need to update the memory pointer in order
            // to return the correct value ?
            mstore(0x40, add(payload, 0xa0)) 
        }
    }

    function getStorageLocation(uint256 index) public pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encodePacked(bytes32(0)))) + (index * 3));
    }
}

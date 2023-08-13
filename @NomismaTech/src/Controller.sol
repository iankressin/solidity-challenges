// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StructDefiner} from "./StructDefiner.sol";
import "./Storage.sol";

contract Controller {
    Storage internal storageContract;

    constructor(address _storageContract) {
        storageContract = Storage(_storageContract);
    }

    function decodeStructByIndex(uint256 index) public view returns (StructDefiner.MyStruct memory myStruct) {
        bytes memory encodedStruct = storageContract.getEncodedStructByIndex(index);

        // I need to debug this assembly block to understand why my variables aren't being allocated
        // in the same memory words as the ones being returned from the named return of this function
        // 
        // The rationale behing what's going on is the following
        // 1 - Load the memory pointer to a variable
        // 2 - Write the byte offsets from encoded struct into the same offsets of memory words
        // 3 - Update the free memory pointer
        // 
        // This is probably not working because I'm writing a value a the memory address where my struct is stored
        // and then, using the value of that field to write another value in memory + the offset of a word.
        assembly {
            myStruct := mload(0x40)

            // mstore(add(freeMemoryPointer), )
            mstore(myStruct, mload(add(encodedStruct, 0x20)))
            mstore(add(myStruct, 0x20), mload(add(encodedStruct, 0x40)))
            mstore(add(myStruct, 0x40), mload(add(encodedStruct, 0x60)))
            mstore(add(myStruct, 0x60), mload(add(encodedStruct, 0x80)))

            mstore(0x40, add(myStruct, 0xa0)) 
        }
    }
}

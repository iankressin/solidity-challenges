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
        // How is this represented in memory
        bytes memory encodedStruct = storageContract.getEncodedStructByIndex(index);

        assembly {
            myStruct := mload(0x40)

            mstore(myStruct, mload(add(encodedStruct, 0x20)))
            mstore(add(myStruct, 0x20), mload(add(encodedStruct, 0x40)))
            mstore(add(myStruct, 0x40), mload(add(encodedStruct, 0x60)))
            mstore(add(myStruct, 0x60), mload(add(encodedStruct, 0x80)))

            mstore(0x40, add(myStruct, 0xa0)) 
        }
    }
}

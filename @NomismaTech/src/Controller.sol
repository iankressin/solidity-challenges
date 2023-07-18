// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {StructDefiner} from "./StructDefiner.sol";
import "./Storage.sol";

contract Controller {
  Storage internal storageContract;

  constructor(address _storageContract) {
    storageContract = Storage(_storageContract);
  }

  function decodeStructByIndex(uint256 index) public returns (StructDefiner.MyStruct memory myStruct) {
    bytes memory encodedStruct = storageContract.getEncodedStructByIndex(index);

    uint256 field0;
    address field1;
    uint128 field2;
    uint128 field3;

    assembly {
        field0 := mload(add(encodedStruct, 32))
        field1 := mload(add(encodedStruct, 52))
        field2 := mload(add(encodedStruct, 68))
        field3 := mload(add(encodedStruct, 84))
    }

    return StructDefiner.MyStruct(
        field0,
        field1,
        field2,
        field3
    );
  }
}

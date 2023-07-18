// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {StructDefiner} from "./StructDefiner.sol";

contract Storage {
    // uint256 someField; 32 bytes - 1 slot
    // address someAddress; 20 bytes - but there's no variable to be packed together - 1 slot
    // uint128 someOtherField; 16 bytes - 1/2 slot
    // uint128 oneMoreField; 16 bytes - 1/2 slot
    // ---------------------------------------
    // TOTAL OF 3 SLOTS
    uint8 amountOfStorageSlotsStructTakes = 3;
    StructDefiner.MyStruct[] internal structs;

    function push(StructDefiner.MyStruct memory s) public {
        structs.push(s);
    }

    function getEncodedStructByIndex(uint256 index) external view returns (bytes memory payload) {
        StructDefiner.MyStruct memory myStruct = structs[index];

        bytes32 storageLocation = getStorageLocation(index);

        uint256 field0AsBytes; 
        address field1AsBytes;
        uint128 field2AsBytes;
        uint128 field3AsBytes;

        bytes32 uint128StorageMask = hex"00000000000000000000000000000000ffffffffffffffffffffffffffffffff";

        assembly {
            field0AsBytes := sload(storageLocation)
            field1AsBytes := sload(add(storageLocation, 0x1))

            let storageSlot := sload(add(storageLocation, 0x2))

            field2AsBytes := and(storageSlot, uint128StorageMask)
            field3AsBytes := shr(128, and(storageSlot, shl(128, uint128StorageMask)))
        }

        payload = abi.encodePacked(
            field0AsBytes,
            field1AsBytes,
            field2AsBytes,
            field3AsBytes
        );
    }

    function getStorageLocation(uint256 index) public view returns (bytes32) {
        bytes32 initialArrayStorage = keccak256(abi.encodePacked(bytes32(uint256(0))));

        return bytes32(uint256(initialArrayStorage) + (index * 3));
    }
}

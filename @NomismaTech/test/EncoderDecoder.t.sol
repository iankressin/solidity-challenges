// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/Controller.sol";
import "../src/Storage.sol";
import {StructDefiner} from "../src/StructDefiner.sol";

contract ByteEncoderDecoder is Test {
    Storage public storageContract;
    Controller public controller;
    address public alice;
    StructDefiner.MyStruct public structInstance;


    function setUp() public {
        alice = vm.addr(1);

        storageContract = new Storage();
        controller = new Controller(address(storageContract));

        structInstance = StructDefiner.MyStruct({
            someField: 10,
            someAddress: alice,
            someOtherField: 11,
            oneMoreField: 12
        });

        storageContract.push(structInstance);
    }

    function testEncode() public {
        bytes memory target = hex"000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000007e5f4552091a69125d5dfcb7b8c2659029395bdf000000000000000000000000000000000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000c";
        bytes memory encoded = storageContract.getEncodedStructByIndex(0);

        assertEq0(encoded, target);
    }

    function testDecode() public {
        StructDefiner.MyStruct memory decodedStruct = controller.decodeStructByIndex(0);

        assertEq(decodedStruct.someField, structInstance.someField);
        assertEq(decodedStruct.someAddress, structInstance.someAddress);
        assertEq(decodedStruct.someOtherField, structInstance.someOtherField);
        assertEq(decodedStruct.oneMoreField, structInstance.oneMoreField);
    }


    function testGetStorageLocation() public {
        bytes32 firstArrayPosition = hex"290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563";
        bytes32 secondArrayPosition = hex"290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e566";
        bytes32 tenthArrayPosition = hex"290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e581";

        assertEq(firstArrayPosition, storageContract.getStorageLocation(0));
        assertEq(secondArrayPosition, storageContract.getStorageLocation(1));
        assertEq(tenthArrayPosition, storageContract.getStorageLocation(10));
    }
}

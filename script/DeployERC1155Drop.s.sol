// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "forge-std/Script.sol";
import { ERC1155Drop } from "src/ERC1155Drop.sol";
import { DropType } from "src/libs/Structs.sol";

contract DeployERC1155Drop is Script {
    function run() public {
        vm.startBroadcast();

        address admin = msg.sender;

        ERC1155Drop drops = new ERC1155Drop(admin);

        drops.createDrop(
            DropType.Public,
            "ipfs://bafkreiepxqvixhkaqd4tr4uym6q6wyvxcwai7ethmhieompdnlrcldc6rm",
            abi.encode(0.01 ether, 100, 10)
        );

        vm.stopBroadcast();
    }
}

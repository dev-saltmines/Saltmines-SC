// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console } from "forge-std/console.sol";
import { ERC721Mock } from "../test/mocks/ERC721Mock.sol";
import { ERC1155Mock } from "../test/mocks/ERC1155Mock.sol";
import { BaseScript } from "./Base.s.sol";

contract NFTMockScript is BaseScript {
    function run() public broadcast {
        ERC721Mock erc721Mock = new ERC721Mock();
        ERC1155Mock erc1155Mock = new ERC1155Mock();

        console.logAddress(address(erc721Mock));
        console.logAddress(address(erc1155Mock));
    }
}

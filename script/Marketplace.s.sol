// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console } from "forge-std/console.sol";
import { Marketplace } from "../src/Marketplace.sol";
import { BaseScript } from "./Base.s.sol";

contract MarketplaceScript is BaseScript {
    function run() public broadcast {
        address owner = vm.envAddress("OWNER_ADDRESS");

        Marketplace marketplace = new Marketplace(owner);

        console.logAddress(address(marketplace));
    }
}

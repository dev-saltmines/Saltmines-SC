// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console } from "forge-std/console.sol";
import { ZMOContract } from "../src/ZMOContract.sol";
import { BaseScript } from "./Base.s.sol";

contract ZMOContractScript is BaseScript {
    function run() public broadcast {
        address owner = vm.envAddress("OWNER_ADDRESS");
        address moneyKeeper = vm.envAddress("MONEY_KEEPER_ADDRESS");

        ZMOContract zmoContract = new ZMOContract(owner, moneyKeeper);

        console.logAddress(address(zmoContract));
    }
}

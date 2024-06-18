// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Mock is ERC1155 {
    constructor() ERC1155("") { }

    function mint(uint256 id, uint256 value, bytes memory data) external {
        _mint(msg.sender, id, value, data);
    }

    function batchMint(uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external {
        _mintBatch(msg.sender, ids, values, data);
    }

    function burn(uint256 id, uint256 value) external {
        _burn(msg.sender, id, value);
    }

    function batchBurn(uint256[] calldata ids, uint256[] calldata values) external {
        _burnBatch(msg.sender, ids, values);
    }
}

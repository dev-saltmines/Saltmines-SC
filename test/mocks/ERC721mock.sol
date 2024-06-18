// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721 {
    constructor() ERC721("ERC721Mock", "ERC721") { }

    error UnauthorizedOwner(address _sender);

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }

    function burn(uint256 id) external {
        if (msg.sender != ownerOf(id)) {
            revert UnauthorizedOwner(msg.sender);
        }
        _burn(id);
    }
}

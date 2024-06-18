// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

struct OfferInfo {
    address nftAddress;
    uint256 nftId;
    uint256 amount;
    address buyer;
    address seller;
    uint256 offerAt;
    bool offerStatus;
}

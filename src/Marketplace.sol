// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract Marketplace is Ownable, IERC1155Receiver, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public feePercent = 0; // Fee percentage (initially 0%)
    uint256 public listingCounter;

    enum TokenType {
        ERC721,
        ERC1155
    }

    struct Listing {
        uint256 id;
        address seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount; // amount is 1 for ERC721 and >= 1 for ERC1155
        uint256 price;
        TokenType tokenType;
        uint256 listedTime;
    }

    mapping(uint256 => Listing) private listingsData; // listingID -> Listing (details)
    EnumerableSet.UintSet private activeListings; // listing IDs

    // events
    event Listed(
        uint256 listingId,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        TokenType tokenType
    );
    event Unlisted(uint256 listingId);
    event Purchased(uint256 listingId, address buyer, uint256 amount);
    event EmergencyWithdrawNativeToken(address owner, uint256 balance);

    // errors
    error InsufficientBalance();
    error InvalidAmount();
    error InvalidAddress();
    error TokenTypeIsNotSupported();
    error TokenIsNotListed();
    error NotAuthorized();
    error NotTheTokenOnwer();
    error NotEnoughTokens();
    error SizeMismatch();

    constructor(address _owner) Ownable(_owner) {}

    // modifier
    modifier onlyOwnerOrSeller(uint256 _listingId) {
        if (msg.sender != owner() && msg.sender != listingsData[_listingId].seller) {
            revert NotAuthorized();
        }
        _;
    }

    // main functions
    function listNFT(address _tokenAddress, uint256 _tokenId, uint256 _amount, uint256 _price) external {
        if (_tokenAddress == address(0)) {
            revert InvalidAddress();
        }
        if (_amount <= 0) {
            revert InvalidAmount();
        }

        address contractAddress = address(this);
        address msgSender = msg.sender;
        address tokenAddress = _tokenAddress;
        uint256 tokenId = _tokenId;
        uint256 amount = _amount;
        uint256 price = _price;

        TokenType tokenType = getTokenType(_tokenAddress);

        // check the types of the token
        if (tokenType == TokenType.ERC721) {
            if (IERC721(tokenAddress).ownerOf(tokenId) != msgSender) {
                revert NotTheTokenOnwer();
            }
        } else if (tokenType == TokenType.ERC1155) {
            if (IERC1155(tokenAddress).balanceOf(msgSender, tokenId) < amount) {
                revert InsufficientBalance();
            }
        }

        // update the states
        listingCounter++;
        listingsData[listingCounter] = Listing({
            id: listingCounter,
            seller: msgSender,
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            amount: amount,
            price: price,
            tokenType: tokenType,
            listedTime: block.timestamp
        });

        activeListings.add(listingCounter);

        // transfer the token from the user to the marketplace
        if (tokenType == TokenType.ERC721) {
            IERC721(tokenAddress).transferFrom(msgSender, contractAddress, tokenId);
        } else if (tokenType == TokenType.ERC1155) {
            IERC1155(tokenAddress).safeTransferFrom(msgSender, contractAddress, tokenId, amount, "");
        }

        emit Listed(listingCounter, msgSender, tokenAddress, tokenId, amount, price, tokenType);
    }

    function unlistNFT(uint256 _listingId) external onlyOwnerOrSeller(_listingId) {
        if (!activeListings.contains(_listingId)) {
            revert TokenIsNotListed();
        }

        address contractAddress = address(this);
        uint256 listingId = _listingId;
        Listing memory listing = listingsData[listingId];

        // update the states
        delete listingsData[listingId];
        activeListings.remove(listingId);

        // transfer the token from the marketplace to the user
        if (listing.tokenType == TokenType.ERC721) {
            IERC721(listing.tokenAddress).transferFrom(contractAddress, listing.seller, listing.tokenId);
        } else if (listing.tokenType == TokenType.ERC1155) {
            IERC1155(listing.tokenAddress).safeTransferFrom(
                contractAddress,
                listing.seller,
                listing.tokenId,
                listing.amount,
                ""
            );
        }

        emit Unlisted(listingId);
    }

    function buyERC721(uint256 _listingId, address _to) external payable {
        uint256 listingId = _listingId;
        address toAddress = _to;
        Listing memory listing = listingsData[listingId];

        if (!activeListings.contains(listingId)) {
            revert TokenIsNotListed();
        }
        if (listing.tokenType != TokenType.ERC721) {
            revert TokenTypeIsNotSupported();
        }
        if (msg.value < listing.price) {
            revert InsufficientBalance();
        }

        // calculate the fee
        uint256 fee = (msg.value * feePercent) / 100;
        uint256 sellerAmount = msg.value - fee;

        // update the states
        delete listingsData[listingId];
        activeListings.remove(listingId);

        // transfer the token from the marketplace to the user
        IERC721(listing.tokenAddress).transferFrom(address(this), toAddress, listing.tokenId);
        // transfer the Native Token to the seller
        payable(listing.seller).transfer(sellerAmount);

        emit Purchased(listingId, msg.sender, 1);
    }

    function buyERC1155(uint256 _listingId, uint256 _amountToken, address _to) external payable {
        uint256 listingId = _listingId;
        uint256 amount = _amountToken;
        address toAddress = _to;
        Listing memory listing = listingsData[listingId];

        if (listing.tokenType != TokenType.ERC1155) {
            revert TokenTypeIsNotSupported();
        }
        if (!activeListings.contains(listingId)) {
            revert TokenIsNotListed();
        }

        // Ensure the buyer has sent the correct amount of Ether
        uint256 totalPrice = listing.price * amount;
        if (msg.value < totalPrice) {
            revert InsufficientBalance();
        }

        // Ensure the amount is valid
        if (amount > listing.amount) {
            revert NotEnoughTokens();
        }

        uint256 fee = (msg.value * feePercent) / 100;
        uint256 sellerAmount = msg.value - fee;

        // Update the listing
        if (amount == listing.amount) {
            delete listingsData[listingId];
            activeListings.remove(listingId);
        } else {
            listingsData[listingId].amount -= amount;
        }

        // Transfer the ERC1155 tokens to the buyer
        IERC1155(listing.tokenAddress).safeTransferFrom(address(this), toAddress, listing.tokenId, amount, "");

        // Transfer the Ether to the seller
        payable(listing.seller).transfer(sellerAmount);

        emit Purchased(listingId, msg.sender, amount);
    }

    function buyERC1155Batch(
        uint256[] calldata _listingIds,
        uint256[] calldata _amounts,
        address _to
    ) external payable {
        if (_listingIds.length != _amounts.length) {
            revert SizeMismatch();
        }

        uint256 totalCost = 0;
        uint256 numListingsLength = _listingIds.length;

        // Arrays to hold the data for batch transfers
        address[] memory tokenAddresses = new address[](numListingsLength);
        address[] memory sellers = new address[](numListingsLength);
        uint256[] memory tokenIds = new uint256[](numListingsLength);
        uint256[] memory prices = new uint256[](numListingsLength);

        // Calculate total cost and prepare data for transfers
        for (uint256 i = 0; i < numListingsLength; i++) {
            uint256 listingId = _listingIds[i];
            uint256 amount = _amounts[i];
            Listing memory listing = listingsData[listingId];

            if (listing.tokenType != TokenType.ERC1155) {
                revert TokenTypeIsNotSupported();
            }
            if (!activeListings.contains(listingId)) {
                revert TokenIsNotListed();
            }
            if (amount > listing.amount) {
                revert NotEnoughTokens();
            }

            uint256 totalPrice = listing.price * amount;
            totalCost += totalPrice;

            tokenAddresses[i] = listing.tokenAddress;
            sellers[i] = listing.seller;
            tokenIds[i] = listing.tokenId;
            prices[i] = listing.price;

            // Update the listing
            if (amount == listing.amount) {
                delete listingsData[listingId];
                activeListings.remove(listingId);
            } else {
                listingsData[listingId].amount -= amount;
            }

            emit Purchased(listingId, msg.sender, amount);
        }

        if (msg.value < totalCost) {
            revert InsufficientBalance();
        }

        // transfer the tokens in batches by token address
        for (uint256 i = 0; i < numListingsLength; i++) {
            IERC1155(tokenAddresses[i]).safeBatchTransferFrom(
                address(this),
                _to,
                asSingletonArray(tokenIds[i]),
                asSingletonArray(_amounts[i]),
                ""
            );
        }

        // distribute the Native Token to each seller
        for (uint256 i = 0; i < numListingsLength; i++) {
            uint256 totalPrice = prices[i] * _amounts[i];
            uint256 fee = (totalPrice * feePercent) / 100;
            uint256 sellerAmount = totalPrice - fee;
            payable(sellers[i]).transfer(sellerAmount);
        }

        // refund any excess Native Token sent
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    // helper function to create an array with a single element
    function asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    // utils
    // setters
    function setFeePercent(uint256 _feePercent) external onlyOwner {
        feePercent = _feePercent;
    }
    // getters
    function getTokenType(address _tokenAddress) internal view returns (TokenType) {
        if (IERC165(_tokenAddress).supportsInterface(type(IERC721).interfaceId)) {
            return TokenType.ERC721;
        } else if (IERC165(_tokenAddress).supportsInterface(type(IERC1155).interfaceId)) {
            return TokenType.ERC1155;
        } else {
            revert TokenTypeIsNotSupported();
        }
    }

    function getActiveListingsLength() external view returns (uint256) {
        return activeListings.length();
    }

    function getActiveListings() external view returns (uint256[] memory) {
        return activeListings.values();
    }

    function getListing(uint256 _listingId) external view returns (Listing memory) {
        return listingsData[_listingId];
    }

    function isContains(uint256 _listingId) external view returns (bool) {
        return activeListings.contains(_listingId);
    }

    // Required functions to accept ERC1155 tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    // emergency functions
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdrawNativeToken(address _owner) external onlyOwner whenPaused {
        uint256 balance = address(this).balance;
        payable(_owner).transfer(balance);

        emit EmergencyWithdrawNativeToken(_owner, balance);
    }

    receive() external payable {
        if (msg.value <= 0) {
            revert InvalidAmount();
        }
    }
}

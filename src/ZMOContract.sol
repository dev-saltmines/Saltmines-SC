// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { IZMOContract } from "./interfaces/IZMOContract.sol";
import { OfferInfo } from "./types/ZMOContractType.sol";

contract ZMOContract is Ownable, ReentrancyGuard, Pausable, IZMOContract{
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // mul * 10000
    // for example 0.05% = 0.0005 = > 5
    uint256 public feeOffer;
    // mul * 10000
    // for example 0.05% = 0.0005 => 5
    uint256 public feeSuccess;
    address public moneyKeeper;
    uint256 public timeExpire;
    uint256 public currentOfferId;

    mapping(uint256 offerId => OfferInfo offerInfo) public offers;
    mapping(address buyer => uint256[] offerIds) public offerIds;
    mapping(address user => uint256 amount) public userBalance;

    receive() external payable { }

    constructor(address _initialOwner, address _moneyKeeper) Ownable(_initialOwner) {
        moneyKeeper = _moneyKeeper;
        timeExpire = 28 hours;
        feeOffer = 0;
        feeSuccess = 0;
    }

    function deposit() external payable whenNotPaused nonReentrant onlyUser{
        uint256 amount = msg.value;
        if (amount <= 0) {
            revert InvalidAmount(0);
        }

        userBalance[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    function createOffer(
        address _nftAddress,
        uint256 _nftId,
        address _seller,
        uint256 _amount
    )
        external
        whenNotPaused
        nonReentrant
        onlyUser
    {
        address sender = msg.sender;
        if (_amount <= 0) {
            revert InvalidAmount(_amount);
        }

        if (userBalance[sender] < _amount) {
            revert InvalidAmountBalance(_amount);
        }
        uint256 feeOfferValue = _calculateFee(feeOffer, _amount);

        uint256 amount = _amount - feeOfferValue;

        OfferInfo memory newOffer = OfferInfo({
            nftAddress: _nftAddress,
            nftId: _nftId,
            amount: amount,
            buyer: sender,
            seller: _seller,
            offerAt: block.timestamp,
            offerStatus: false
        });

        ++currentOfferId;
        offers[currentOfferId] = newOffer;
        offerIds[sender].push(currentOfferId);

        userBalance[sender] -= _amount;
        userBalance[moneyKeeper] += feeOfferValue;

        emit CreateOffer(currentOfferId, newOffer);
    }

    function updateOffer(uint256 _offerId, uint256 _amount) external whenNotPaused nonReentrant onlyUser{
        address sender = msg.sender;
        uint256 feeOfferValue = _calculateFee(feeOffer, _amount);
        uint256 amount = _amount - feeOfferValue;
        OfferInfo storage offer = offers[_offerId];

        if (_amount <= 0 || amount <= offer.amount) {
            revert InvalidAmount(_amount);
        }

        if (_offerId <= 0 || _offerId > currentOfferId) {
            revert InvalidOfferId(_offerId);
        }

        if (offer.buyer != sender) {
            revert InvalidBuyer(sender);
        }

        if (offer.offerStatus || (offer.offerStatus == false && offer.offerAt + timeExpire < block.timestamp)) {
            revert InvalidOffer();
        }

        userBalance[sender] += offer.amount;

        if (userBalance[sender] < _amount) {
            revert InvalidAmountBalance(_amount);
        }

        offer.amount = amount;
        offer.offerAt = block.timestamp;
        offer.offerStatus = false;
        userBalance[sender] -= amount;
        userBalance[moneyKeeper] += feeOfferValue;

        emit UpdateOffer(_offerId, offer);
    }

    function acceptOffer(uint256 _offerId) external whenNotPaused nonReentrant onlyUser{
        address sender = msg.sender;

        if (_offerId <= 0 || _offerId > currentOfferId) {
            revert InvalidOfferId(_offerId);
        }

        OfferInfo storage offerInfo = offers[_offerId];

        if (offerInfo.offerStatus) {
            revert InvalidOffer();
        }

        if (offerInfo.offerAt + timeExpire < block.timestamp) {
            revert ExpiredOffer();
        }

        if (offerInfo.seller != sender) {
            revert InvalidSeller(sender);
        }

        if (offerInfo.amount <= 0 || address(this).balance < offerInfo.amount) {
            revert InvalidAmount(offerInfo.amount);
        }

        uint256 feeSuccessValue = _calculateFee(feeSuccess, offerInfo.amount);
        uint256 amount = offerInfo.amount - feeSuccessValue;

        offerInfo.offerStatus = true;
        userBalance[moneyKeeper] += feeSuccessValue;
        userBalance[sender] += amount;

        bool isERC721 = _isERC721(offerInfo.nftAddress);
        bool isERC1155 = _isERC1155(offerInfo.nftAddress);
        bool isERC165 = _isERC165(offerInfo.nftAddress);

        if(!isERC165){
            revert InvalidNft(offerInfo.nftAddress); 
        }

        if (isERC721) {
            if (IERC721(offerInfo.nftAddress).ownerOf(offerInfo.nftId) != sender) {
                revert UnauthorizedOwner(sender);
            }

            IERC721(offerInfo.nftAddress).safeTransferFrom(sender, offerInfo.buyer, offerInfo.nftId);
        } else if (isERC1155) {
            if (IERC1155(offerInfo.nftAddress).balanceOf(sender, offerInfo.nftId) == 0) {
                revert InsufficientBalance(0);
            }

            IERC1155(offerInfo.nftAddress).safeTransferFrom(sender, offerInfo.buyer, offerInfo.nftId, 1, "");
        } else {
            revert InvalidNft(offerInfo.nftAddress);
        }

        emit AcceptOffer(_offerId, offerInfo);
    }

    function getAvailableBalance(address sender) external view returns (uint256) {
        return _getAvailableBalance(sender);
    }

    function withdraw(uint256 _amount) external whenNotPaused nonReentrant onlyUser{
        address sender = msg.sender;
        if (_amount <= 0) {
            revert InvalidAmount(_amount);
        }

        uint256 availableAmount = _getAvailableBalance(sender);

        if (_amount > address(this).balance || _amount > availableAmount) {
            revert InsufficientBalance(_amount);
        }

        userBalance[sender] = availableAmount - _amount;

        payable(sender).transfer(_amount);

        emit Withdraw(sender, _amount);
    }

    function _getAvailableBalance(address _sender) internal view returns (uint256) {
        uint256 amount = userBalance[_sender];
        uint256 length = offerIds[_sender].length;
        for (uint256 i; i < length;) {
            OfferInfo memory offerInfo = offers[offerIds[_sender][i]];
            if (_sender != offerInfo.buyer) {
                revert InvalidBuyer(_sender);
            }

            if (offerInfo.offerStatus == false && offerInfo.offerAt + timeExpire < block.timestamp) {
                amount += offerInfo.amount;
            }

            unchecked {
                ++i;
            }
        }
        return amount;
    }

    function setMoneyKeeper(address _moneyKeeper) external onlyOwner {
        moneyKeeper = _moneyKeeper;
    }

    function setTimeExpire(uint256 _expire) external onlyOwner {
        timeExpire = _expire;
    }

    function setFeeOffer(uint256 _feeOffer) external onlyOwner {
        feeOffer = _feeOffer;
    }

    function setFeeSuccess(uint256 _feeSuccess) external onlyOwner {
        feeSuccess = _feeSuccess;
    }

    function getOffer(uint256 _offerId) external view returns (OfferInfo memory) {
        if (_offerId <= 0 || _offerId > currentOfferId) {
            revert InvalidOfferId(_offerId);
        }
        return offers[_offerId];
    }

    function _isERC165(address _nftAddress) internal view returns (bool){
        return ERC165Checker.supportsERC165(_nftAddress);
    }

    function _isERC721(address _nftAddress) internal view returns (bool) {
        return ERC165Checker.supportsInterface(_nftAddress, _INTERFACE_ID_ERC721);
    }

    function _isERC1155(address _nftAddress) internal view returns (bool) {
        return ERC165Checker.supportsInterface(_nftAddress, _INTERFACE_ID_ERC1155);
    }

    function _calculateFee(uint256 _fee, uint256 _amount) internal pure returns (uint256) {
        return (_amount * _fee) / 10_000;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyUser() {
        _checkUser();
        _;
    }

    function _checkUser() internal view virtual {
        if (address(0) == _msgSender()) {
            revert InvalidUser(_msgSender());
        }
    }
}

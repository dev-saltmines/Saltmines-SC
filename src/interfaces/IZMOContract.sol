// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { OfferInfo } from "../types/ZMOContractType.sol";

interface IZMOContract {
    // event list
    event Deposit(address indexed _sender, uint256 indexed _amount);
    event Withdraw(address indexed _sender, uint256 indexed _amount);
    event CreateOffer(uint256 indexed _offerId, OfferInfo _offerInfo);
    event UpdateOffer(uint256 indexed _offerId, OfferInfo _offerInfo);
    event AcceptOffer(uint256 indexed _offerId, OfferInfo _offerInfo);
    event ClaimNft(uint256 indexed _offerId, OfferInfo _offerInfo);

    // error list
    error InvalidAmount(uint256 _amount);
    error InvalidAmountBalance(uint256 _amount);
    error FailedTransaction();
    error InvalidOfferId(uint256 _offerId);
    error InvalidBuyer(address _sender);
    error InvalidOffer();
    error InvalidSeller(address _sender);
    error UnauthorizedOwner(address _sender);
    error InsufficientBalance(uint256 _amount);
    error InvalidNft(address _nftAddress);
    error ExpiredOffer();
    error InvalidUser(address _user);

    /**
     * @notice Deposit native token.
     *
     * @dev Will transfer token to ZMOContract.
     * @dev Emit a {Deposit} event.
     *
     * Requirements:
     *   - Require sender's balance more than amount send to contract.
     */
    function deposit() external payable;

    /**
     * @notice Create new offer.
     *
     * @dev Emit a {CreateOffer} event.
     *
     * @param _nftAddres Address of nft.
     * @param _nftId Id of nft.
     * @param _seller Address of seller.
     * @param _amount amount that buyer buy nft.
     */
    function createOffer(address _nftAddres, uint256 _nftId, address _seller, uint256 _amount) external;

    /**
     * @notice Update exist offer.
     *
     * @dev Emit a {UpdateOffer} event.
     *
     * @param _offerId Id of offer.
     * @param _amount amount that buyer buy nft.
     */
    function updateOffer(uint256 _offerId, uint256 _amount) external;

    /**
     * @notice Accept exist offer.
     *
     * @dev Emit a {AcceptOffer} event.
     *
     * @param _offerId Id of offer.
     */
    function acceptOffer(uint256 _offerId) external;

    /**
     * @notice Get available balance buyer that can be withdraw.
     */
    function getAvailableBalance(address _sender) external returns (uint256);

    /**
     * @notice Withdraw user's balance in contract.
     *
     * @dev Emit a {Withdraw} event.
     *
     * @param _amount Amount that user want to withdraw.
     */
    function withdraw(uint256 _amount) external;

    /**
     * @notice Set Keeper's address that keep fees money.
     *
     * @param _moneyKeeper Address of keeper.
     */
    function setMoneyKeeper(address _moneyKeeper) external;

    /**
     * @notice Set time expire of offer.
     *
     * Requirements:
     *  - Just only owner call this function.
     *
     * @param _expire Time expire.
     */
    function setTimeExpire(uint256 _expire) external;

    /**
     * @notice Set fee when offer success created.
     *
     * Requirements:
     *  - Just only owner call this function.
     *
     * @param _feeOffer Amount that fee of offer when created.
     */
    function setFeeOffer(uint256 _feeOffer) external;

    /**
     * @notice Set fee when offer success accepted.
     *
     * Requirements:
     *  - Just only owner call this function.
     *
     * @param _feeSuccess Amount that fee of offer when accepted.
     */
    function setFeeSuccess(uint256 _feeSuccess) external;

    /**
     * @notice Get exist offer.
     *
     * @param _offerId Id of Offer.
     */
    function getOffer(uint256 _offerId) external returns (OfferInfo memory);

    /**
     * @notice Pause that function have pause flag.
     *
     * Requirements:
     *  - Just only owner call this function.
     */
    function pause() external;

    /**
     * @notice Unpause that function have paused.
     *
     * Requirements:
     *  - Just only owner call this function.
     */
    function unpause() external;
}

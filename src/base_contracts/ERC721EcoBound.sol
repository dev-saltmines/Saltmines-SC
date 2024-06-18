// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ERC721EcoBound
 * @dev Extends the ERC721 token standard by adding functionalities that bind the token to a specific ecosystem.
 *      This contract includes features such as restricted transfers, burnability, reentrancy protection,
 *      royalty distribution, and administrative control. It's suitable for scenarios requiring a controlled
 *      environment, such as tokens with environmental impacts or in contexts where only authorized entities
 *      can transfer or burn tokens.
 */
contract ERC721EcoBound is ERC721Royalty, AccessControl, ReentrancyGuard, ERC721Burnable {
    
    bytes32 public constant ROYALTY_MANAGER_ROLE = keccak256("ROYALTY_MANAGER_ROLE");
    bytes32 public constant APPROVED_CONTRACT_ROLE = keccak256("APPROVED_CONTRACT_ROLE");

    string private baseURI;

    /**
     * @dev Constructor sets the token metadata, roles, and initial royalty configuration.
     * @param name Name of the ERC721 token.
     * @param symbol Symbol of the ERC721 token.
     * @param _baseURI_ Base URI for token metadata.
     * @param adminAddress Address with admin privileges to manage the contract.
     * @param royaltyManagerAddress Address responsible for managing royalty settings.
     * @param royaltyRecipient Address of the initial recipient of royalties.
     * @param royaltyFraction Numerator for royalty percentage expressed in basis points.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI_,
        address adminAddress,
        address royaltyManagerAddress,
        address royaltyRecipient,
        uint96 royaltyFraction
    )
        ERC721(name, symbol)
    {
        require(adminAddress != address(0), "Admin address cannot be the zero address");
        require(royaltyManagerAddress != address(0), "Royalty manager address cannot be the zero address");
        require(royaltyRecipient != address(0), "Royalty recipient address cannot be the zero address");

        baseURI = _baseURI_;

        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _grantRole(ROYALTY_MANAGER_ROLE, royaltyManagerAddress);

        _setDefaultRoyalty(royaltyRecipient, royaltyFraction);
    }


    /**
     * @dev Updates the royalty configuration by the royalty manager.
     * @param recipient New recipient of royalties.
     * @param feeNumerator New royalty percentage expressed in basis points.
     */
    function updateRoyaltyInfo(address recipient, uint96 feeNumerator) public onlyRole(ROYALTY_MANAGER_ROLE) {
        _setDefaultRoyalty(recipient, feeNumerator);
    }


    /**
     * @dev Grants a contract the ability to transfer and burn tokens.
     * @param contractAddress Address of the contract to be approved.
     */
    function addApprovedContract(address contractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(APPROVED_CONTRACT_ROLE, contractAddress);
    }


    /**
     * @dev Revokes a contract's ability to transfer and burn tokens.
     * @param contractAddress Address of the contract to be revoked.
     */
    function removeApprovedContract(address contractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(APPROVED_CONTRACT_ROLE, contractAddress);
    }


    /**
     * @dev Restricts `transferFrom` to only approved contracts.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(hasRole(APPROVED_CONTRACT_ROLE, _msgSender()), "Caller is not approved to transfer");
        super.transferFrom(from, to, tokenId);
    }


    /**
     * @dev Restricts `safeTransferFrom` to only approved contracts.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(hasRole(APPROVED_CONTRACT_ROLE, _msgSender()), "Caller is not approved to transfer");
        super.safeTransferFrom(from, to, tokenId, _data);
    }


    /**
     * @dev Restricts `approve` to addresses with the approved contract role.
     */
    function approve(address to, uint256 tokenId) public override {
        require(hasRole(APPROVED_CONTRACT_ROLE, to), "ERC721EcoBound: approve to caller that is not approved contract");
        super.approve(to, tokenId);
    }


    /**
     * @dev Restricts `setApprovalForAll` to operators with the approved contract role.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(hasRole(APPROVED_CONTRACT_ROLE, operator), "ERC721EcoBound: Operator does not have approved contract role");
        super.setApprovalForAll(operator, approved);
    }


    /**
     * @dev Allows burning of tokens by approved contracts only.
     */
    function burn(uint256 tokenId) public override {
        require(hasRole(APPROVED_CONTRACT_ROLE, msg.sender), "ERC721EcoBound: Operator does not have approved contract role");
        super.burn(tokenId);
    }


    /**
     * @dev Ensures support for ERC721, ERC721Royalty, and AccessControl interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalty, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /**
     * @dev Provides a uniform URI for all tokens, ignoring the tokenId.
     */
    function tokenURI(uint256 /* tokenId*/ ) public view override returns (string memory) {
        return _baseURI();
    }


    /**
     * @dev Returns the base URI set during construction and used for all token URIs.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}

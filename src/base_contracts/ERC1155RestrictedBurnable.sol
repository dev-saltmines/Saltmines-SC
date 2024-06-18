// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ERC1155RestrictedBurnable
 * @dev Extends the ERC1155 token standard by adding functionalities for burnability, supply tracking, metadata URI storage,
 *      and royalty management via ERC2981. It also includes reentrancy protection and access-controlled administrative functions.
 *      This contract is suitable for situations where only certain contracts can burn or transfer tokens, such as in gaming or
 *      limited edition digital assets.
 */
contract ERC1155RestrictedBurnable is AccessControl, ReentrancyGuard, ERC1155Burnable, ERC1155Supply, ERC1155URIStorage, ERC2981  {
    using Strings for uint256;

    bytes32 public constant ROYALTY_MANAGER_ROLE = keccak256("ROYALTY_MANAGER_ROLE");
    bytes32 public constant APPROVED_CONTRACT_ROLE = keccak256("APPROVED_CONTRACT_ROLE");

    string public name;
    string public symbol;

    string private _baseURI;
    uint8 private _modificationChances;
    bool private _modificationsDisabled;

    /**
     * @dev Initializes the contract by setting up roles, royalty information, and metadata URIs.
     * @param _name Display name of the token collection.
     * @param _symbol Abbreviated symbol of the token collection.
     * @param _baseURI_ URI prefix for all token metadata.
     * @param admin Address with the default admin role, capable of administrative functions.
     * @param royaltyManager Address with the royalty manager role, authorized to update royalty settings.
     * @param royaltyRecipient Initial recipient of royalties.
     * @param royaltyFraction Royalty rate expressed in basis points.
     * @param _modificationChances_ Maximum number of times the base URI can be modified.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI_,
        address admin,
        address royaltyManager,
        address royaltyRecipient,
        uint96 royaltyFraction,
        uint8 _modificationChances_
    ) ERC1155(_baseURI_) {
        require(admin != address(0), "Admin address cannot be the zero address");
        require(royaltyManager != address(0), "Royalty manager address cannot be the zero address");
        require(royaltyRecipient != address(0), "Royalty recipient address cannot be the zero address");

        name = _name;
        symbol = _symbol;
        _baseURI = _baseURI_;
        _modificationChances = _modificationChances_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ROYALTY_MANAGER_ROLE, royaltyManager);

        _setDefaultRoyalty(royaltyRecipient, royaltyFraction);
    }


    /**
     * @dev Approves a contract to burn or transfer tokens.
     * @param contractAddress Address of the contract to be approved.
     */
    function addApprovedContract(address contractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(APPROVED_CONTRACT_ROLE, contractAddress);
    }

    /**
     * @dev Revokes a previously granted approval for a contract to burn or transfer tokens.
     * @param contractAddress Address of the contract to have its approval revoked.
     */
    function removeApprovedContract(address contractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(APPROVED_CONTRACT_ROLE, contractAddress);
    }

    /**
     * @dev Sets the default royalty information for all tokens in the collection.
     * @param recipient Address that will receive the royalties.
     * @param feeNumerator Royalty rate, denoted in basis points.
     */
    function setDefaultRoyaltyInfo(address recipient, uint96 feeNumerator) public onlyRole(ROYALTY_MANAGER_ROLE) {
        _setDefaultRoyalty(recipient, feeNumerator);
    }

    /**
     * @dev Returns the URI for a given token ID, dynamically generating it by concatenating the base URI with the token ID.
     * @param id Token ID to generate the metadata URI for.
     */
    function uri(uint256 id) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return string(abi.encodePacked(_baseURI, id.toString()));
    }

    /**
     * @dev Modifies the base URI for token metadata if modifications are still allowed.
     * @param newBaseURI New base URI to be used for all tokens.
     */
    function modifyBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_modificationsDisabled, "Modifications have been permanently disabled.");
        require(_modificationChances > 0, "No modification chances left.");

        _baseURI = newBaseURI;
        _modificationChances--;
    }

    /**
     * @dev Permanently disables modifications to the base URI and other modifiable aspects of the contract.
     */
    function disableModifications() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _modificationsDisabled = true;
    }

    /**
     * @dev Provides royalty information for a specific token sale.
     * @param tokenId Token ID for which to provide royalty details.
     * @param salePrice Sale price of the token.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address recipient, uint256 royaltyAmount)
    {
        return super.royaltyInfo(tokenId, salePrice);
    }

    /**
     * @dev Supports multiple interfaces including ERC1155, ERC2981, and AccessControl for comprehensive functionality.
     * @param interfaceId ID of the interface to check.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /**
     * @dev Allows approved contracts to burn tokens, ensuring only authorized entities can execute burns.
     * @param account Token owner's account.
     * @param id ID of the token to be burned.
     * @param value Amount of the token to be burned.
     */
    function burn(address account, uint256 id, uint256 value) public override onlyRole(APPROVED_CONTRACT_ROLE) {
        super.burn(account, id, value);
    }

    /**
     * @dev Allows approved contracts to perform batch burns, facilitating efficient management of multiple tokens.
     * @param account Token owner's account.
     * @param ids Array of token IDs to be burned.
     * @param values Array of token amounts to be burned.
     */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public override onlyRole(APPROVED_CONTRACT_ROLE) {
        super.burnBatch(account, ids, values);
    }

    /**
     * @dev Internal function to handle updates post token transfer, minting, or burning operations.
     * @param from Address sending the tokens.
     * @param to Address receiving the tokens.
     * @param ids Array of token IDs being transferred.
     * @param values Array of token quantities being transferred.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
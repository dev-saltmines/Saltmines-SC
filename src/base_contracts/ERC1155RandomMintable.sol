// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC1155RestrictedBurnable.sol";
import "../interfaces/IRandomNumberGenerator.sol";

/**
 * @title ERC1155RandomMintable
 * @dev Extends ERC1155RestrictedBurnable with random token minting capabilities.
 *      This contract allows for tokens with different rarities and serial numbers to be randomly minted.
 *      It employs an external random number generator to ensure the randomness of token selection.
 *      Token data such as rarity and serial number are stored and managed within this contract.
 */
contract ERC1155RandomMintable is ERC1155RestrictedBurnable {
    using EnumerableSet for EnumerableSet.UintSet;

    enum Rarity {
        Common,
        Rare,
        Epic,
        Legendary
    }

    struct TokenData {
        Rarity rarity;
        string serialNumber;
    }

    uint256 public maxSupply;
    uint256 public currentSupply;
    bool public supplyFullyProvided;

    mapping(uint256 => TokenData) public tokenData;

    uint256 private nonce;
    EnumerableSet.UintSet private availableTokenIds;

    IRandomNumberGenerator private randomNumberGenerator;

    event TokenMinted(
        address indexed to,
        uint256 indexed tokenId,
        Rarity rarity,
        string serialNumber
    );

    /**
     * @dev Constructor that sets up the random mintable ERC1155 token.
     * @param _name Name of the token collection.
     * @param _symbol Symbol of the token collection.
     * @param _baseUri Base URI for the ERC1155 token.
     * @param _admin Address with admin privileges.
     * @param _randomNumberGeneratorAddress Address of the random number generator contract.
     * @param _royaltyManager Address with royalty management privileges.
     * @param _royaltyRecipient Address to receive royalties.
     * @param _royaltyFraction Royalty rate in basis points.
     * @param _modificationChances Number of allowable URI modifications.
     * @param _initialNonce Initial nonce for random number generation.
     * @param _maxSupply Maximum supply of tokens.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _admin,
        address _randomNumberGeneratorAddress,
        address _royaltyManager,
        address _royaltyRecipient,
        uint96 _royaltyFraction,
        uint8 _modificationChances,
        uint256 _initialNonce,
        uint256 _maxSupply
    )
    ERC1155RestrictedBurnable(
    _name,
    _symbol,
    _baseUri,
    _admin,
    _royaltyManager,
    _royaltyRecipient,
    _royaltyFraction,
    _modificationChances
    )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        randomNumberGenerator = IRandomNumberGenerator(_randomNumberGeneratorAddress);
        nonce = _initialNonce;
        maxSupply = _maxSupply;
        supplyFullyProvided = false;
    }

    /**
     * @dev Provides the initial supply of token IDs, rarities, and serial numbers. This function must be called to populate
     * the contract with initial token data before any minting can occur.
     * @param tokenIds Array of token IDs to be added.
     * @param rarities Array of rarities corresponding to the token IDs.
     * @param serialNumbers Array of serial numbers corresponding to the token IDs.
     */
    function provideInitialSupply(uint256[] calldata tokenIds, Rarity[] calldata rarities, string[] calldata serialNumbers) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenIds.length == rarities.length && tokenIds.length == serialNumbers.length, "Mismatch in array lengths");
        require(currentSupply + tokenIds.length <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            availableTokenIds.add(tokenIds[i]);
            tokenData[tokenIds[i]] = TokenData({
                rarity: rarities[i],
                serialNumber: serialNumbers[i]
            });
        }

        currentSupply += tokenIds.length;

        if (currentSupply == maxSupply) {
            supplyFullyProvided = true;
        }
    }

    /**
     * @dev Mints a random token to a specified address. The function selects a token ID at random from availableTokenIds,
     *      mints the token, and then emits a TokenMinted event.
     * @param to Address to mint the token to.
     */
    function mintRandomToken(address to) public onlyRole(APPROVED_CONTRACT_ROLE) {
        require(supplyFullyProvided, "Supply has not been fully provided yet");
        require(availableTokenIds.length() > 0, "No available token IDs");

        uint256 index = randomNumberGenerator.generateRandomNumberWithLimit(nonce, availableTokenIds.length());
        nonce++;

        uint256 tokenId = availableTokenIds.at(index);
        availableTokenIds.remove(tokenId);

        TokenData storage data = tokenData[tokenId];

        _mint(to, tokenId, 1, "");
        emit TokenMinted(to, tokenId, data.rarity, data.serialNumber);
    }
}
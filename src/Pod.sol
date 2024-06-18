// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


import "./base_contracts/ERC721EcoBound.sol";

/**
 * @title Pod Contract
 * @dev This contract extends ERC721EcoBound, adding specialized features for Pod ecosystem operations. It integrates
 *      financial management capabilities and enforces limitations on mint transactions, including a sales start timestamp
 *      to adapt to specific use cases. The contract facilitates regulated token minting, financial management, and controlled
 *      sales timing within its ecosystem.
 */
contract Pod is ERC721EcoBound  {
    
    bytes32 public constant FINANCE_MANAGER_ROLE = keccak256("FINANCE_MANAGER_ROLE");

    struct ContractConfig {
        string name;
        string symbol;
        string baseURI;
        address adminAddress;
        address royaltyManagerAddress;
        address financeManagerAddress;
        address royaltyRecipient;
        uint96 royaltyFraction;
    }

    struct SaleConfig {
        uint256 purchasePrice;
        uint256 maxPodsPerTx;
        uint256 maxSupply;
        uint256 salesStartTimestamp;
        uint256 regularOpeningTimeStamp;
        uint256 prematureOpeningTimeStamp;
        bool isMystery;
    }

    uint256 public pricePerPod; 
    uint256 public maxPodsPerPurchaseTx;
    uint256 public maxSupply;
    uint256 public salesStartTimestamp;
    uint256 public regularOpeningTimeStamp;
    uint256 public prematureOpeningTimeStamp;
    bool public isMystery;
    bool public isSoldOut;

    address private _financeManagerAddress;
    uint256 private _totalPods;

    event PodsPurchased(address indexed buyer, uint256 numberOfPods, uint256[] podIds);
    event SoldOut();

    /**
     * @dev Initializes the Pod contract with ERC721EcoBound settings and specific configurations for Pod sales and management.
     * @param contractConfig Struct containing initial settings for contract metadata and administrative roles.
     * @param saleConfig Struct containing sales-related settings including pricing, supply limits, and sales timing.
     */
    constructor(ContractConfig memory contractConfig, SaleConfig memory saleConfig)
        ERC721EcoBound(contractConfig.name, contractConfig.symbol, contractConfig.baseURI,
        contractConfig.adminAddress, contractConfig.royaltyManagerAddress, contractConfig.royaltyRecipient, contractConfig.royaltyFraction)
    {
        pricePerPod = saleConfig.purchasePrice;
        maxPodsPerPurchaseTx = saleConfig.maxPodsPerTx;
        maxSupply = saleConfig.maxSupply;
        salesStartTimestamp = saleConfig.salesStartTimestamp;
        regularOpeningTimeStamp = saleConfig.regularOpeningTimeStamp;
        prematureOpeningTimeStamp = saleConfig.prematureOpeningTimeStamp;
        isMystery = saleConfig.isMystery;

        _financeManagerAddress = contractConfig.financeManagerAddress;
        _grantRole(FINANCE_MANAGER_ROLE, _financeManagerAddress);
    }

    /**
     * @dev Facilitates the minting of Pods based on the specified quantity. Ensures compliance with transaction, supply limits,
     * and sales start timing.
     * @param numberOfTokens The quantity of Pods to mint.
     */
    function buyPod(uint256 numberOfTokens) public payable nonReentrant {
        require(block.timestamp >= salesStartTimestamp, "Pod sales have not started yet");
        require(numberOfTokens <= maxPodsPerPurchaseTx, "Max mints per transaction exceeded");
        require(_totalPods + numberOfTokens <= maxSupply, "Purchase would exceed max supply of NFTs");
        require(pricePerPod * numberOfTokens <= msg.value, "Ether value sent is not correct");


        uint256[] memory mintedPodIds = new uint256[](numberOfTokens);

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _totalPods + 1;
            if (mintIndex <= maxSupply) {
                _safeMint(msg.sender, mintIndex);
                mintedPodIds[i] = mintIndex;
                _totalPods++;
            }
        }

        if (_totalPods >= maxSupply) {
            isSoldOut = true;
            emit SoldOut();
        }

        emit PodsPurchased(msg.sender, numberOfTokens, mintedPodIds);
    }

    /**
     * @dev Allows the finance manager to withdraw the collected funds from Pod sales.
     */
    function transferFundsToFinanceManager() public onlyRole(FINANCE_MANAGER_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = _financeManagerAddress.call{value: balance}("");
        require(success, "Transfer failed.");
    }


    /**
     * @dev Updates the finance manager's address, allowing for changes in financial control.
     * @param newFinanceManager The new address to be assigned the finance manager role.
     */
    function setFinanceManagerAddress(address newFinanceManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFinanceManager != address(0), "Invalid address: cannot be the zero address");
        _revokeRole(FINANCE_MANAGER_ROLE, _financeManagerAddress);
        _financeManagerAddress = newFinanceManager;
        _grantRole(FINANCE_MANAGER_ROLE, newFinanceManager);
    }

}

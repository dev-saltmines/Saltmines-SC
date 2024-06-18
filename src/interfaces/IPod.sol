// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPod {
  function APPROVED_CONTRACT_ROLE (  ) external view returns ( bytes32 );
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function FINANCE_MANAGER_ROLE (  ) external view returns ( bytes32 );
  function ROYALTY_MANAGER_ROLE (  ) external view returns ( bytes32 );
  function addApprovedContract ( address contractAddress ) external;
  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function burn ( uint256 tokenId ) external;
  function buyPod ( uint256 numberOfTokens ) external;
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function isMystery (  ) external view returns ( bool );
  function isSoldOut (  ) external view returns ( bool );
  function maxPodsPerPurchaseTx (  ) external view returns ( uint256 );
  function maxSupply (  ) external view returns ( uint256 );
  function name (  ) external view returns ( string memory);
  function regularOpeningTimeStamp (  ) external view returns ( uint256 );
  function prematureOpeningTimeStamp (  ) external view returns ( uint256 );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function pricePerPod (  ) external view returns ( uint256 );
  function removeApprovedContract ( address contractAddress ) external;
  function renounceRole ( bytes32 role, address callerConfirmation ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function royaltyInfo ( uint256 tokenId, uint256 salePrice ) external view returns ( address, uint256 );
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setFinanceManagerAddress ( address newFinanceManager ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory);
  function tokenURI ( uint256 tokenId ) external view returns ( string memory);
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferFundsToFinanceManager (  ) external;
  function updateRoyaltyInfo ( address recipient, uint96 feeNumerator ) external;
}

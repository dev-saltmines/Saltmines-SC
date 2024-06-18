// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IERC1155RandomMintable {
  function APPROVED_CONTRACT_ROLE (  ) external view returns ( bytes32 );
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function ROYALTY_MANAGER_ROLE (  ) external view returns ( bytes32 );
  function addApprovedContract ( address contractAddress ) external;
  function balanceOf ( address account, uint256 id ) external view returns ( uint256 );
  function balanceOfBatch ( address[] memory accounts, uint256[] memory ids ) external view returns ( uint256[] memory);
  function burn ( address account, uint256 id, uint256 value ) external;
  function burnBatch ( address account, uint256[] memory ids, uint256[] memory values ) external;
  function currentSupply (  ) external view returns ( uint256 );
  function exists ( uint256 id ) external view returns ( bool );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function isApprovedForAll ( address account, address operator ) external view returns ( bool );
  function maxSupply (  ) external view returns ( uint256 );
  function mintRandomToken ( address to ) external;
  function name (  ) external view returns ( string memory);
  function provideInitialSupply ( uint256[] memory tokenIds, uint8[] memory rarities, string[] memory serialNumbers ) external;
  function removeApprovedContract ( address contractAddress ) external;
  function renounceRole ( bytes32 role, address callerConfirmation ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function royaltyInfo ( uint256 tokenId, uint256 salePrice ) external view returns ( address recipient, uint256 royaltyAmount );
  function safeBatchTransferFrom ( address from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data ) external;
  function safeTransferFrom ( address from, address to, uint256 id, uint256 value, bytes memory data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setDefaultRoyaltyInfo ( address recipient, uint96 feeNumerator ) external;
  function supplyFullyProvided (  ) external view returns ( bool );
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory);
  function tokenData ( uint256 ) external view returns ( uint8 rarity, string memory serialNumber );
  function totalSupply (  ) external view returns ( uint256 );
  function totalSupply ( uint256 id ) external view returns ( uint256 );
  function uri ( uint256 id ) external view returns ( string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPodOpener {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function addMintingContract ( address _podContract, address _mintingContract ) external;
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function mintingContracts ( address ) external view returns ( address );
  function openPod ( address _podContract, uint256 podId ) external;
  function renounceRole ( bytes32 role, address callerConfirmation ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
}

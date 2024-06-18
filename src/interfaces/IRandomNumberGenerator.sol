// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRandomNumberGenerator {
  function generateRandomNumber ( uint256 nonce ) external returns ( uint256 );
  function generateRandomNumberWithLimit ( uint256 nonce, uint256 lessThan ) external returns ( uint256 );
}

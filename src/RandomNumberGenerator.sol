// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@iota/iscmagic/ISC.sol";

/**
 * @title Random Number Generator Contract
 * @dev This contract leverages the IOTA Smart Contract Protocol's ISCSandbox to generate verifiable random numbers.
 *      It is designed to support decentralized applications by providing high-quality randomness with two main functionalities:
 *      generating unbounded random numbers and generating random numbers within a specified range. The randomness is derived
 *      from the ISCSandbox's getEntropy method, ensuring unpredictability and verifiable randomness.
 */
contract RandomNumberGenerator {

    constructor() {}

    /**
     * @notice Generates a random number derived from user-provided nonce and intrinsic blockchain entropy.
     * @dev This method generates an unbounded random number by hashing the combined entropy of the ISCSandbox, sender's address,
     *      and a user-provided nonce.
     * @param nonce A user-provided nonce to increase entropy and ensure uniqueness of the output.
     * @return A pseudo-random number generated using blockchain entropy and user-provided nonce.
     */
    function generateRandomNumber(uint256 nonce) public returns (uint256) {
        uint256 randomWord = uint256(
            keccak256(
                abi.encode(
                    ISC.sandbox.getEntropy(),
                    msg.sender,
                    nonce
                )
            )
        );
        return uint256(keccak256(abi.encode(randomWord)));
    }

    /**
     * @notice Generates a bounded random number derived from user-provided nonce and intrinsic blockchain entropy.
     * @dev This method generates a random number within a specified range by first producing an unbounded random number
     *      and then applying a modulo operation to limit its range.
     * @param nonce A user-provided nonce to increase entropy and ensure uniqueness of the output.
     * @param lessThan The exclusive upper limit for the random number generation.
     * @return A pseudo-random number less than the specified upper limit, ensuring it fits within the desired range.
     */
    function generateRandomNumberWithLimit(uint256 nonce, uint256 lessThan) public returns (uint256) {
        uint256 randomWord = uint256(
            keccak256(
                abi.encode(
                    ISC.sandbox.getEntropy(),
                    msg.sender,
                    nonce
                )
            )
        );
        uint256 newRand = uint256(keccak256(abi.encode(randomWord)));
        return newRand % lessThan;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IERC1155RandomMintable.sol";
import "./interfaces/IPod.sol";
import "./interfaces/IRandomNumberGenerator.sol";

contract PodOpener is AccessControl {
    mapping(address => IERC1155RandomMintable) public mysteryMintingContracts;
    mapping(address => IERC1155RandomMintable[2]) public basicMintingContracts;

    uint256 private nonce;
    IRandomNumberGenerator private randomNumberGenerator;

    constructor(address _adminAddress, address _randomNumberGenerator, uint256 _initialNonce) {
        _grantRole(DEFAULT_ADMIN_ROLE, _adminAddress);

        nonce = _initialNonce;
        randomNumberGenerator = IRandomNumberGenerator(_randomNumberGenerator);
    }

    function addMysteryMintingContract(address _podContract, IERC1155RandomMintable _mintingContract) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_podContract != address(_mintingContract), "Minting contract cannot be the same as pod contract");
        mysteryMintingContracts[_podContract] = _mintingContract;
    }

    function addBasicMintingContracts(address _podContract, IERC1155RandomMintable _mintingContract1, IERC1155RandomMintable _mintingContract2) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_mintingContract1 != _mintingContract2, "Minting contracts must be different");
        basicMintingContracts[_podContract] = [_mintingContract1, _mintingContract2];
    }

    function removeMysteryMintingContract(address _podContract) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete mysteryMintingContracts[_podContract];
    }

    function removeBasicMintingContracts(address _podContract) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete basicMintingContracts[_podContract];
    }

    function openPod(address _podContract, uint256 podId) public {
        IPod pod = IPod(_podContract);
        require(pod.ownerOf(podId) == msg.sender, "Caller is not the owner of the pod");
        require(!pod.isSoldOut(), "Pod is sold out");

        uint256 openingStartTimestamp = pod.regularOpeningTimeStamp();
        if (pod.isMystery()) {
            openingStartTimestamp = pod.isSoldOut() ? pod.prematureOpeningTimeStamp() : pod.regularOpeningTimeStamp();
        }
        require(block.timestamp >= openingStartTimestamp, "Opening period has not started yet");

        if (pod.isMystery()) {
            mysteryMintingContracts[_podContract].mintRandomToken(msg.sender);
        } else {
            uint randomIndex = randomNumberGenerator.generateRandomNumberWithLimit(nonce, 2);
            basicMintingContracts[_podContract][randomIndex].mintRandomToken(msg.sender);
        }

        nonce++;
        pod.burn(podId);
    }
}

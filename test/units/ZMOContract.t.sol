// SPDX-Licenst-Identifer: UNLICENSED
pragma solidity ^0.8.20;

import { BaseTest } from "../Base.t.sol";
import { ZMOContract } from "../../src/ZMOContract.sol";
import { ERC721Mock } from "../mocks/ERC721mock.sol";
import { ERC1155Mock } from "../mocks/ERC1155mock.sol";
import { OfferInfo } from "../../src/types/ZMOContractType.sol";

contract ZMOContractTest is BaseTest {
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    ZMOContract public zmoContract;
    ERC721Mock public erc721Mock;
    ERC1155Mock public erc1155Mock;

    function setUp() public {
        zmoContract = new ZMOContract(users.admin, users.rootAdmin);
        erc721Mock = new ERC721Mock();
        erc1155Mock = new ERC1155Mock();
        deal(users.alice, 100);
        deal(users.bob, 100);

        vm.startPrank(users.admin);
        erc721Mock.mint(users.admin, 1);
        erc721Mock.mint(users.admin, 2);
        erc1155Mock.mint(1, 1, "");
        erc1155Mock.mint(2, 5, "");
        vm.stopPrank();

        vm.startPrank(users.rootAdmin);
        erc721Mock.mint(users.rootAdmin, 3);
        erc1155Mock.mint(3, 10, "");
        vm.stopPrank();
    }

    function test_pause_shouldRevert_whenOwnableUnauthorizedAccount() public {
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, users.alice));

        vm.prank(users.alice);
        zmoContract.pause();
    }

    function test_pause_shouldRevert_whenEnforcedPause() public {
        vm.prank(users.admin);
        zmoContract.pause();

        bytes4 selector = bytes4(keccak256("EnforcedPause()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(users.admin);
        zmoContract.pause();
    }

    function test_pause_shouldPause() public {
        vm.prank(users.admin);
        zmoContract.pause();

        assertEq(zmoContract.paused(), true);
    }

    function test_unpause_shouldRevert_whenOwnableUnauthorizedAccount() public {
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, users.alice));

        vm.prank(users.alice);
        zmoContract.unpause();
    }

    function test_unpause_shouldRevert_whenExpectedPause() public {
        bytes4 selector = bytes4(keccak256("ExpectedPause()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(users.admin);
        zmoContract.unpause();
    }

    function test_unpause_shouldUnpause() public {
        vm.prank(users.admin);
        zmoContract.pause();

        vm.prank(users.admin);
        zmoContract.unpause();

        assertEq(zmoContract.paused(), false);
    }

    function test_setTimeExprire_shouldSetTimeExpire() public {
        vm.prank(users.admin);
        zmoContract.setTimeExpire(2 days);

        assertEq(zmoContract.timeExpire(), 2 days);
    }

    function test_setMoneyKeeper_shouldSetMoneyKeeper() public {
        vm.prank(users.admin);
        zmoContract.setMoneyKeeper(users.bob);

        assertEq(zmoContract.moneyKeeper(), users.bob);
    }

    function test_setFeeOffer_shouldSetFeeOffer() public {
        vm.prank(users.admin);
        zmoContract.setFeeOffer(5);

        assertEq(zmoContract.feeOffer(), 5);
    }

    function test_setFeeSuccess_shouldSetFeeSuccess() public {
        vm.prank(users.admin);
        zmoContract.setFeeSuccess(5);

        assertEq(zmoContract.feeSuccess(), 5);
    }

    function test_deposit_shouldRevert_whenPause() public {
        vm.prank(users.admin);
        zmoContract.pause();

        bytes4 selector = bytes4(keccak256("EnforcedPause()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(users.alice);
        zmoContract.deposit();
    }

    function test_deposit_shouldRevert_WhenInvalidAmount() public {
        uint256 amount = 0;

        bytes4 selector = bytes4(keccak256("InvalidAmount(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 0));

        vm.prank(users.alice);
        zmoContract.deposit{ value: amount }();
    }

    function test_deposit_shouldDeposit() public {
        uint256 amount = 6;
        uint256 preUserBalance = users.alice.balance;
        uint256 preUserBalanceContract = zmoContract.userBalance(users.alice);
        uint256 preZMOContractBalance = address(zmoContract).balance;

        vm.prank(users.alice);
        zmoContract.deposit{ value: amount }();

        uint256 posUserBalance = users.alice.balance;
        uint256 posUserBalanceContract = zmoContract.userBalance(users.alice);
        uint256 posZMOContractBalance = address(zmoContract).balance;

        assertEq(preUserBalance - 6, posUserBalance);
        assertEq(preUserBalanceContract + 6, posUserBalanceContract);
        assertEq(preZMOContractBalance + 6, posZMOContractBalance);
    }

    function test_createOffer_shouldRevert_whenPause() public {
        vm.prank(users.admin);
        zmoContract.pause();

        bytes4 selector = bytes4(keccak256("EnforcedPause()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(users.alice);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, 15);
    }

    function test_createOffer_shouldRevert_whenInvalidAmount() public {
        bytes4 selector = bytes4(keccak256("InvalidAmount(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 0));

        vm.prank(users.alice);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, 0);
    }

    function test_createOffer_shouldRevert_whenInvalidAmountBalance() public {
        uint256 amount = 5;

        bytes4 selector = bytes4(keccak256("InvalidAmountBalance(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 5));

        vm.prank(users.alice);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, amount);
    }

    function test_createOffer_shouldCreateOffer() public {
        uint256 amount = 6;
        vm.prank(users.alice);
        zmoContract.deposit{ value: amount }();

        // Miss test case check balance moneyKeeper
        uint256 preBuyerBalanceContract = zmoContract.userBalance(users.alice);

        vm.warp(2 days);
        vm.prank(users.alice);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, amount);

        OfferInfo memory offerInfo = OfferInfo({
            nftAddress: address(erc721Mock),
            nftId: 1,
            amount: 6,
            buyer: users.alice,
            seller: users.admin,
            offerAt: 2 days,
            offerStatus: false
        });

        uint256 posBuyerBalanceContract = zmoContract.userBalance(users.alice);

        uint256 offerId = 1;
        OfferInfo memory retrievedOfferInfo = zmoContract.getOffer(offerId);

        assertEq(zmoContract.currentOfferId(), offerId);
        assertEq(preBuyerBalanceContract - 6, posBuyerBalanceContract);

        assertEq(abi.encode(offerInfo), abi.encode(retrievedOfferInfo));
    }

    function test_updateOffer_shouldRevert_whenPause() public {
        vm.startPrank(users.alice);
        zmoContract.deposit{ value: 10 }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, 5);
        vm.stopPrank();

        vm.prank(users.admin);
        zmoContract.pause();

        bytes4 selector = bytes4(keccak256("EnforcedPause()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(users.alice);
        vm.warp(3 days);
        zmoContract.updateOffer(1, 10);
    }

    function test_updateOffer_shouldRevert_whenInvalidAmount() public {
        uint256 amount = 6;
        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, amount);
        vm.stopPrank();

        uint256 amountUpdate = 0;

        bytes4 selector = bytes4(keccak256("InvalidAmount(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 0));

        vm.prank(users.alice);
        zmoContract.updateOffer(1, amountUpdate);
    }

    function test_updateOffer_shouldRevert_whenInvalidOfferId() public {
        uint256 amount = 6;
        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, amount);
        vm.stopPrank();

        uint256 amountUpdate = 3;

        bytes4 selector = bytes4(keccak256("InvalidOfferId(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 2));

        vm.prank(users.alice);
        zmoContract.updateOffer(2, amountUpdate);
    }

    function test_updateOffer_shouldRevert_whenInvalidBuyer() public {
        uint256 amount = 10;
        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, 5);
        vm.stopPrank();

        uint256 amountUpdate = 10;

        bytes4 selector = bytes4(keccak256("InvalidBuyer(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, users.bob));

        vm.prank(users.bob);
        zmoContract.updateOffer(1, amountUpdate);
    }

    function test_updateOffer_shouldRevert_whenInvalidOfferStatusAccepted() public {
        uint256 amount = 15;
        uint256 offerId = 1;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, 5);
        zmoContract.createOffer(address(erc721Mock), 2, users.admin, 5);
        vm.stopPrank();

        vm.startPrank(users.admin);
        vm.warp(2 days + 2 hours);
        erc721Mock.approve(address(zmoContract), 1);
        zmoContract.acceptOffer(offerId);
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("InvalidOffer()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.startPrank(users.alice);
        vm.warp(2 days + 5 hours);
        zmoContract.updateOffer(1, 10);
        vm.stopPrank();
    }

    function test_updateOffer_shouldRevert_whenInvalidOfferStatusExpire() public {
        uint256 amount = 15;
        uint256 offerId = 1;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, 5);
        zmoContract.createOffer(address(erc721Mock), 2, users.admin, 5);
        vm.stopPrank();

        vm.startPrank(users.admin);
        vm.warp(2 days + 2 hours);
        erc721Mock.approve(address(zmoContract), 1);
        zmoContract.acceptOffer(offerId);
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("InvalidOffer()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.startPrank(users.alice);
        vm.warp(2 days + 28 hours + 1 seconds);
        zmoContract.updateOffer(2, 10);
        vm.stopPrank();
    }

    function test_updateOffer_shouldUpdateOffer() public {
        uint256 amount = 10;
        uint256 offerId = 1;

        vm.prank(users.alice);
        zmoContract.deposit{ value: amount }();

        uint256 preBuyerBalance = zmoContract.userBalance(users.alice);

        vm.startPrank(users.alice);
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, 5);

        vm.warp(3 days);
        zmoContract.updateOffer(offerId, 10);
        vm.stopPrank();

        OfferInfo memory offerInfo = OfferInfo({
            nftAddress: address(erc721Mock),
            nftId: 1,
            amount: 10,
            buyer: users.alice,
            seller: users.admin,
            offerAt: 3 days,
            offerStatus: false
        });

        uint256 posBuyerBalance = zmoContract.userBalance(users.alice);

        OfferInfo memory retrievedOfferInfo = zmoContract.getOffer(offerId);

        assertEq(posBuyerBalance, 0);
        assertEq(zmoContract.currentOfferId(), offerId);
        assertEq(preBuyerBalance - 10, posBuyerBalance);
        assertEq(abi.encode(offerInfo), abi.encode(retrievedOfferInfo));
    }

    function test_acceptOffer_shouldRevert_whenPause() public {
        vm.startPrank(users.alice);
        zmoContract.deposit{ value: 10 }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, 5);
        vm.stopPrank();

        vm.prank(users.alice);
        vm.warp(2 days + 2 hours);
        zmoContract.updateOffer(1, 10);

        vm.prank(users.admin);
        zmoContract.pause();

        bytes4 selector = bytes4(keccak256("EnforcedPause()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.startPrank(users.admin);
        vm.warp(3 days + 28 hours + 1 seconds);
        zmoContract.acceptOffer(1);
        vm.stopPrank();
    }

    function test_acceptOffer_shouldRevert_whenInvalidOfferId() public {
        uint256 amount = 6;
        uint256 offerId = 2;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, amount);
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("InvalidOfferId(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 2));

        vm.prank(users.admin);
        zmoContract.acceptOffer(offerId);
    }

    function test_acceptOffer_shouldRevert_whenOfferAlreadySuccess() public {
        uint256 amount = 6;
        uint256 offerId = 1;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, amount);
        vm.stopPrank();

        vm.startPrank(users.admin);
        vm.warp(2 days + 2 hours);
        erc721Mock.approve(address(zmoContract), 1);
        zmoContract.acceptOffer(offerId);
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("InvalidOffer()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(users.admin);
        zmoContract.acceptOffer(offerId);
    }

    function test_acceptOffer_shouldRevert_whenExpiredOffer() public {
        uint256 amount = 6;
        uint256 offerId = 1;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, amount);
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("ExpiredOffer()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.warp(2 days + 28 hours + 1 seconds);
        vm.prank(users.admin);
        zmoContract.acceptOffer(offerId);
    }

    function test_acceptOffer_shouldRevert_whenInvalidSeller() public {
        uint256 amount = 6;
        uint256 offerId = 1;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, amount);
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("InvalidSeller(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, users.alice));

        vm.warp(2 days + 2 hours);
        vm.prank(users.alice);
        zmoContract.acceptOffer(offerId);
    }

    function test_acceptOffer_shouldRevert_whenUnauthorizedOwner() public {
        uint256 amount = 6;
        uint256 offerId = 1;
        address nftAddress = address(erc721Mock);
        uint256 nftId = 3;
        address sellerAddress = users.admin;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(nftAddress, nftId, sellerAddress, amount);
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("UnauthorizedOwner(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, users.admin));

        vm.warp(2 days + 2 hours);
        vm.prank(users.admin);
        zmoContract.acceptOffer(offerId);
    }

    function test_acceptOffer_shouldRevert_whenInsufficientBalance() public {
        uint256 amount = 6;
        uint256 offerId = 1;
        address nftAddress = address(erc1155Mock);
        uint256 nftId = 4;
        address sellerAddress = users.admin;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(nftAddress, nftId, sellerAddress, amount);
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("InsufficientBalance(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 0));

        vm.warp(2 days + 2 hours);
        vm.prank(users.admin);
        zmoContract.acceptOffer(offerId);
    }

    function test_acceptOffer_shouldAcceptOffer_ERC721() public {
        uint256 amount = 6;
        uint256 offerId = 1;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc721Mock), 1, users.admin, amount);
        vm.stopPrank();

        // Miss test case check balance moneyKeeper
        uint256 preSellerBalanceContract = zmoContract.userBalance(users.admin);

        vm.startPrank(users.admin);
        vm.warp(2 days + 2 hours);
        erc721Mock.approve(address(zmoContract), 1);
        zmoContract.acceptOffer(offerId);
        vm.stopPrank();

        OfferInfo memory offerInfo = OfferInfo({
            nftAddress: address(erc721Mock),
            nftId: 1,
            amount: 6,
            buyer: users.alice,
            seller: users.admin,
            offerAt: 2 days,
            offerStatus: true
        });

        uint256 posSellerBalanceContract = zmoContract.userBalance(users.admin);
        OfferInfo memory retrievedOfferInfo = zmoContract.getOffer(offerId);

        assertEq(abi.encode(offerInfo), abi.encode(retrievedOfferInfo));
        assertEq(preSellerBalanceContract + 6, posSellerBalanceContract);
        assertEq(erc721Mock.ownerOf(1), users.alice);
    }

    function test_acceptOffer_shouldAcceptOffer_ERC1155() public {
        uint256 amount = 6;
        uint256 offerId = 1;

        vm.startPrank(users.alice);
        zmoContract.deposit{ value: amount }();
        vm.warp(2 days);
        zmoContract.createOffer(address(erc1155Mock), 1, users.admin, amount);
        vm.stopPrank();

        // Miss test case check balance moneyKeeper
        uint256 preSellerBalanceContract = zmoContract.userBalance(users.admin);

        vm.startPrank(users.admin);
        vm.warp(2 days + 2 hours);
        erc1155Mock.setApprovalForAll(address(zmoContract), true);
        zmoContract.acceptOffer(offerId);
        vm.stopPrank();

        OfferInfo memory offerInfo = OfferInfo({
            nftAddress: address(erc1155Mock),
            nftId: 1,
            amount: 6,
            buyer: users.alice,
            seller: users.admin,
            offerAt: 2 days,
            offerStatus: true
        });

        uint256 posSellerBalanceContract = zmoContract.userBalance(users.admin);
        OfferInfo memory retrievedOfferInfo = zmoContract.getOffer(offerId);

        assertEq(abi.encode(offerInfo), abi.encode(retrievedOfferInfo));
        assertEq(preSellerBalanceContract + 6, posSellerBalanceContract);
        assertEq(erc1155Mock.balanceOf(users.alice, 1), 1);
    }

    function test_withdraw_shouldRevert_whenPause() public {
        uint256 amount = 15;
        uint256 offerId = 1;

        vm.prank(users.alice);
        zmoContract.deposit{ value: amount }();

        vm.startPrank(users.alice);
        vm.warp(2 days);
        zmoContract.createOffer(address(erc1155Mock), 1, users.admin, 5);
        zmoContract.updateOffer(offerId, 10);
        vm.warp(3 days);
        zmoContract.createOffer(address(erc721Mock), 2, users.admin, 5);
        vm.stopPrank();

        vm.startPrank(users.admin);
        vm.warp(2 days + 2 hours);
        erc1155Mock.setApprovalForAll(address(zmoContract), true);
        zmoContract.acceptOffer(offerId);
        vm.stopPrank();

        vm.prank(users.admin);
        zmoContract.pause();

        bytes4 selector = bytes4(keccak256("EnforcedPause()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        vm.prank(users.alice);
        zmoContract.withdraw(5);
    }

    function test_withdraw_shouldRevert_whenInvalidAmount() public {
        bytes4 selector = bytes4(keccak256("InvalidAmount(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 0));

        vm.prank(users.alice);
        zmoContract.withdraw(0);
    }

    function test_withdraw_shouldRevert_whenInsufficientBalanceContract() public {
        uint256 amount = 15;

        vm.prank(users.alice);
        zmoContract.deposit{ value: amount }();

        vm.prank(address(zmoContract));
        payable(users.admin).transfer(10);

        bytes4 selector = bytes4(keccak256("InsufficientBalance(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 10));

        vm.prank(users.alice);
        zmoContract.withdraw(10);
    }

    function test_withdraw_shouldRevert_whenInsufficientBalanceUser() public {
        uint256 amount = 15;

        vm.prank(users.alice);
        zmoContract.deposit{ value: amount }();

        vm.startPrank(users.alice);
        vm.warp(2 days);
        zmoContract.createOffer(address(erc1155Mock), 1, users.admin, 5);
        zmoContract.createOffer(address(erc721Mock), 2, users.admin, 10);
        vm.stopPrank();

        vm.startPrank(users.admin);
        vm.warp(2 days + 2 hours);
        erc1155Mock.setApprovalForAll(address(zmoContract), true);
        zmoContract.acceptOffer(1);
        vm.stopPrank();

        bytes4 selector = bytes4(keccak256("InsufficientBalance(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 15));

        vm.prank(users.alice);
        zmoContract.withdraw(15);
    }

    function test_withdraw_shouldWithdraw() public {
        uint256 amount = 15;
        uint256 offerId = 1;

        vm.prank(users.alice);
        zmoContract.deposit{ value: amount }();

        uint256 preBuyerBlance = users.alice.balance;
        uint256 preBuyerBalanceContract = zmoContract.userBalance(users.alice);

        vm.startPrank(users.alice);
        vm.warp(2 days);
        zmoContract.createOffer(address(erc1155Mock), 1, users.admin, 5);
        zmoContract.updateOffer(offerId, 10);
        vm.warp(3 days);
        zmoContract.createOffer(address(erc721Mock), 2, users.admin, 5);
        vm.stopPrank();

        vm.startPrank(users.admin);
        vm.warp(2 days + 2 hours);
        erc1155Mock.setApprovalForAll(address(zmoContract), true);
        zmoContract.acceptOffer(offerId);
        vm.stopPrank();

        vm.startPrank(users.alice);
        vm.warp(3 days + 28 hours + 1 seconds);
        zmoContract.withdraw(5);
        vm.stopPrank();

        uint256 posBuyerBlance = users.alice.balance;
        uint256 posBuyerBalanceContract = zmoContract.userBalance(users.alice);

        assertEq(preBuyerBlance + 5, posBuyerBlance);
        assertEq(posBuyerBlance, 90);
        assertEq(preBuyerBalanceContract - 15, posBuyerBalanceContract);
        assertEq(posBuyerBalanceContract, 0);
    }
}

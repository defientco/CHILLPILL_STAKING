// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/ChillpillStaking.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ChillPill is ERC721 {
    uint256 tokenId = 1;

    constructor() ERC721("CHILLPILL", "CHILLRX") {}

    function mint() public {
        _mint(msg.sender, tokenId);
        ++tokenId;
    }
}

contract ContractTest is Test {
    ChillpillStaking cps;
    ChillPill erc721;
    ChillToken ct;
    uint256 vaultDuration = 100;
    uint256 totalSupply = 100;
    address owner = address(this);
    uint256 ONE_DAY = 60 * 60 * 24;

    function setUp() public {
        erc721 = new ChillPill();
        cps = new ChillpillStaking(address(erc721), vaultDuration, totalSupply);
        ct = cps.chillToken();
    }

    function testCan_initVariables() public {
        assertEq(cps.totalStaked(), 0);
        assertEq(cps.nftAddress(), address(erc721));
        assertEq(address(cps.chillToken()), address(ct));
        assertEq(cps.vaultStart(), block.timestamp);
        assertEq(cps.vaultEnd(), block.timestamp + (vaultDuration * 1 days));
        assertEq(cps.totalClaimed(), 0);
        assertEq(cps.totalNftSupply(), totalSupply);
        assertEq(cps.maxSupply(), 8080000000000000000000000);
    }

    function testCan_haveVaultBalanceOfZero() public {
        assertEq(erc721.balanceOf(owner), 0);
    }

    function testCan_revertStakeInvalidTokenId() public {
        uint256[] memory tokensToStake = new uint256[](1);
        tokensToStake[0] = 1;
        vm.expectRevert("ERC721: invalid token ID");
        cps.stake(tokensToStake);
    }

    function testCan_revertStakeNotApprovedForTransfer() public {
        erc721.mint();
        uint256[] memory tokensToStake = new uint256[](1);
        tokensToStake[0] = 1;
        vm.expectRevert("not approved for transfer");
        cps.stake(tokensToStake);
    }

    function testCan_stakeApprovedToken() public {
        erc721.mint();
        erc721.approve(address(cps), 1);
        uint256[] memory tokensToStake = new uint256[](1);
        tokensToStake[0] = 1;
        cps.stake(tokensToStake);
    }

    function testCan_stakeApprovedForAll() public {
        erc721.mint();
        uint256[] memory tokensToStake = new uint256[](1);
        erc721.setApprovalForAll(address(cps), true);
        tokensToStake[0] = 1;
        cps.stake(tokensToStake);
    }

    function testCan_earn808ChillIn1Day() public {
        erc721.mint();
        uint256[] memory tokensToStake = new uint256[](1);
        erc721.setApprovalForAll(address(cps), true);
        tokensToStake[0] = 1;
        cps.stake(tokensToStake);
        vm.warp(block.timestamp + ONE_DAY);
        assertEq(
            cps.earningInfo(address(this), tokensToStake),
            cps.dailyStakeRate()
        );
    }
}

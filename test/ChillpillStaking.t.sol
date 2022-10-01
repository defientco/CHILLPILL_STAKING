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

contract ChillPillStakingTest is Test {
    ChillpillStaking cps;
    ChillPill erc721;
    ChillToken ct;
    uint256 totalSupply = 9999;
    address owner = address(this);

    function setUp() public {
        erc721 = new ChillPill();
        cps = new ChillpillStaking(address(erc721), totalSupply);
        ct = cps.chillToken();
    }

    function testCan_initVariables() public {
        assertEq(cps.totalStaked(), 0);
        assertEq(cps.nftAddress(), address(erc721));
        assertEq(address(cps.chillToken()), address(ct));
        assertEq(cps.totalClaimed(), 0);
        assertEq(cps.totalNftSupply(), totalSupply);
        assertEq(cps.maxSupply(), 8080000000000000000000000);
    }

    function testCan_decentSdkCompatible() public {
        assertEq(cps.erc20Address(), address(ct));
        assertEq(cps.balanceOf(msg.sender), 0);
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

    function testCan_revertEarningInfoNotOwner() public {
        erc721.mint();
        uint256[] memory tokensToStake = new uint256[](1);
        erc721.setApprovalForAll(address(cps), true);
        tokensToStake[0] = 1;
        cps.stake(tokensToStake);
        vm.expectRevert("not an owner");
        cps.earningInfo(address(1), tokensToStake);
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
        vm.warp(block.timestamp + 1 days);
        assertEq(
            cps.earningInfo(address(this), tokensToStake),
            8080000003870675200
        );
    }

    function testCan_dailyStakeRate() public {
        assertEq(cps.dailyStakeRate(), 8080000000000000000);
    }

    function testCan_secondStakeRate() public {
        assertEq(
            cps.secondStakeRate(),
            cps.dailyStakeRate() / 1 days + (cps.dailyStakeRate() % 1 days)
        );
    }

    function testCan_earnHalfDayRate() public {
        erc721.mint();
        uint256[] memory tokensToStake = new uint256[](1);
        erc721.setApprovalForAll(address(cps), true);
        tokensToStake[0] = 1;
        cps.stake(tokensToStake);
        vm.warp(block.timestamp + (1 days / 2));
        assertEq(
            cps.earningInfo(address(this), tokensToStake),
            cps.secondStakeRate() * (1 days / 2)
        );
    }

    function testCan_stakeAllPills() public {
        uint256[] memory tokensToStake = new uint256[](9999);
        for (uint256 i = 0; i < tokensToStake.length; i++) {
            erc721.mint();
            tokensToStake[i] = i + 1;
        }
        erc721.setApprovalForAll(address(cps), true);
        cps.stake(tokensToStake);
        assertEq(cps.balanceOf(address(this)), tokensToStake.length);
        assertEq(cps.tokensOfOwner(address(this)).length, tokensToStake.length);
    }

    function testCan_unstake() public {
        vm.startPrank(address(1));
        uint256[] memory tokensToStake = new uint256[](1);
        tokensToStake[0] = 1;
        erc721.mint();
        erc721.setApprovalForAll(address(cps), true);
        cps.stake(tokensToStake);
        vm.warp(block.timestamp + 1 days);
        assertEq(
            cps.earningInfo(address(1), tokensToStake),
            cps.secondStakeRate() * 1 days
        );
        cps.unstake(tokensToStake);
        assertEq(ct.balanceOf(address(1)), cps.secondStakeRate() * 1 days);
        assertEq(cps.balanceOf(address(1)), 0);
        assertEq(ct.totalSupply(), cps.secondStakeRate() * 1 days);
    }

    function testCan_revertIfStakingContractReceivesNFT() public {
        uint256[] memory tokensToStake = new uint256[](1);
        erc721.mint();
        tokensToStake[0] = 1;
        erc721.setApprovalForAll(address(cps), true);
        cps.stake(tokensToStake);
        vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");
        cps.unstake(tokensToStake);
    }

    function testCan_firstHalvening() public {
        vm.startPrank(address(1));
        uint256[] memory tokensToStake = new uint256[](9999);
        for (uint256 i = 0; i < tokensToStake.length; i++) {
            erc721.mint();
            tokensToStake[i] = i + 1;
        }
        erc721.setApprovalForAll(address(cps), true);
        cps.stake(tokensToStake);
        // minimum days if all pills staked is 51 days till first halvening
        vm.warp(51 days);
        assertTrue(
            cps.earningInfo(address(1), tokensToStake) > cps.maxSupply() / 2
        );
        cps.unstake(tokensToStake);
        assertTrue(ct.totalSupply() > cps.maxSupply() / 2);
        assertEq(cps.dailyStakeRate(), 8080000000000000000 / 2);
    }
}

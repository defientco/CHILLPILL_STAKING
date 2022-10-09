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

contract PartyPills is ERC721 {
    uint256 tokenId = 1;

    constructor() ERC721("PARTY PILLS", "PARTY") {}

    function mint() public {
        _mint(msg.sender, tokenId);
        ++tokenId;
    }
}

contract PartyPillStakingTest is Test {
    ChillpillStaking cps;
    ChillPill erc721;
    ChillToken ct;
    PartyPills pp;
    uint256 totalSupply = 9999;
    address owner = address(this);
    uint256 offset;

    function setUp() public {
        erc721 = new ChillPill();
        pp = new PartyPills();
        cps = new ChillpillStaking(address(erc721), totalSupply);
        ct = cps.chillToken();
        offset = cps.partyPillStartIndex();
    }

    function isInitialState() private {
        assertEq(cps.partyPillAddress(), address(0));
        assertEq(cps.partyPillMultiplier(), 0);
        assertEq(cps.partyPillCount(), 0);
        assertEq(cps.partyPillStartIndex(), offset);
    }

    function setupPartyPills() private {
        cps.updatePartyPill(address(pp), 3, 5000);
    }

    function testCan_initVariables() public {
        isInitialState();
    }

    function testCan_ownable() public {
        assertEq(cps.owner(), address(this));
    }

    function testCan_updatePartyPill() public {
        uint256 _supply = cps.totalNftSupply();
        uint256 _partySupply = 5000;
        cps.updatePartyPill(address(1), 3, _partySupply);
        assertEq(cps.partyPillAddress(), address(1));
        assertEq(cps.partyPillMultiplier(), 3);
        assertEq(cps.partyPillCount(), _partySupply);
        assertEq(cps.totalNftSupply(), _partySupply + _supply);
    }

    function testCan_updateSupplyMultipleTimes() public {
        uint256 _supply = cps.totalNftSupply();
        for (uint256 i = 500; i < 10000; i++) {
            cps.updatePartyPill(address(1), 3, i);
            assertEq(cps.partyPillCount(), i);
            assertEq(cps.totalNftSupply(), i + _supply);
        }
    }

    function testCan_revertNonOwnerUpdatePartyPill() public {
        vm.prank(address(0));
        vm.expectRevert("Ownable: caller is not the owner");
        cps.updatePartyPill(address(1), 3, 5000);
        isInitialState();
    }

    function testCan_stakePartyPill() public {
        pp.mint();
        uint256[] memory tokensToStake = new uint256[](1);
        tokensToStake[0] = 1 + offset;
        pp.setApprovalForAll(address(cps), true);
        setupPartyPills();
        assertEq(pp.ownerOf(1), address(this));
        assertEq(cps.balanceOf(address(this)), 0);
        cps.stake(tokensToStake);
        assertEq(pp.ownerOf(1), address(cps));
        assertEq(cps.balanceOf(address(this)), 1);
    }

    function testCan_stakeAllPartyPills() public {
        setupPartyPills();
        uint256[] memory tokensToStake = new uint256[](cps.partyPillCount());
        for (uint256 i = 1; i <= tokensToStake.length; i++) {
            pp.mint();
            tokensToStake[i - 1] = offset + i;
            assertEq(pp.ownerOf(i), address(this));
        }
        pp.setApprovalForAll(address(cps), true);
        assertEq(cps.balanceOf(address(this)), 0);
        cps.stake(tokensToStake);
        for (uint256 i = 1; i <= tokensToStake.length; i++) {
            assertEq(pp.ownerOf(i), address(cps));
        }
        assertEq(cps.balanceOf(address(this)), cps.partyPillCount());
    }

    function testCan_earnMultiplier() public {
        setupPartyPills();
        pp.mint();
        uint256[] memory tokensToStake = new uint256[](1);
        tokensToStake[0] = 1 + offset;
        pp.setApprovalForAll(address(cps), true);
        cps.stake(tokensToStake);
        vm.warp(block.timestamp + 1 days);
        assertEq(
            cps.earningInfo(address(this), tokensToStake),
            24240000011612025600
        );
    }

    function testCan_claim() public {
        setupPartyPills();
        pp.mint();
        uint256[] memory tokensToStake = new uint256[](1);
        tokensToStake[0] = 1 + offset;
        pp.setApprovalForAll(address(cps), true);
        cps.stake(tokensToStake);
        vm.warp(block.timestamp + 1 days);
        cps.claim(tokensToStake);
        assertEq(ct.balanceOf(address(this)), 24240000011612025600);
    }
}

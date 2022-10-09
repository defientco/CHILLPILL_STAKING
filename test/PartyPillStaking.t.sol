// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/ChillpillStaking.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "../src/lib/ChillStructs.sol";

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

contract PartyPillStakingTest is Test, ChillStructs {
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
        cps.updatePartyPill(address(1), 3, 5000);
        assertEq(cps.partyPillAddress(), address(1));
        assertEq(cps.partyPillMultiplier(), 3);
        assertEq(cps.partyPillCount(), 5000);
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
}

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

    function setUp() public {
        erc721 = new ChillPill();
        pp = new PartyPills();
        cps = new ChillpillStaking(address(erc721), totalSupply);
        ct = cps.chillToken();
    }

    function testCan_initVariables() public {
        assertEq(cps.partyPillAddress(), address(0));
        assertEq(cps.partyPillMultiplier(), 0);
        assertEq(cps.partyPillCount(), 0);
    }
}

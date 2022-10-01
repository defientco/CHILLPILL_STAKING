// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/ChillpillStaking.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ChillPill is ERC721 {
    uint256 public tokenId = 1;

    constructor() ERC721("CHILLPILL", "CHILLRX") {}

    function mint() public {
        _mint(msg.sender, tokenId);
        ++tokenId;
    }
}

contract ChillPillStakingThirdHalveningTest is Test {
    ChillpillStaking cps;
    ChillPill erc721;
    ChillToken ct;
    uint256 totalSupply = 9999;
    address owner = address(this);
    uint256[] allPills = new uint256[](9999);

    function setUp() public {
        erc721 = new ChillPill();
        cps = new ChillpillStaking(address(erc721), totalSupply);
        ct = cps.chillToken();

        // 0 HALVENING => 1 HALVENING
        vm.startPrank(address(1));
        uint256[] memory tokensToStake = new uint256[](9999);
        for (uint256 i = 0; i < tokensToStake.length; i++) {
            erc721.mint();
            allPills[i] = i + 1;
        }
        erc721.setApprovalForAll(address(cps), true);
        cps.stake(allPills);
        // minimum days if all pills staked is 51 days till first halvening
        vm.warp(block.timestamp + 51 days);
        assertTrue(cps.earningInfo(address(1), allPills) > cps.maxSupply() / 2);
        cps.unstake(allPills);

        // 1 HALVENING => 2 HALVENING
        cps.stake(allPills);
        vm.warp(block.timestamp + 51 days);
        cps.unstake(allPills);

        // 2 HALVENING => 3 HALVENING
        cps.stake(allPills);
        vm.warp(block.timestamp + 51 days);
        cps.unstake(allPills);

        assertTrue(ct.totalSupply() > (7 * cps.maxSupply()) / 8);
        vm.stopPrank();
    }

    function testCan_thirdHalvening() public {
        assertEq(cps.halveningCount(), 3);
    }

    function testCan_halveningDailyStakeRate() public {
        assertEq(cps.dailyStakeRate(), 8080000000000000000 / 8);
    }

    function testCan_halveningSecondStakeRate() public {
        assertEq(
            cps.secondStakeRate(),
            cps.dailyStakeRate() / 1 days + (cps.dailyStakeRate() % 1 days)
        );
    }

    function testCan_earn101ChillIn1Day() public {
        vm.startPrank(address(2));
        uint256[] memory tokensToStake = new uint256[](1);
        tokensToStake[0] = erc721.tokenId();
        erc721.mint();
        erc721.setApprovalForAll(address(cps), true);
        cps.stake(tokensToStake);
        vm.warp(block.timestamp + 1 days);
        assertEq(
            cps.earningInfo(address(2), tokensToStake),
            1010000006082489600
        );
    }

    function testCan_earnHalveningHalfDayRate() public {
        vm.startPrank(address(2));
        uint256[] memory tokensToStake = new uint256[](1);
        tokensToStake[0] = erc721.tokenId();
        erc721.mint();
        erc721.setApprovalForAll(address(cps), true);
        cps.stake(tokensToStake);
        vm.warp(block.timestamp + (1 days / 2));
        assertEq(
            cps.earningInfo(address(2), tokensToStake),
            cps.secondStakeRate() * (1 days / 2)
        );
    }

    function testCan_stakeAllPills() public {
        vm.startPrank(address(1));
        cps.stake(allPills);
        assertEq(cps.balanceOf(address(1)), allPills.length);
        assertEq(cps.tokensOfOwner(address(1)).length, allPills.length);
    }

    function testCan_noFourthHalvening() public {
        vm.startPrank(address(1));
        cps.stake(allPills);
        // minimum days if all pills staked
        // is 51 days till expected forth halvening
        // note: only 3 halvenings
        vm.warp(block.timestamp + 50 days);
        assertFalse(
            cps.earningInfo(address(1), allPills) > cps.maxSupply() / 16
        );
        vm.warp(block.timestamp + 1 days);
        assertTrue(
            cps.earningInfo(address(1), allPills) > cps.maxSupply() / 16
        );
        cps.unstake(allPills);
        assertTrue(ct.totalSupply() > (15 * cps.maxSupply()) / 16);
        assertEq(cps.dailyStakeRate(), 8080000000000000000 / 8);
        assertEq(cps.halveningCount(), 3);
    }

    function testCan_mintAllChillTokens() public {
        vm.startPrank(address(1));
        cps.stake(allPills);
        vm.warp(block.timestamp + 100 days);
        cps.unstake(allPills);
        assertEq(cps.dailyStakeRate(), 8080000000000000000 / 8);
        assertEq(cps.halveningCount(), 3);
        assertEq(ct.totalSupply(), cps.maxSupply());
    }
}

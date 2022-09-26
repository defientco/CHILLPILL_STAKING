// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/ChillpillStaking.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ContractTest is Test {
    ChillpillStaking cps;
    ERC721 erc721;
    ERC20 erc20;

    function setUp() public {
        erc721 = new ERC721("chillpill", "CHILL");
        erc20 = new ERC20("CHILLPILL", "CHILL");
        uint256 _vaultDuration = 100;
        uint256 _totalSupply = 100;
        cps = new ChillpillStaking(
            address(this),
            address(erc721),
            address(erc20),
            _vaultDuration,
            _totalSupply
        );
    }

    function testCan_totalStaked() public {
        assertEq(cps.totalStaked(), 0);
    }
}

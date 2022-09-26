// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/ChillToken.sol";

contract ContractTest is Test {
    ChillToken ct;
    address minter;

    function setUp() public {
        minter = address(this);
        ct = new ChillToken(minter);
    }

    function testCan_initVariables() public {
        assertEq(ct.totalSupply(), 0);
        assertEq(ct.name(), "CHILL");
        assertEq(ct.symbol(), "CHILL");
        assertEq(ct.minter(), minter);
    }

    function testCan_mintNewTokens() public {
        ct.mint(address(this), 100);
        assertEq(ct.totalSupply(), 100);
    }

    function testCan_revertNonMinterMintNewTokens() public {
        vm.startPrank(address(1));
        vm.expectRevert("not authorized to mint new $CHILL tokens");
        ct.mint(address(this), 100);
    }
}

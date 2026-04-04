// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IDotOneSwapV2Factory, Deployer} from "./util/Deployer.sol";
import {Helpers} from "./util/Helpers.sol";
import {Constants} from "./util/Constants.sol";

abstract contract Deployed is Test {
    IDotOneSwapV2Factory factory;

    function setUp() public virtual {
        factory = Deployer.deployFactory(address(this));
    }
}

contract FactoryTests is Deployed {
    function test_isInitialized() public view {
        assertEq(factory.feeTo(), Constants.ADDRESS_ZERO);
        assertEq(factory.feeToSetter(), address(this));
        assertEq(factory.allPairsLength(), 0);
    }

    function test_createPair(address token0, address token1) public {
        vm.assume(token0 != token1 && token0 != Constants.ADDRESS_ZERO && token1 != Constants.ADDRESS_ZERO);
        (address tokenA, address tokenB) = token0 < token1 ? (token0, token1) : (token1, token0);
        address create2address = Helpers.getDotOneSwapV2PairAddress(factory, tokenA, tokenB);
        vm.expectEmit(true, true, true, true);
        emit IDotOneSwapV2Factory.PairCreated(tokenA, tokenB, create2address, 1);
        factory.createPair(token0, token1);
        assertEq(factory.getPair(token0, token1), create2address);
        assertEq(factory.getPair(token1, token0), create2address);
        assertEq(factory.allPairs(0), create2address);
    }

    function test_createPair_IdenticalAddresses(address token) public {
        vm.assume(token != Constants.ADDRESS_ZERO);
        vm.expectRevert("DotOneSwapV2: IDENTICAL_ADDRESSES");
        factory.createPair(token, token);
    }

    function test_createPair_ZeroAddress(address token) public {
        vm.assume(token != Constants.ADDRESS_ZERO);
        vm.expectRevert("DotOneSwapV2: ZERO_ADDRESS");
        factory.createPair(token, Constants.ADDRESS_ZERO);
    }

    function test_createPair_PairExists(address token0, address token1) public {
        vm.assume(token0 != token1 && token0 != Constants.ADDRESS_ZERO && token1 != Constants.ADDRESS_ZERO);
        factory.createPair(token0, token1);
        vm.expectRevert("DotOneSwapV2: PAIR_EXISTS");
        factory.createPair(token0, token1);
    }

    function test_setFeeTo(address other) public {
        vm.assume(other != address(this));
        factory.setFeeTo(other);
        assertEq(factory.feeTo(), other);
        assertEq(factory.feeToSetter(), address(this));
    }

    function test_setFeeTo_Unauthorized(address other) public {
        vm.assume(other != address(this));
        vm.prank(other);
        vm.expectRevert("DotOneSwapV2: FORBIDDEN");
        factory.setFeeTo(other);
    }

    function test_setFeeToSetter(address other) public {
        vm.assume(other != address(this));
        factory.setFeeToSetter(other);
        assertEq(factory.feeTo(), Constants.ADDRESS_ZERO);
        assertEq(factory.feeToSetter(), other);
    }

    function test_setFeeToSetter_Unauthorized(address other) public {
        vm.assume(other != address(this));
        vm.prank(other);
        vm.expectRevert("DotOneSwapV2: FORBIDDEN");
        factory.setFeeToSetter(other);
    }

    function test_setFeeToSetter_ToOther(address other) public {
        vm.assume(other != address(this));
        factory.setFeeTo(other);
        factory.setFeeToSetter(other);
        assertEq(factory.feeToSetter(), other);
        assertEq(factory.feeTo(), other);
        vm.expectRevert("DotOneSwapV2: FORBIDDEN");
        factory.setFeeToSetter(other);
    }
}

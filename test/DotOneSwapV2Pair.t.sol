// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IDotOneSwapV2Factory,IDotOneSwapV2Pair, Deployer} from "./util/Deployer.sol";
import {Helpers} from "./util/Helpers.sol";
import {Constants} from "./util/Constants.sol";
import {CustomToken} from "./util/CustomToken.sol";

import {IDotOneSwapV2Factory} from "../src/interfaces/IDotOneSwapV2Factory.sol";
import {IDotOneSwapV2Pair} from "../src/interfaces/IDotOneSwapV2Pair.sol";

abstract contract Deployed is Test {
    IDotOneSwapV2Factory factory;
    IDotOneSwapV2Pair pair;

    CustomToken token0Contract;
    CustomToken token1Contract;

    function setUp() public virtual {
        factory = Deployer.deployFactory(address(this));
        token0Contract = new  CustomToken("Token0","tkn0");
        token1Contract = new  CustomToken("Token1","tkn1");
    }

    function createPairRandom(address token0, address token1) public {
        vm.assume(token0 != token1 && token0 != Constants.ADDRESS_ZERO && token1 != Constants.ADDRESS_ZERO);
        (address tokenA, address tokenB) = token0 < token1 ? (token0, token1) : (token1, token0);
        address pairAddres = factory.createPair(token0, token1);

    }
}

contract PairTests is Deployed {


    function test_mint  () public
    {
        uint amount0 = 100 ether;
        uint amount1 = 100 ether;
        address pairAddres = factory.createPair(address(token0Contract), address(token1Contract));
        token0Contract.transfer(pairAddres, amount0);
        token1Contract.transfer(pairAddres, amount1);
        uint liquidity = IDotOneSwapV2Pair(pairAddres).mint(address(this));

        assertEq(token0Contract.balanceOf(address(pairAddres)), amount0, "Pair Token0 balance incorrect");
        assertEq(token1Contract.balanceOf(address(pairAddres)), amount1, "Pair Token1 balance incorrect");

        (uint112 reserve0, uint112 reserve1, ) = IDotOneSwapV2Pair (pairAddres).getReserves();
        assertEq(reserve0, amount0);
        assertEq(reserve1, amount1);

        console.log("Liquidity is");
        console.log(liquidity);

    }

    function test_burn  () public
    {
        uint amount0 = 100 ether;
        uint amount1 = 100 ether;
        address pairAddres = factory.createPair(address(token0Contract), address(token1Contract));
        token0Contract.transfer(pairAddres, amount0);
        token1Contract.transfer(pairAddres, amount1);
        uint liquidity = IDotOneSwapV2Pair(pairAddres).mint(address(this));

        IDotOneSwapV2Pair(pairAddres).transfer(pairAddres, liquidity);

        (uint256 amount0Out, uint256 amount1Out) = IDotOneSwapV2Pair(pairAddres).burn(address(this));

        assertGt(amount0Out, amount0 - 10000, "Should receive token0 back");
        assertGt(amount1Out, amount1 - 10000, "Should receive token1 back");

        assertEq(IDotOneSwapV2Pair(pairAddres).balanceOf(address(this)), 0, "Should have 0 LP tokens left");
        assertEq(IDotOneSwapV2Pair(pairAddres).totalSupply(), 1000, "Total supply should remain as MINIMUM_LIQUIDITY");

    }

    function test_swap () public
    {
        address alice = makeAddr("alice"); 

        uint amount0 = 100 ether;
        uint amount1 = 100 ether;
        address pairAddres = factory.createPair(address(token0Contract), address(token1Contract));
        token0Contract.transfer(pairAddres, amount0);
        token1Contract.transfer(pairAddres, amount1);
        uint liquidity = IDotOneSwapV2Pair(pairAddres).mint(address(this));
        // --- Execute Swap ---
        // We want to swap Token0 for Token1
        uint256 swapAmountIn = 0.1 ether;
        token0Contract.transfer(pairAddres, swapAmountIn);

        uint256 amount1Out = 0.02 ether; 

        IDotOneSwapV2Pair(pairAddres).swap(0, amount1Out, alice, "");

        assertEq(token1Contract.balanceOf(alice), 0.02 ether );
    }
}

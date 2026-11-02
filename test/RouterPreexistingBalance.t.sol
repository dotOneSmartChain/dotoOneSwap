// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IDotOneSwapV2Factory, IDotOneSwapV2Pair, IDotOneSwapV2Router02, Deployer} from "./util/Deployer.sol";

/// @notice Fee-on-transfer router routes must not spend a balance left by an earlier call.
contract RouterPreexistingBalanceTest is Test {
    IDotOneSwapV2Factory internal factory;
    IDotOneSwapV2Router02 internal router;
    WethMock internal weth;

    function setUp() public {
        factory = Deployer.deployFactory(address(this));
        weth = new WethMock();
        router = Deployer.deployRouter(address(factory), address(weth));
    }

    function test_supportingEthSwap_leavesPreexistingWeth() public {
        Token token = new Token();
        address lp = makeAddr("lp");
        address caller = makeAddr("caller");
        token.mint(address(this), 100 ether);
        token.mint(caller, 1 ether);
        weth.deposit{value: 106 ether}();
        address pair = _seed(address(token), address(weth), 100 ether, 100 ether, lp);

        uint256 dust = 5 ether;
        weth.transfer(address(router), dust);
        uint256 expected = router.getAmountOut(1 ether, 100 ether, 100 ether);

        vm.startPrank(caller);
        token.approve(address(router), type(uint256).max);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            1 ether, 0, _path(address(token), address(weth)), caller, block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertEq(caller.balance, expected);
        assertEq(weth.balanceOf(address(router)), dust);
        assertEq(weth.balanceOf(pair), 100 ether - expected);
    }

    function test_supportingEthSwap_paysOutputWhenRouterStartsEmpty() public {
        Token token = new Token();
        address lp = makeAddr("lp");
        address caller = makeAddr("caller");
        token.mint(address(this), 100 ether);
        token.mint(caller, 1 ether);
        weth.deposit{value: 100 ether}();
        _seed(address(token), address(weth), 100 ether, 100 ether, lp);

        uint256 expected = router.getAmountOut(1 ether, 100 ether, 100 ether);

        vm.startPrank(caller);
        token.approve(address(router), type(uint256).max);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            1 ether, expected, _path(address(token), address(weth)), caller, block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertEq(caller.balance, expected);
        assertEq(weth.balanceOf(address(router)), 0);
    }

    function test_removeLiquidity_leavesPreexistingToken() public {
        Token token = new Token();
        address lp = makeAddr("lp");
        token.mint(address(this), 100 ether);
        weth.deposit{value: 100 ether}();
        address pair = _seed(address(token), address(weth), 100 ether, 100 ether, lp);

        uint256 dust = 5 ether;
        token.mint(address(router), dust);
        uint256 liquidity = IDotOneSwapV2Pair(pair).balanceOf(lp);
        uint256 pairBefore = token.balanceOf(pair);
        uint256 lpBefore = token.balanceOf(lp);

        vm.startPrank(lp);
        IDotOneSwapV2Pair(pair).approve(address(router), liquidity);
        router.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(token), liquidity, 0, 0, lp, block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertEq(token.balanceOf(lp) - lpBefore, pairBefore - token.balanceOf(pair));
        assertEq(token.balanceOf(address(router)), dust);
        assertGt(token.balanceOf(lp) - lpBefore, 0);
    }

    function test_removeLiquidity_leavesPreexistingWeth() public {
        Token token = new Token();
        address lp = makeAddr("lp");
        token.mint(address(this), 100 ether);
        weth.deposit{value: 110 ether}();
        address pair = _seed(address(token), address(weth), 100 ether, 100 ether, lp);

        uint256 dust = 7 ether;
        weth.transfer(address(router), dust);
        uint256 liquidity = IDotOneSwapV2Pair(pair).balanceOf(lp);
        uint256 ethBefore = lp.balance;

        vm.startPrank(lp);
        IDotOneSwapV2Pair(pair).approve(address(router), liquidity);
        router.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(token), liquidity, 0, 0, lp, block.timestamp + 1 hours
        );
        vm.stopPrank();

        assertEq(weth.balanceOf(address(router)), dust);
        assertGt(lp.balance - ethBefore, 0);
    }

    function _seed(address tokenA, address tokenB, uint256 amountA, uint256 amountB, address to)
        internal
        returns (address pair)
    {
        pair = factory.createPair(tokenA, tokenB);
        (bool okA,) = tokenA.call(abi.encodeWithSignature("transfer(address,uint256)", pair, amountA));
        (bool okB,) = tokenB.call(abi.encodeWithSignature("transfer(address,uint256)", pair, amountB));
        require(okA && okB, "seed");
        IDotOneSwapV2Pair(pair).mint(to);
    }

    function _path(address a, address b) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = a;
        path[1] = b;
    }
}

contract Token {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        return true;
    }
}

contract WethMock {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw(uint256 wad) external {
        balanceOf[msg.sender] -= wad;
        (bool ok,) = msg.sender.call{value: wad}("");
        require(ok, "weth withdraw");
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        return true;
    }

    receive() external payable {
        deposit();
    }
}

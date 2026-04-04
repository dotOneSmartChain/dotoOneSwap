pragma solidity >=0.5.0;

interface IDotOneSwapV2Callee {
    function DotOneSwapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

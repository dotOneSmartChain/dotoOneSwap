// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {IDotOneSwapV2Factory, IDotOneSwapV2ERC20} from "./Deployer.sol";

library Helpers {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function getDotOneSwapV2PairAddress(IDotOneSwapV2Factory factory, address token0, address token1)
        internal
        view
        returns (address create2Address)
    {
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes memory bytecode = abi.encodePacked(vm.getCode("DotOneSwapV2Pair.sol:DotOneSwapV2Pair"));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(factory), salt, keccak256(bytecode)));

        return address(uint160(uint256(hash)));
    }

    function getVRSForERC20Permit(
        IDotOneSwapV2ERC20 token,
        uint256 ownerPK,
        address owner,
        address spender,
        uint256 approvalAmount,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(token.PERMIT_TYPEHASH(), owner, spender, approvalAmount, token.nonces(owner), deadline)
                )
            )
        );
        (v, r, s) = vm.sign(ownerPK, digest);
    }
}

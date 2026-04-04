// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Test.sol";
import {Test, console} from "forge-std/Test.sol";
import {IDotOneSwapV2Factory} from "../../src/interfaces/IDotOneSwapV2Factory.sol";
import {IDotOneSwapV2Pair} from "../../src/interfaces/IDotOneSwapV2Pair.sol";
import {IDotOneSwapV2ERC20} from "../../src/interfaces/IDotOneSwapV2ERC20.sol";
import {IDotOneSwapV2Router02} from "../../src/interfaces/IDotOneSwapV2Router02.sol";

library Deployer {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function deployFactory(address _feeToSetter) internal returns (IDotOneSwapV2Factory factory) {
        bytes memory args = abi.encode(_feeToSetter);
        bytes memory bytecode = abi.encodePacked(vm.getCode("DotOneSwapV2Factory.sol:DotOneSwapV2Factory"), args);
        assembly {
            factory := create(0, add(bytecode, 32), mload(bytecode))
        }
    }

    function deployPair() internal returns (IDotOneSwapV2Pair pair) {
        bytes memory bytecode = abi.encodePacked(vm.getCode("DotOneSwapV2Pair.sol:DotOneSwapV2Pair"));
        assembly {
            pair := create(0, add(bytecode, 32), mload(bytecode))
        }
    }

    function getLogInitCodeHash() public {
        bytes memory bytecode = abi.encodePacked(vm.getCode("DotOneSwapV2Pair.sol:DotOneSwapV2Pair"));

        bytes32 initCodeHash = keccak256(bytecode);
    
        console.log("COPY THIS HASH INTO YOUR LIBRARY:");
        console.logBytes32(initCodeHash);
    }

    function deployERC20(uint256 mintAmount) internal returns (IDotOneSwapV2ERC20 erc20) {
        bytes memory args = abi.encode(mintAmount);
        bytes memory bytecode = abi.encodePacked(vm.getCode("ERC20.sol:ERC20"), args);
        assembly {
            erc20 := create(0, add(bytecode, 32), mload(bytecode))
        }
    }

    function deployRouter(address factory, address wrappedDot) internal returns (IDotOneSwapV2Router02 router) {
        bytes memory args = abi.encode(factory,wrappedDot);
        bytes memory bytecode = abi.encodePacked(vm.getCode("DotOneSwapV2Router02.sol:DotOneSwapV2Router02"), args);
        assembly {
            router := create(0, add(bytecode, 32), mload(bytecode))
        }
    }
}

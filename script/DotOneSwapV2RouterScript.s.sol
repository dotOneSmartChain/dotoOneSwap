// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IDotOneSwapV2Router02, Deployer} from "../test/util/Deployer.sol";


contract DotOneSwapV2RouterScript is Script {

    function setUp() public {}

    function run() public { 
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        address deployer = 0xf3EBB9a4E6DbE46e8e56Fb064aaD6b6b41748518;
        address factory = 0xD728243a996C615a44Eedcd40AE311083B9b9279;
        address wrappedDot = 0x1b6FFd37758092cD7867223e6Fd4f4C1aB50cD53;
        IDotOneSwapV2Router02 router = Deployer.deployRouter(factory, wrappedDot);
        console.log(address(router));
        vm.stopBroadcast();
    }
}

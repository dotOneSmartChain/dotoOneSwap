// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IDotOneSwapV2Factory, Deployer} from "../test/util/Deployer.sol";


contract DotOneSwapV2FactoryScript is Script {

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        address deployer = 0xf3EBB9a4E6DbE46e8e56Fb064aaD6b6b41748518;

        IDotOneSwapV2Factory factory = Deployer.deployFactory(deployer);

        console.log(address(factory));

        //new DotOneSwapV2Factory();

        vm.stopBroadcast();
    }
}

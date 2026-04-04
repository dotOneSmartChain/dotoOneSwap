// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IDotOneSwapV2Router02, Deployer} from "./util/Deployer.sol";
import {Helpers} from "./util/Helpers.sol";
import {Constants} from "./util/Constants.sol";
import {CustomToken} from "./util/CustomToken.sol";

abstract contract Deployed is Test {
    IDotOneSwapV2Router02 router;
    address factory  = 0x0f3812d6aF480ba23fe44104814a4dA1952A60A1;
    address weth  = 0x669708BDB53906C64E4Bf2Da5f4CF41dFc49A5BA;

    string public constant RPC_URL = "https://rpc-testnet.oilcoin.online";

    function setUpCustom(uint256 blockNumber) private {
        uint forkId = vm.createSelectFork(RPC_URL, blockNumber);

    }

    function setUp() public virtual {
        setUpCustom(484038);
        router = Deployer.deployRouter(factory,weth);
        
    }
}

contract DotOneSwapV2Rotuer is Deployed {

    

    //address uniswapRouterAddress = 0x752F75426fdC3079fB1a1AED9C73163E2A64E626;

   

    function test_routerMint() public  {

        
        Deployer.getLogInitCodeHash();

        address  usddAddress = 0x2Da502fa3219182c989D534B3CEc1D40DC18DC87;
        address  oilAddress = 0x3C8fb0291D7b2D9B03D2436f8681e2264A6036c5;

        
        vm.prank(0x9De16230e1d3120c80eC5a54CDcE91E71d94b444);
        CustomToken(usddAddress).approve(address(router) , 100 ether);

        vm.prank(0x9De16230e1d3120c80eC5a54CDcE91E71d94b444);
        CustomToken(oilAddress).approve(address(router) , 100 ether);

        vm.prank(0x9De16230e1d3120c80eC5a54CDcE91E71d94b444);
        router.addLiquidity
        (
            usddAddress,
            oilAddress,
            10 ether,
            10 ether,
            10 ether,
            10 ether,
            0x9De16230e1d3120c80eC5a54CDcE91E71d94b444,
            1865295015
        );
    }
}

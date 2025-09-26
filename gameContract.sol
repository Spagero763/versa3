// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VersaGames is Ownable {
    using SafeMath for uint256;

    uint256 public stakeAmount;
    uint256 public prizePool;
    uint256 public totalGamesPlayed;

    mapping(address => uint256) public activeStakes;
    mapping(address => bool) public hasPlayed;
    mapping(address => uint256) public lastPlayed;

    event GamePlayed(address indexed player, uint256 amount, uint256 timestamp);
    event PrizePoolFunded(uint256 amount);
    event StakeWithdrawn(address indexed player, uint256 amount);
    event PrizeClaimed(address indexed winner, uint256 amount);

    constructor(uint256 _initialStakeAmount) Ownable(msg.sender) {
        require(_initialStakeAmount > 0, "Stake amount must be greater than 0");
        stakeAmount = _initialStakeAmount;
    }

    function playGame() external payable {
        require(msg.value == stakeAmount, "Incorrect stake amount");
        require(!hasPlayed[msg.sender], "Already played in this round");

        activeStakes[msg.sender] = msg.value;
        hasPlayed[msg.sender] = true;
        lastPlayed[msg.sender] = block.timestamp;
        totalGamesPlayed++;

        // Transfer stake to prize pool (using SafeMath)
        prizePool = prizePool.add(msg.value);

        emit GamePlayed(msg.sender, msg.value, block.timestamp);
    }

    function fundPrizePool() external payable onlyOwner {
        require(msg.value > 0, "Must send ETH to fund the prize pool");
        prizePool = prizePool.add(msg.value);
        emit PrizePoolFunded(msg.value);
    }

    function withdrawStake() external {
        require(hasPlayed[msg.sender], "No active stake");
        require(block.timestamp.sub(lastPlayed[msg.sender]) >= 1 days, "Stake locked for 1 day");

        uint256 amount = activeStakes[msg.sender];
        activeStakes[msg.sender] = 0;
        hasPlayed[msg.sender] = false;

        payable(msg.sender).transfer(amount);
        emit StakeWithdrawn(msg.sender, amount);
    }

    function claimPrize() external onlyOwner {
        require(prizePool > 0, "No prize to claim");
        uint256 amount = prizePool;
        prizePool = 0;

        payable(owner()).transfer(amount);
        emit PrizeClaimed(owner(), amount);
    }

    // Helper function to check if a player can withdraw
    function canWithdraw(address player) external view returns (bool) {
        return hasPlayed[player] && block.timestamp.sub(lastPlayed[player]) >= 1 days;
    }
}
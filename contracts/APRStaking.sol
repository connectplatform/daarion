// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract APRStaking is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    ERC20Upgradeable public DAAR;
    ERC20Upgradeable public DAARION;
    uint256 public apr; // Fixed APR
    address public walletR; // Reserve wallet for APR-based rewards

    struct APRStake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => APRStake) public aprStakes;
    uint256 public totalStakedDAARION; // Total staked DAARION

    event APRStakeEvent(address indexed user, uint256 amount);
    event APRUnstakeEvent(address indexed user, uint256 amount);
    event APRRewardClaimed(address indexed user, uint256 reward);

    function initialize(address _DAAR, address _DAARION, address _walletR, address owner) public initializer {
        DAAR = ERC20Upgradeable(_DAAR);
        DAARION = ERC20Upgradeable(_DAARION);
        walletR = _walletR;
        apr = 4; // Initialize APR
        __Ownable_init(owner);
        __ReentrancyGuard_init();
    }

    function stakeAPR(uint256 _amount) external nonReentrant {
        require(DAARION.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        APRStake storage aprStakeRecord = aprStakes[msg.sender];
        aprStakeRecord.amount += _amount;
        aprStakeRecord.startTime = block.timestamp;

        totalStakedDAARION += _amount; // Update total staked DAARION
        emit APRStakeEvent(msg.sender, _amount);
    }

    function unstakeAPR(uint256 _amount) external nonReentrant {
        APRStake storage aprStakeRecord = aprStakes[msg.sender];
        require(aprStakeRecord.amount >= _amount, "Insufficient staked amount");

        uint256 reward = calculateAPRReward(msg.sender);
        require(DAAR.balanceOf(walletR) >= reward, "Insufficient reward balance in walletR");
        require(DAAR.transferFrom(walletR, msg.sender, reward), "Reward transfer failed");

        aprStakeRecord.amount -= _amount;
        require(DAARION.transfer(msg.sender, _amount), "Transfer failed");

        totalStakedDAARION -= _amount; // Update total staked DAARION
        emit APRUnstakeEvent(msg.sender, _amount);
        emit APRRewardClaimed(msg.sender, reward);
    }

    function calculateAPRReward(address staker) public view returns (uint256) {
        APRStake memory aprStakeRecord = aprStakes[staker];
        uint256 stakingDuration = block.timestamp - aprStakeRecord.startTime;
        uint256 reward = (aprStakeRecord.amount * apr * stakingDuration) / (100 * 365 days);
        return reward;
    }

    function getTotalStakedDAARION() external view returns (uint256) {
        return totalStakedDAARION;
    }
}

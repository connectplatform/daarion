// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract DAARDistributor is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IERC20Upgradeable public DAAR;
    IERC20Upgradeable public DAARION;
    uint256 public epochLength;
    uint256 public currentEpoch;
    address public walletR; // Reserve wallet for APR-based rewards
    uint256 public apr = 4; // Fixed APR of 4%

    struct Stake {
        uint256 amount;
        uint256 epoch;
        uint256 rewardDebt; // Tracks pending rewards
    }

    struct APRStake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake) public stakes;
    mapping(address => APRStake) public aprStakes;
    uint256 public totalStaked;
    uint256 public accRewardPerShare; // Accumulated rewards per staked token

    event DAARDistributed(uint256 epoch, uint256 totalStake, uint256 reward);
    event EpochLengthSet(uint256 newEpochLength);
    event StakeEvent(address indexed user, uint256 amount);
    event UnstakeEvent(address indexed user, uint256 amount);
    event APRStakeEvent(address indexed user, uint256 amount);
    event APRUnstakeEvent(address indexed user, uint256 amount);
    event ClaimRewardsEvent(address indexed user, uint256 reward);
    event APRRewardClaimed(address indexed user, uint256 reward);

    function initialize(address _DAAR, address _DAARION, uint256 _epochLength, address _walletR) public initializer {
        DAAR = IERC20Upgradeable(_DAAR);
        DAARION = IERC20Upgradeable(_DAARION);
        epochLength = _epochLength;
        walletR = _walletR;
        currentEpoch = block.timestamp / epochLength;
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setEpochLength(uint256 _epochLength) external onlyOwner {
        require(_epochLength > 0, "Epoch length must be greater than zero");
        epochLength = _epochLength;
        emit EpochLengthSet(_epochLength);
    }

    function stakeDAARION(uint256 _amount) external nonReentrant {
        updateEpoch();
        
        require(DAARION.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        Stake storage stakeRecord = stakes[msg.sender];
        if (stakeRecord.amount > 0) {
            uint256 pendingRewards = stakeRecord.amount * accRewardPerShare / 1e12 - stakeRecord.rewardDebt;
            if (pendingRewards > 0) {
                DAAR.transfer(msg.sender, pendingRewards);
            }
        }

        stakeRecord.amount += _amount;
        stakeRecord.rewardDebt = stakeRecord.amount * accRewardPerShare / 1e12;
        totalStaked += _amount;

        emit StakeEvent(msg.sender, _amount);
    }

    function unstakeDAARION(uint256 _amount) external nonReentrant {
        updateEpoch();

        Stake storage stakeRecord = stakes[msg.sender];
        require(stakeRecord.amount >= _amount, "Insufficient stake");

        uint256 pendingRewards = stakeRecord.amount * accRewardPerShare / 1e12 - stakeRecord.rewardDebt;
        if (pendingRewards > 0) {
            DAAR.transfer(msg.sender, pendingRewards);
        }

        stakeRecord.amount -= _amount;
        stakeRecord.rewardDebt = stakeRecord.amount * accRewardPerShare / 1e12;
        totalStaked -= _amount;

        require(DAARION.transfer(msg.sender, _amount), "Transfer failed");

        emit UnstakeEvent(msg.sender, _amount);
    }

    function claimRewards() external nonReentrant {
        updateEpoch();

        Stake storage stakeRecord = stakes[msg.sender];
        uint256 pendingRewards = stakeRecord.amount * accRewardPerShare / 1e12 - stakeRecord.rewardDebt;
        require(pendingRewards > 0, "No rewards available");

        DAAR.transfer(msg.sender, pendingRewards);

        stakeRecord.rewardDebt = stakeRecord.amount * accRewardPerShare / 1e12;

        emit ClaimRewardsEvent(msg.sender, pendingRewards);
    }

    function distributeDAAR() external onlyOwner {
        updateEpoch();

        uint256 reward = DAAR.balanceOf(address(this));
        if (reward > 0 && totalStaked > 0) {
            accRewardPerShare += reward * 1e12 / totalStaked;
        }

        emit DAARDistributed(currentEpoch, totalStaked, reward);
    }

    function updateEpoch() internal {
        uint256 newEpoch = block.timestamp / epochLength;
        if (newEpoch > currentEpoch) {
            currentEpoch = newEpoch;
        }
    }

    // APR-based staking functions
    function stakeAPR(uint256 _amount) external nonReentrant {
        require(DAARION.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        APRStake storage aprStakeRecord = aprStakes[msg.sender];
        aprStakeRecord.amount += _amount;
        aprStakeRecord.startTime = block.timestamp;

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

        emit APRUnstakeEvent(msg.sender, _amount);
        emit APRRewardClaimed(msg.sender, reward);
    }

    function calculateAPRReward(address staker) public view returns (uint256) {
        APRStake memory aprStakeRecord = aprStakes[staker];
        uint256 stakingDuration = block.timestamp - aprStakeRecord.startTime;
        uint256 reward = (aprStakeRecord.amount * apr * stakingDuration) / (100 * 365 days);
        return reward;
    }
}

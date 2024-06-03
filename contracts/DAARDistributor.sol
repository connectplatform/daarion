// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract DAARDistributor is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    ERC20Upgradeable public DAAR;
    ERC20Upgradeable public DAARION;
    uint256 public epochLength;
    uint256 public currentEpoch;

    struct Stake {
        uint256 amount;
        uint256 epoch;
        uint256 rewardDebt; // Tracks pending rewards
    }

    mapping(address => Stake) public stakes;
    uint256 public totalStaked;
    uint256 public accRewardPerShare; // Accumulated rewards per staked token

    event DAARDistributed(uint256 epoch, uint256 totalStake, uint256 reward);
    event EpochLengthSet(uint256 newEpochLength);
    event StakeEvent(address indexed user, uint256 amount);
    event UnstakeEvent(address indexed user, uint256 amount);
    event ClaimRewardsEvent(address indexed user, uint256 reward);

    function initialize(address _DAAR, address _DAARION, uint256 _epochLength, address _owner) public initializer {
        DAAR = ERC20Upgradeable(_DAAR);
        DAARION = ERC20Upgradeable(_DAARION);
        epochLength = _epochLength;
        currentEpoch = block.timestamp / epochLength;
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        transferOwnership(_owner);
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
}

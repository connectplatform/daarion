// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DAARDistributor is 
    Initializable, 
    ReentrancyGuardUpgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable 
{
    ERC20Upgradeable public DAAR;
    ERC20Upgradeable public DAARION;

    uint256 public totalStakedDAARION;
    uint256 public epochDuration;
    uint256 public lastEpochTimestamp;

    struct Stake {
        uint256 amount;
        uint256 lastClaimedEpoch;
    }

    mapping(address => Stake) public stakes;

    mapping(uint256 => uint256) public epochRewards;

    event StakeEvent(address indexed user, uint256 amount);
    event UnstakeEvent(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 indexed epoch, address[] recipients, uint256[] amounts);

    function initialize(
        address _DAAR, 
        address _DAARION, 
        address _wallet1, 
        uint256 _epochDuration
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init(_wallet1);
        __UUPSUpgradeable_init();

        require(_DAAR != address(0), "Invalid DAAR address");
        require(_DAARION != address(0), "Invalid DAARION address");
        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_epochDuration > 0, "Epoch duration must be greater than zero");

        DAAR = ERC20Upgradeable(_DAAR);
        DAARION = ERC20Upgradeable(_DAARION);
        epochDuration = _epochDuration;
        lastEpochTimestamp = block.timestamp;
        totalStakedDAARION = 0;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function stakeDAARION(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        Stake storage userStake = stakes[msg.sender];
        userStake.amount += amount;
        totalStakedDAARION += amount;
        require(DAARION.transferFrom(msg.sender, address(this), amount), "DAARION transfer failed");
        emit StakeEvent(msg.sender, amount);
    }

    function unstakeDAARION(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient stake");
        userStake.amount -= amount;
        totalStakedDAARION -= amount;
        require(DAARION.transfer(msg.sender, amount), "DAARION transfer failed");
        emit UnstakeEvent(msg.sender, amount);
    }

    function distributeRewards(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Array length mismatch");
        require(block.timestamp >= lastEpochTimestamp + epochDuration, "Epoch not ended");

        uint256 currentEpoch = getCurrentEpoch();
        uint256 totalReward = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalReward += amounts[i];
        }

        uint256 currentBalance = DAAR.balanceOf(address(this));
        require(totalReward <= currentBalance, "Insufficient DAAR balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(DAAR.transfer(recipients[i], amounts[i]), "DAAR transfer failed");
            stakes[recipients[i]].lastClaimedEpoch = currentEpoch;
        }

        epochRewards[currentEpoch] = totalReward;
        lastEpochTimestamp = block.timestamp;
        emit RewardsDistributed(currentEpoch, recipients, amounts);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp - lastEpochTimestamp) / epochDuration + 1;
    }

    function getPendingRewardsDAARDistributor(address user) external view returns (uint256) {
        Stake storage userStake = stakes[user];
        if (userStake.amount == 0) return 0;

        uint256 currentEpoch = getCurrentEpoch();
        if (userStake.lastClaimedEpoch >= currentEpoch) return 0;

        uint256 totalReward = 0;
        for (uint256 epoch = userStake.lastClaimedEpoch + 1; epoch <= currentEpoch; epoch++) {
            if (epochRewards[epoch] > 0 && totalStakedDAARION > 0) {
                totalReward += (userStake.amount * epochRewards[epoch]) / totalStakedDAARION;
            }
        }
        return totalReward;
    }

    uint256[50] private __gap;
}
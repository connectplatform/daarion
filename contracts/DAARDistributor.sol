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
    // Token interfaces
    ERC20Upgradeable public DAAR;      // DAAR token (reward token)
    ERC20Upgradeable public DAARION;   // DAARION token (staking token)

    // Staking and reward variables
    uint256 public totalStakedDAARION; // Total DAARION tokens staked
    uint256 public epochDuration;      // Duration of each epoch in seconds
    uint256 public lastEpochTimestamp; // Timestamp of the last epoch distribution

    // Staking data structure for DAARION
    struct Stake {
        uint256 amount;       // Amount of DAARION staked
        uint256 lastClaimedEpoch; // Epoch when rewards were last claimed
    }

    // Mapping of user address to their stake
    mapping(address => Stake) public stakes;

    // Epoch reward tracking
    mapping(uint256 => uint256) public epochRewards; // DAAR rewards per epoch

    // Events
    event StakeEvent(address indexed user, uint256 amount);
    event UnstakeEvent(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 indexed epoch, address[] recipients, uint256[] amounts);

    /**
     * @dev Initializes the contract with DAAR, DAARION, wallet1, and epoch duration.
     * @param _DAAR Address of the DAAR token contract.
     * @param _DAARION Address of the DAARION token contract.
     * @param _wallet1 Address authorized to own the contract.
     * @param _epochDuration Duration of each epoch in seconds.
     */
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

    /**
     * @dev UUPS upgrade authorization; only the owner can upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Stake DAARION tokens.
     */
    function stakeDAARION(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        Stake storage userStake = stakes[msg.sender];
        userStake.amount += amount;
        totalStakedDAARION += amount;
        require(DAARION.transferFrom(msg.sender, address(this), amount), "DAARION transfer failed");
        emit StakeEvent(msg.sender, amount);
    }

    /**
     * @dev Unstake DAARION tokens.
     */
    function unstakeDAARION(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient stake");
        userStake.amount -= amount;
        totalStakedDAARION -= amount;
        require(DAARION.transfer(msg.sender, amount), "DAARION transfer failed");
        emit UnstakeEvent(msg.sender, amount);
    }

    /**
     * @dev Distribute DAAR rewards for the current epoch to stakers (called by owner).
     * @param recipients List of staker addresses.
     * @param amounts List of DAAR reward amounts for each staker.
     */
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

    /**
     * @dev Get the current epoch number.
     * @return Current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp - lastEpochTimestamp) / epochDuration + 1;
    }

    /**
     * @dev Get pending rewards for a user (for off-chain calculation).
     * @param user Address of the user.
     * @return Pending DAAR rewards since last claimed epoch.
     */
    function getPendingRewards(address user) external view returns (uint256) {
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

    // Reserved storage space for future upgrades.
    uint256[50] private __gap;
}
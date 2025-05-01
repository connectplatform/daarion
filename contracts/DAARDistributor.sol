// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract DAARDistributor is 
    Initializable, 
    ReentrancyGuardUpgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable, 
    PausableUpgradeable 
{
    // Token interfaces
    ERC20Upgradeable public DAAR;      // DAAR token (reward token)
    ERC20Upgradeable public DAARION;   // DAARION token (staking token)

    // Reward calculation variables for DAARION staking
    uint256 public accRewardPerShare; // Accumulated reward per share for DAARION (scaled by 1e12)
    uint256 public totalStakedDAARION; // Total DAARION tokens staked

    uint256 public lastRewardBalance;  // Last recorded balance of DAAR for reward calculation

    // Epoch configuration
    uint256 public epochDuration;      // Duration of each epoch in seconds
    uint256 public lastEpochTimestamp; // Timestamp of the last epoch distribution

    // Address authorized to withdraw excess tokens
    address public wallet1;

    // Staking data structure for DAARION
    struct Stake {
        uint256 amount;       // Amount of DAARION staked
        uint256 rewardDebt;   // Reward debt (to prevent double claiming)
        uint256 rewardCredit; // Accumulated rewards ready to claim
    }

    // Mapping of user address to their stake
    mapping(address => Stake) public stakes;

    // Events
    event StakeEvent(address indexed user, uint256 amount);
    event UnstakeEvent(address indexed user, uint256 amount);
    event ClaimRewardsEvent(address indexed user, uint256 reward);
    event ExcessTokensWithdrawn(address indexed wallet1, uint256 amount, address token);
    event EpochDistributionTriggered(uint256 timestamp, uint256 rewardDistributed);

    /**
     * @dev Initializes the contract with DAAR, DAARION, wallet1, and epoch duration.
     * @param _DAAR Address of the DAAR token contract.
     * @param _DAARION Address of the DAARION token contract.
     * @param _wallet1 Address authorized to withdraw excess tokens and own the contract.
     * @param _epochDuration Duration of each epoch in seconds.
     */
    function initialize(
        address _DAAR, 
        address _DAARION, 
        address _wallet1, 
        uint256 _epochDuration
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init(_wallet1); // Set _wallet1 as the initial owner
        __UUPSUpgradeable_init();
        __Pausable_init();

        require(_DAAR != address(0), "Invalid DAAR address");
        require(_DAARION != address(0), "Invalid DAARION address");
        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_epochDuration > 0, "Epoch duration must be greater than zero");

        DAAR = ERC20Upgradeable(_DAAR);
        DAARION = ERC20Upgradeable(_DAARION);
        wallet1 = _wallet1;
        epochDuration = _epochDuration;
        lastEpochTimestamp = block.timestamp;

        accRewardPerShare = 0;
        totalStakedDAARION = 0;
        lastRewardBalance = 0;
    }

    /**
     * @dev UUPS upgrade authorization; only the owner can upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Pause the contract, preventing staking, unstaking, and claiming.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract, allowing staking, unstaking, and claiming.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Stake DAARION tokens.
     */
    function stakeDAARION(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        _updatePool();
        Stake storage userStake = stakes[msg.sender];
        if (userStake.amount > 0) {
            uint256 pendingReward = (userStake.amount * accRewardPerShare / 1e12) - userStake.rewardDebt;
            if (pendingReward > 0) {
                userStake.rewardCredit += pendingReward;
            }
        }
        require(DAARION.transferFrom(msg.sender, address(this), amount), "DAARION transfer failed");
        userStake.amount += amount;
        totalStakedDAARION += amount;
        userStake.rewardDebt = userStake.amount * accRewardPerShare / 1e12;
        emit StakeEvent(msg.sender, amount);
    }

    /**
     * @dev Unstake DAARION tokens.
     */
    function unstakeDAARION(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient stake");
        _updatePool();
        uint256 pendingReward = (userStake.amount * accRewardPerShare / 1e12) - userStake.rewardDebt;
        if (pendingReward > 0) {
            userStake.rewardCredit += pendingReward;
        }
        userStake.amount -= amount;
        totalStakedDAARION -= amount;
        userStake.rewardDebt = userStake.amount * accRewardPerShare / 1e12;
        require(DAARION.transfer(msg.sender, amount), "DAARION transfer failed");
        emit UnstakeEvent(msg.sender, amount);
    }

    /**
     * @dev Claim accumulated DAAR rewards.
     */
    function claimRewards() external nonReentrant whenNotPaused {
        _updatePool();
        Stake storage userStake = stakes[msg.sender];
        uint256 pendingReward = (userStake.amount * accRewardPerShare / 1e12) - userStake.rewardDebt;
        uint256 totalReward = userStake.rewardCredit + pendingReward;
        require(totalReward > 0, "No rewards to claim");
        userStake.rewardCredit = 0;
        userStake.rewardDebt = userStake.amount * accRewardPerShare / 1e12;
        require(DAAR.transfer(msg.sender, totalReward), "DAAR transfer failed");
        lastRewardBalance -= totalReward;
        emit ClaimRewardsEvent(msg.sender, totalReward);
    }

    /**
     * @dev Internal function to update the reward pool.
     */
    function _updatePool() internal {
        uint256 currentBalance = DAAR.balanceOf(address(this));
        uint256 reward = currentBalance > lastRewardBalance ? currentBalance - lastRewardBalance : 0;
        if (totalStakedDAARION > 0 && reward > 0) {
            accRewardPerShare += (reward * 1e12) / totalStakedDAARION;
            lastRewardBalance = currentBalance;
        } else if (reward > 0) {
            lastRewardBalance = currentBalance;
        }
    }

    /**
     * @dev Trigger the epoch distribution of DAAR rewards from walletD.
     */
    function triggerEpochDistribution() external onlyOwner {
        require(block.timestamp >= lastEpochTimestamp + epochDuration, "Epoch not ended");
        _updatePool();
        lastRewardBalance = DAAR.balanceOf(address(this));
        lastEpochTimestamp = block.timestamp;
        emit EpochDistributionTriggered(block.timestamp, lastRewardBalance);
    }

    /**
     * @dev Allows wallet1 to withdraw excess DAARION or DAAR tokens.
     * @param token Address of the token to withdraw (DAAR or DAARION)
     * @param amount Amount to withdraw
     */
    function withdrawExcessTokens(address token, uint256 amount) external {
        require(msg.sender == wallet1, "Only wallet1 can withdraw");
        require(token == address(DAAR) || token == address(DAARION), "Unsupported token");
        uint256 excess;
        if (token == address(DAARION)) {
            excess = DAARION.balanceOf(address(this)) - totalStakedDAARION;
        } else if (token == address(DAAR)) {
            excess = DAAR.balanceOf(address(this)) - lastRewardBalance;
        }
        require(amount <= excess, "Exceeds excess amount");
        require(ERC20Upgradeable(token).transfer(wallet1, amount), "Transfer failed");
        emit ExcessTokensWithdrawn(wallet1, amount, token);
    }

    /**
     * @dev Updates wallet1 address (only callable by current wallet1).
     * @param _newWallet1 The new address for wallet1.
     */
    function updateWallet1(address _newWallet1) external {
        require(msg.sender == wallet1, "Only wallet1 can update");
        require(_newWallet1 != address(0), "Invalid address");
        wallet1 = _newWallet1;
    }

    /**
     * @dev Get pending rewards for a user.
     * @param user Address of the user
     * @return Total pending DAAR rewards
     */
    function getPendingRewards(address user) external view returns (uint256) {
        Stake storage userStake = stakes[user];
        uint256 tempAccRewardPerShare = accRewardPerShare;
        uint256 currentBalance = DAAR.balanceOf(address(this));
        uint256 reward = currentBalance > lastRewardBalance ? currentBalance - lastRewardBalance : 0;
        if (totalStakedDAARION > 0 && reward > 0) {
            tempAccRewardPerShare += (reward * 1e12) / totalStakedDAARION;
        }
        uint256 pendingReward = (userStake.amount * tempAccRewardPerShare / 1e12) - userStake.rewardDebt;
        return userStake.rewardCredit + pendingReward;
    }

    // Reserved storage space for future upgrades.
    uint256[50] private __gap;
}
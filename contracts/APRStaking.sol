// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import OpenZeppelin upgradeable libraries
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract APRStaking is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    // ERC20 token interfaces
    ERC20Upgradeable public DAAR;      // DAAR token (reward token)
    ERC20Upgradeable public DAARION;   // DAARION token (staking token)

    // Reward calculation variables
    uint256 public accRewardPerShare;     // Accumulated reward per share (scaled by 1e12)
    uint256 public totalStakedDAARION;    // Total DAARION tokens staked
    uint256 public lastRewardBalance;     // Last recorded balance of DAAR for reward calculation

    // Staking data structure
    struct Stake {
        uint256 amount;       // Amount of DAARION staked
        uint256 rewardDebt;   // Reward debt (to prevent double claiming)
        uint256 rewardCredit; // Accumulated rewards ready to claim
    }

    // Mapping of user address to their stake
    mapping(address => Stake) public stakes;

    // Events for logging
    event StakeEvent(address indexed user, uint256 amount);
    event UnstakeEvent(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event ExcessTokensWithdrawn(address indexed owner, uint256 amount, address token);

    /**
     * @dev Initializer function (replaces constructor)
     * @param _daar Address of the DAAR token contract
     * @param _daarion Address of the DAARION token contract
     * @param _wallet1 Address of the initial owner (e.g., Gnosis Safe)
     */
    function initialize(
        address _daar,
        address _daarion,
        address _wallet1
    ) public initializer {
        __Ownable_init(_wallet1); // Set Gnosis Safe as owner
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(_daar != address(0), "Invalid DAAR address");
        require(_daarion != address(0), "Invalid DAARION address");
        DAAR = ERC20Upgradeable(_daar);
        DAARION = ERC20Upgradeable(_daarion);

        accRewardPerShare = 0;
        totalStakedDAARION = 0;
        lastRewardBalance = 0;
    }

    /**
     * @dev UUPS upgrade authorization function.
     * Only the owner can authorize an upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Stake DAARION tokens to earn DAAR rewards.
     * @param amount Amount of DAARION to stake
     */
    function stakeDAARION(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
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
     * @param amount Amount of DAARION to unstake
     */
    function unstakeDAARION(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked amount");

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
    function claimReward() external nonReentrant {
        _updatePool();

        Stake storage userStake = stakes[msg.sender];
        uint256 pendingReward = (userStake.amount * accRewardPerShare / 1e12) - userStake.rewardDebt;
        uint256 totalReward = userStake.rewardCredit + pendingReward;

        require(totalReward > 0, "No rewards to claim");

        userStake.rewardCredit = 0;
        userStake.rewardDebt = userStake.amount * accRewardPerShare / 1e12;

        require(DAAR.transfer(msg.sender, totalReward), "DAAR transfer failed");
        lastRewardBalance -= totalReward;

        emit RewardClaimed(msg.sender, totalReward);
    }

    /**
     * @dev Internal function to update the reward pool based on DAAR balance.
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
     * @dev Withdraw excess tokens (DAAR or DAARION) from the contract.
     * @param token Address of the token to withdraw (DAAR or DAARION)
     * @param amount Amount to withdraw
     */
    function withdrawExcessTokens(address token, uint256 amount) external onlyOwner {
        require(token == address(DAAR) || token == address(DAARION), "Unsupported token");
        require(amount > 0, "Amount must be greater than zero");

        uint256 availableBalance = ERC20Upgradeable(token).balanceOf(address(this));
        if (token == address(DAARION)) {
            require(availableBalance >= totalStakedDAARION + amount, "Insufficient excess DAARION");
        }
        require(ERC20Upgradeable(token).transfer(msg.sender, amount), "Transfer failed");

        if (token == address(DAAR)) {
            lastRewardBalance = availableBalance > amount ? availableBalance - amount : 0;
        }

        emit ExcessTokensWithdrawn(msg.sender, amount, token);
    }

    /**
     * @dev Get pending rewards for a user.
     * @param user Address of the user
     * @return Total pending DAAR rewards
     */
    function getPendingRewards(address user) external view returns (uint256) {
        Stake storage userStake = stakes[user];
        if (totalStakedDAARION == 0) return userStake.rewardCredit;

        uint256 currentBalance = DAAR.balanceOf(address(this));
        uint256 reward = currentBalance > lastRewardBalance ? currentBalance - lastRewardBalance : 0;
        uint256 tempAccRewardPerShare = accRewardPerShare;

        if (reward > 0) {
            tempAccRewardPerShare += (reward * 1e12) / totalStakedDAARION;
        }

        uint256 pendingReward = (userStake.amount * tempAccRewardPerShare / 1e12) - userStake.rewardDebt;
        return userStake.rewardCredit + pendingReward;
    }

    // Reserved storage gap for upgradeability
    uint256[50] private __gap;
}
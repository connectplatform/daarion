// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import OpenZeppelin upgradeable libraries
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract APRStaking is 
    Initializable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    UUPSUpgradeable 
{
    // ERC20 token interfaces
    ERC20Upgradeable public DAAR;      // DAAR token (reward and staking token)
    ERC20Upgradeable public DAARION;   // DAARION token (staking token)

    // Reward calculation variables for DAARION staking
    uint256 public accRewardPerShareDAARION; // Accumulated reward per share for DAARION (scaled by 1e12)
    uint256 public totalStakedDAARION;       // Total DAARION tokens staked

    // Reward calculation variables for DAAR staking
    uint256 public accRewardPerShareDAAR;    // Accumulated reward per share for DAAR (scaled by 1e12)
    uint256 public totalStakedDAAR;          // Total DAAR tokens staked

    uint256 public lastRewardBalance;        // Last recorded balance of DAAR for reward calculation

    // Staking data structures
    struct StakeDAARION {
        uint256 amount;       // Amount of DAARION staked
        uint256 rewardDebt;   // Reward debt (to prevent double claiming)
        uint256 rewardCredit; // Accumulated rewards ready to claim
    }

    struct StakeDAAR {
        uint256 amount;       // Amount of DAAR staked
        uint256 rewardDebt;   // Reward debt (to prevent double claiming)
        uint256 rewardCredit; // Accumulated rewards ready to claim
    }

    // Mappings of user address to their stakes
    mapping(address => StakeDAARION) public stakesDAARION;
    mapping(address => StakeDAAR) public stakesDAAR;

    // Events for logging
    event StakeDAARIONEvent(address indexed user, uint256 amount);
    event UnstakeDAARIONEvent(address indexed user, uint256 amount);
    event StakeDAAREvent(address indexed user, uint256 amount);
    event UnstakeDAAREvent(address indexed user, uint256 amount);
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
        __Pausable_init();        // Initialize pausable
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(_daar != address(0), "Invalid DAAR address");
        require(_daarion != address(0), "Invalid DAARION address");
        DAAR = ERC20Upgradeable(_daar);
        DAARION = ERC20Upgradeable(_daarion);

        accRewardPerShareDAARION = 0;
        accRewardPerShareDAAR = 0;
        totalStakedDAARION = 0;
        totalStakedDAAR = 0;
        lastRewardBalance = 0;
    }

    /**
     * @dev UUPS upgrade authorization function.
     * Only the owner can authorize an upgrade.
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
     * @dev Stake DAARION tokens to earn DAAR rewards.
     * @param amount Amount of DAARION to stake
     */
    function stakeDAARION(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _updatePoolDAARION();

        StakeDAARION storage userStake = stakesDAARION[msg.sender];
        if (userStake.amount > 0) {
            uint256 pendingReward = (userStake.amount * accRewardPerShareDAARION / 1e12) - userStake.rewardDebt;
            if (pendingReward > 0) {
                userStake.rewardCredit += pendingReward;
            }
        }

        require(DAARION.transferFrom(msg.sender, address(this), amount), "DAARION transfer failed");
        userStake.amount += amount;
        totalStakedDAARION += amount;
        userStake.rewardDebt = userStake.amount * accRewardPerShareDAARION / 1e12;

        emit StakeDAARIONEvent(msg.sender, amount);
    }

    /**
     * @dev Unstake DAARION tokens.
     * @param amount Amount of DAARION to unstake
     */
    function unstakeDAARION(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        StakeDAARION storage userStake = stakesDAARION[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked amount");

        _updatePoolDAARION();

        uint256 pendingReward = (userStake.amount * accRewardPerShareDAARION / 1e12) - userStake.rewardDebt;
        if (pendingReward > 0) {
            userStake.rewardCredit += pendingReward;
        }

        userStake.amount -= amount;
        totalStakedDAARION -= amount;
        userStake.rewardDebt = userStake.amount * accRewardPerShareDAARION / 1e12;

        require(DAARION.transfer(msg.sender, amount), "DAARION transfer failed");

        emit UnstakeDAARIONEvent(msg.sender, amount);
    }

    /**
     * @dev Stake DAAR tokens to earn DAAR rewards.
     * @param amount Amount of DAAR to stake
     */
    function stakeDAAR(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _updatePoolDAAR();

        StakeDAAR storage userStake = stakesDAAR[msg.sender];
        if (userStake.amount > 0) {
            uint256 pendingReward = (userStake.amount * accRewardPerShareDAAR / 1e12) - userStake.rewardDebt;
            if (pendingReward > 0) {
                userStake.rewardCredit += pendingReward;
            }
        }

        require(DAAR.transferFrom(msg.sender, address(this), amount), "DAAR transfer failed");
        userStake.amount += amount;
        totalStakedDAAR += amount;
        userStake.rewardDebt = userStake.amount * accRewardPerShareDAAR / 1e12;

        emit StakeDAAREvent(msg.sender, amount);
    }

    /**
     * @dev Unstake DAAR tokens.
     * @param amount Amount of DAAR to unstake
     */
    function unstakeDAAR(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        StakeDAAR storage userStake = stakesDAAR[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked amount");

        _updatePoolDAAR();

        uint256 pendingReward = (userStake.amount * accRewardPerShareDAAR / 1e12) - userStake.rewardDebt;
        if (pendingReward > 0) {
            userStake.rewardCredit += pendingReward;
        }

        userStake.amount -= amount;
        totalStakedDAAR -= amount;
        userStake.rewardDebt = userStake.amount * accRewardPerShareDAAR / 1e12;

        require(DAAR.transfer(msg.sender, amount), "DAAR transfer failed");

        emit UnstakeDAAREvent(msg.sender, amount);
    }

    /**
     * @dev Claim accumulated DAAR rewards from both staking pools.
     */
    function claimReward() external nonReentrant whenNotPaused {
        _updatePoolDAARION();
        _updatePoolDAAR();

        StakeDAARION storage userStakeDAARION = stakesDAARION[msg.sender];
        StakeDAAR storage userStakeDAAR = stakesDAAR[msg.sender];

        uint256 pendingRewardDAARION = (userStakeDAARION.amount * accRewardPerShareDAARION / 1e12) - userStakeDAARION.rewardDebt;
        uint256 totalRewardDAARION = userStakeDAARION.rewardCredit + pendingRewardDAARION;

        uint256 pendingRewardDAAR = (userStakeDAAR.amount * accRewardPerShareDAAR / 1e12) - userStakeDAAR.rewardDebt;
        uint256 totalRewardDAAR = userStakeDAAR.rewardCredit + pendingRewardDAAR;

        uint256 totalReward = totalRewardDAARION + totalRewardDAAR;

        require(totalReward > 0, "No rewards to claim");

        if (totalRewardDAARION > 0) {
            userStakeDAARION.rewardCredit = 0;
            userStakeDAARION.rewardDebt = userStakeDAARION.amount * accRewardPerShareDAARION / 1e12;
        }

        if (totalRewardDAAR > 0) {
            userStakeDAAR.rewardCredit = 0;
            userStakeDAAR.rewardDebt = userStakeDAAR.amount * accRewardPerShareDAAR / 1e12;
        }

        require(DAAR.transfer(msg.sender, totalReward), "DAAR transfer failed");
        lastRewardBalance -= totalReward;

        emit RewardClaimed(msg.sender, totalReward);
    }

    /**
     * @dev Internal function to update the reward pool for DAARION staking.
     */
    function _updatePoolDAARION() internal {
        uint256 currentBalance = DAAR.balanceOf(address(this));
        uint256 reward = currentBalance > lastRewardBalance ? currentBalance - lastRewardBalance : 0;

        if (totalStakedDAARION > 0 && reward > 0) {
            uint256 rewardShare = (reward * totalStakedDAARION) / (totalStakedDAARION + totalStakedDAAR);
            accRewardPerShareDAARION += (rewardShare * 1e12) / totalStakedDAARION;
        }
    }

    /**
     * @dev Internal function to update the reward pool for DAAR staking.
     */
    function _updatePoolDAAR() internal {
        uint256 currentBalance = DAAR.balanceOf(address(this));
        uint256 reward = currentBalance > lastRewardBalance ? currentBalance - lastRewardBalance : 0;

        if (totalStakedDAAR > 0 && reward > 0) {
            uint256 rewardShare = (reward * totalStakedDAAR) / (totalStakedDAARION + totalStakedDAAR);
            accRewardPerShareDAAR += (rewardShare * 1e12) / totalStakedDAAR;
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
        } else if (token == address(DAAR)) {
            require(availableBalance >= totalStakedDAAR + amount, "Insufficient excess DAAR");
        }
        require(ERC20Upgradeable(token).transfer(msg.sender, amount), "Transfer failed");

        if (token == address(DAAR)) {
            lastRewardBalance = availableBalance > amount ? availableBalance - amount : 0;
        }

        emit ExcessTokensWithdrawn(msg.sender, amount, token);
    }

    /**
     * @dev Get pending rewards for a user from both staking pools.
     * @param user Address of the user
     * @return Total pending DAAR rewards
     */
    function getPendingRewards(address user) external view returns (uint256) {
        StakeDAARION storage userStakeDAARION = stakesDAARION[user];
        StakeDAAR storage userStakeDAAR = stakesDAAR[user];

        uint256 tempAccRewardPerShareDAARION = accRewardPerShareDAARION;
        uint256 tempAccRewardPerShareDAAR = accRewardPerShareDAAR;

        uint256 currentBalance = DAAR.balanceOf(address(this));
        uint256 reward = currentBalance > lastRewardBalance ? currentBalance - lastRewardBalance : 0;

        if (reward > 0) {
            if (totalStakedDAARION > 0) {
                uint256 rewardShareDAARION = (reward * totalStakedDAARION) / (totalStakedDAARION + totalStakedDAAR);
                tempAccRewardPerShareDAARION += (rewardShareDAARION * 1e12) / totalStakedDAARION;
            }
            if (totalStakedDAAR > 0) {
                uint256 rewardShareDAAR = (reward * totalStakedDAAR) / (totalStakedDAARION + totalStakedDAAR);
                tempAccRewardPerShareDAAR += (rewardShareDAAR * 1e12) / totalStakedDAAR;
            }
        }

        uint256 pendingRewardDAARION = (userStakeDAARION.amount * tempAccRewardPerShareDAARION / 1e12) - userStakeDAARION.rewardDebt;
        uint256 totalRewardDAARION = userStakeDAARION.rewardCredit + pendingRewardDAARION;

        uint256 pendingRewardDAAR = (userStakeDAAR.amount * tempAccRewardPerShareDAAR / 1e12) - userStakeDAAR.rewardDebt;
        uint256 totalRewardDAAR = userStakeDAAR.rewardCredit + pendingRewardDAAR;

        return totalRewardDAARION + totalRewardDAAR;
    }

    // Reserved storage gap for upgradeability
    uint256[50] private __gap;
}
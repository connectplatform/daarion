// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import OpenZeppelin upgradeable contracts
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract DAARDistributor is
    Initializable,
    ReentrancyGuardUpgradeable
{
    // Token interfaces
    IERC20Upgradeable public DAAR;      // DAAR token (reward token)
    IERC20Upgradeable public DAARION;   // DAARION token (staking token)

    // Reward calculation variables
    uint256 public accRewardPerShare;   // Accumulated reward per share (scaled by 1e12)
    uint256 public totalStakedDAARION;  // Total amount of DAARION tokens staked

    // Tracking the last reward balance
    uint256 public lastRewardBalance;

    // Address authorized to withdraw excess DAARION tokens
    address public wallet1;

    // Staking data structure
    struct Stake {
        uint256 amount;        // Amount of DAARION staked
        uint256 rewardDebt;    // Reward debt for the user
        uint256 rewardCredit;  // Pending rewards
    }

    // Mapping of user address to their stake
    mapping(address => Stake) public stakes;

    // Events
    event StakeEvent(address indexed user, uint256 amount);
    event UnstakeEvent(address indexed user, uint256 amount);
    event ClaimRewardsEvent(address indexed user, uint256 reward);
    event ExcessDAARIONWithdrawn(address indexed wallet1, uint256 amount);

    /**
     * @dev Initialize the contract with DAAR and DAARION token addresses and set wallet1
     * @param _DAAR Address of the DAAR token contract
     * @param _DAARION Address of the DAARION token contract
     * @param _wallet1 Address authorized to withdraw excess DAARION tokens
     */
    function initialize(address _DAAR, address _DAARION, address _wallet1) public initializer {
        __ReentrancyGuard_init();
        
        DAAR = IERC20Upgradeable(_DAAR);
        DAARION = IERC20Upgradeable(_DAARION);
        wallet1 = _wallet1;
        accRewardPerShare = 0;
        lastRewardBalance = 0;
    }

    /**
     * @dev Stake DAARION tokens
     * @param amount Amount of DAARION tokens to stake
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

        // Transfer DAARION tokens from user to contract
        DAARION.transferFrom(msg.sender, address(this), amount);

        // Update user stake and total staked
        userStake.amount += amount;
        totalStakedDAARION += amount;

        // Update reward debt
        userStake.rewardDebt = userStake.amount * accRewardPerShare / 1e12;

        emit StakeEvent(msg.sender, amount);
    }

    /**
     * @dev Unstake DAARION tokens
     * @param amount Amount of DAARION tokens to unstake
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

        // Update user stake and total staked
        userStake.amount -= amount;
        totalStakedDAARION -= amount;

        // Update reward debt
        userStake.rewardDebt = userStake.amount * accRewardPerShare / 1e12;

        // Transfer DAARION tokens back to user
        DAARION.transfer(msg.sender, amount);

        emit UnstakeEvent(msg.sender, amount);
    }

    /**
     * @dev Claim accumulated DAAR rewards
     */
    function claimRewards() external nonReentrant {
        _updatePool();

        Stake storage userStake = stakes[msg.sender];

        uint256 pendingReward = (userStake.amount * accRewardPerShare / 1e12) - userStake.rewardDebt;
        uint256 reward = userStake.rewardCredit + pendingReward;

        require(reward > 0, "No rewards to claim");

        // Reset user's reward credit and update reward debt
        userStake.rewardCredit = 0;
        userStake.rewardDebt = userStake.amount * accRewardPerShare / 1e12;

        // Transfer DAAR tokens to user
        DAAR.transfer(msg.sender, reward);

        // Update last reward balance
        lastRewardBalance -= reward;

        emit ClaimRewardsEvent(msg.sender, reward);
    }

    /**
     * @dev Internal function to update the reward pool
     */
    function _updatePool() internal {
        uint256 currentBalance = DAAR.balanceOf(address(this));
        uint256 reward = currentBalance - lastRewardBalance;

        if (totalStakedDAARION > 0 && reward > 0) {
            accRewardPerShare += (reward * 1e12) / totalStakedDAARION;
            lastRewardBalance = currentBalance;
        } else if (reward > 0) {
            // If there are rewards but no stakers, update lastRewardBalance
            lastRewardBalance = currentBalance;
        }
    }

    /**
     * @dev Allows wallet1 to withdraw excess DAARION tokens (not staked by users)
     * @param amount Amount of excess DAARION tokens to withdraw
     */
    function withdrawExcessDAARION(uint256 amount) external {
        require(msg.sender == wallet1, "Only wallet1 can withdraw excess DAARION");

        uint256 excess = DAARION.balanceOf(address(this)) - totalStakedDAARION;
        require(amount <= excess, "Amount exceeds excess DAARION");

        // Transfer excess DAARION tokens to wallet1
        DAARION.transfer(wallet1, amount);

        // Emit an event for transparency
        emit ExcessDAARIONWithdrawn(wallet1, amount);
    }

    /**
     * @dev Optional: Function to update wallet1 address (only callable by current wallet1)
     * @param _newWallet1 The new address for wallet1
     */
    function updateWallet1(address _newWallet1) external {
        require(msg.sender == wallet1, "Only wallet1 can update its address");
        require(_newWallet1 != address(0), "Invalid address");
        wallet1 = _newWallet1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol"; // Corrected path
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DAARDistributor is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // Token interfaces
    ERC20Upgradeable public DAAR;      // DAAR token (reward token)
    ERC20Upgradeable public DAARION;   // DAARION token (staking token)

    // Reward calculation variables
    uint256 public accRewardPerShare;     // Accumulated reward per share (scaled by 1e12)
    uint256 public totalStakedDAARION;    // Total DAARION tokens staked

    // Tracking last reward balance
    uint256 public lastRewardBalance;

    // Address authorized to withdraw excess DAARION tokens
    address public wallet1;

    // Staking data structure
    struct Stake {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardCredit;
    }

    // Mapping of user address to their stake
    mapping(address => Stake) public stakes;

    // Events
    event StakeEvent(address indexed user, uint256 amount);
    event UnstakeEvent(address indexed user, uint256 amount);
    event ClaimRewardsEvent(address indexed user, uint256 reward);
    event ExcessDAARIONWithdrawn(address indexed wallet1, uint256 amount);

    /**
     * @dev Initializes the contract with DAAR and DAARION addresses and sets wallet1.
     * @param _DAAR Address of the DAAR token contract.
     * @param _DAARION Address of the DAARION token contract.
     * @param _wallet1 Address authorized to withdraw excess DAARION tokens and own the contract.
     */
    function initialize(address _DAAR, address _DAARION, address _wallet1) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init(_wallet1); // Set _wallet1 as the initial owner
        __UUPSUpgradeable_init();

        DAAR = ERC20Upgradeable(_DAAR);
        DAARION = ERC20Upgradeable(_DAARION);
        wallet1 = _wallet1;
        accRewardPerShare = 0;
        lastRewardBalance = 0;
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
        _updatePool();
        Stake storage userStake = stakes[msg.sender];
        if (userStake.amount > 0) {
            uint256 pendingReward = (userStake.amount * accRewardPerShare / 1e12) - userStake.rewardDebt;
            if (pendingReward > 0) {
                userStake.rewardCredit += pendingReward;
            }
        }
        DAARION.transferFrom(msg.sender, address(this), amount);
        userStake.amount += amount;
        totalStakedDAARION += amount;
        userStake.rewardDebt = userStake.amount * accRewardPerShare / 1e12;
        emit StakeEvent(msg.sender, amount);
    }

    /**
     * @dev Unstake DAARION tokens.
     */
    function unstakeDAARION(uint256 amount) external nonReentrant {
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
        DAARION.transfer(msg.sender, amount);
        emit UnstakeEvent(msg.sender, amount);
    }

    /**
     * @dev Claim accumulated DAAR rewards.
     */
    function claimRewards() external nonReentrant {
        _updatePool();
        Stake storage userStake = stakes[msg.sender];
        uint256 pendingReward = (userStake.amount * accRewardPerShare / 1e12) - userStake.rewardDebt;
        uint256 reward = userStake.rewardCredit + pendingReward;
        require(reward > 0, "No rewards");
        userStake.rewardCredit = 0;
        userStake.rewardDebt = userStake.amount * accRewardPerShare / 1e12;
        DAAR.transfer(msg.sender, reward);
        lastRewardBalance -= reward;
        emit ClaimRewardsEvent(msg.sender, reward);
    }

    /**
     * @dev Internal function to update the reward pool.
     */
    function _updatePool() internal {
        uint256 currentBalance = DAAR.balanceOf(address(this));
        uint256 reward = currentBalance - lastRewardBalance;
        if (totalStakedDAARION > 0 && reward > 0) {
            accRewardPerShare += (reward * 1e12) / totalStakedDAARION;
            lastRewardBalance = currentBalance;
        } else if (reward > 0) {
            lastRewardBalance = currentBalance;
        }
    }

    /**
     * @dev Allows wallet1 to withdraw excess DAARION tokens.
     * @param amount Amount of excess DAARION tokens to withdraw.
     */
    function withdrawExcessDAARION(uint256 amount) external {
        require(msg.sender == wallet1, "Only wallet1 can withdraw");
        uint256 excess = DAARION.balanceOf(address(this)) - totalStakedDAARION;
        require(amount <= excess, "Exceeds excess amount");
        DAARION.transfer(wallet1, amount);
        emit ExcessDAARIONWithdrawn(wallet1, amount);
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

    // Reserved storage space for future upgrades.
    uint256[50] private __gap;
}
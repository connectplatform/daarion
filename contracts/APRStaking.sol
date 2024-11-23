// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import OpenZeppelin libraries
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract APRStaking is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // ERC20 token interfaces
    IERC20 public DAAR;
    IERC20 public DAARION;

    // Annual Percentage Rates (in basis points, e.g., 500 = 5%)
    uint256 public aprDAAR;
    uint256 public aprDAARION;

    // Struct to hold staking information
    struct APRStake {
        uint256 amount;      // Amount staked
        uint256 startTime;   // Timestamp when staking started or was last updated
        uint256 reward;      // Accumulated rewards
    }

    // Mapping of user address => token address => stake data
    mapping(address => mapping(address => APRStake)) public aprStakes;

    // Events for logging
    event APRStakeEvent(address indexed user, uint256 amount, address token);
    event APRUnstakeEvent(address indexed user, uint256 amount, address token);
    event APRRewardClaimed(address indexed user, uint256 reward, address token);

    // Initialize the contract
    function initialize(
        address _DAAR,
        address _DAARION,
        uint256 _aprDAAR,
        uint256 _aprDAARION
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        DAAR = IERC20(_DAAR);
        DAARION = IERC20(_DAARION);
        aprDAAR = _aprDAAR;
        aprDAARION = _aprDAARION;
    }

    // Set APR for DAAR
    function setAPRDAAR(uint256 _aprDAAR) external onlyOwner {
        aprDAAR = _aprDAAR;
    }

    // Set APR for DAARION
    function setAPRDAARION(uint256 _aprDAARION) external onlyOwner {
        aprDAARION = _aprDAARION;
    }

    // Stake tokens (token can be DAAR or DAARION)
    function stakeAPR(uint256 amount, address token) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(token == address(DAAR) || token == address(DAARION), "Unsupported token");

        // Update rewards before modifying staked amount
        _updateReward(msg.sender, token);

        APRStake storage stakeData = aprStakes[msg.sender][token];

        // Transfer tokens from the user to the contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Update staked amount and start time
        stakeData.amount += amount;
        stakeData.startTime = block.timestamp;

        emit APRStakeEvent(msg.sender, amount, token);
    }

    // Unstake tokens
    function unstakeAPR(uint256 amount, address token) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(token == address(DAAR) || token == address(DAARION), "Unsupported token");

        APRStake storage stakeData = aprStakes[msg.sender][token];

        require(stakeData.amount >= amount, "Insufficient staked amount");

        // Update rewards before modifying staked amount
        _updateReward(msg.sender, token);

        // Update staked amount
        stakeData.amount -= amount;

        // Transfer tokens back to the user
        IERC20(token).transfer(msg.sender, amount);

        // Update start time
        stakeData.startTime = block.timestamp;

        emit APRUnstakeEvent(msg.sender, amount, token);
    }

    // Claim accumulated rewards
    function claimReward(address token) external nonReentrant {
        require(token == address(DAAR) || token == address(DAARION), "Unsupported token");

        APRStake storage stakeData = aprStakes[msg.sender][token];

        // Update rewards before claiming
        _updateReward(msg.sender, token);

        uint256 reward = stakeData.reward;
        require(reward > 0, "No rewards to claim");

        // Reset accumulated rewards
        stakeData.reward = 0;

        // Transfer rewards from contract's balance to user
        IERC20(token).transfer(msg.sender, reward);

        emit APRRewardClaimed(msg.sender, reward, token);
    }

    // Internal function to update rewards
    function _updateReward(address staker, address token) internal {
        APRStake storage stakeData = aprStakes[staker][token];

        if (stakeData.amount == 0) {
            stakeData.startTime = block.timestamp;
            return;
        }

        uint256 reward = calculateAPRReward(staker, token);
        stakeData.reward += reward;
        stakeData.startTime = block.timestamp;
    }

    // Calculate the reward for a user and token
    function calculateAPRReward(address staker, address token) public view returns (uint256) {
        APRStake storage stakeData = aprStakes[staker][token];

        uint256 timeStaked = block.timestamp - stakeData.startTime;
        uint256 aprRate = token == address(DAAR) ? aprDAAR : aprDAARION;

        // Reward calculation: (staked amount * APR * time staked) / (365 days * 10000)
        return (stakeData.amount * aprRate * timeStaked) / (365 days * 10000);
    }

    // Optional: Function to allow the owner to withdraw excess tokens from the contract
    function withdrawExcessTokens(address token, uint256 amount) external onlyOwner {
        require(token == address(DAAR) || token == address(DAARION), "Unsupported token");
        require(amount > 0, "Amount must be greater than zero");

        IERC20(token).transfer(msg.sender, amount);
    }
}

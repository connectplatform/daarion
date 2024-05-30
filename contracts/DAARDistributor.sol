// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAARDistributor is Ownable {
    IERC20 public DAAR;
    IERC20 public DAARION;
    uint256 public epochLength; // Length of an epoch in seconds

    struct Epoch {
        uint256 totalStake;
        uint256 reward;
        uint256 timestamp;
    }
    
    mapping(address => uint256) public stakedAmount;
    Epoch[] public epochs;

    event DAARDistributed(uint256 epochIndex, uint256 totalStake, uint256 reward);
    event EpochLengthSet(uint256 newEpochLength);

    constructor(address _DAAR, address _DAARION, uint256 _epochLength) {
        DAAR = IERC20(_DAAR);
        DAARION = IERC20(_DAARION);
        epochLength = _epochLength;
    }

    function setEpochLength(uint256 _epochLength) external onlyOwner {
        require(_epochLength > 0, "Epoch length must be greater than zero");
        epochLength = _epochLength;
        emit EpochLengthSet(_epochLength);
    }

    function distributeDAAR() external onlyOwner {
        uint256 totalStake = getTotalStake();
        uint256 reward = DAAR.balanceOf(address(this));
        epochs.push(Epoch(totalStake, reward, block.timestamp));

        for (uint256 i = 0; i < epochs.length; i++) {
            Epoch storage epoch = epochs[i];
            if (block.timestamp >= epoch.timestamp + epochLength) {
                uint256 rewardPerToken = epoch.reward / epoch.totalStake;
                for (uint256 j = 0; j < epochs.length; j++) {
                    address account = getAccount(j);
                    uint256 stake = stakedAmount[account];
                    DAAR.transfer(account, stake * rewardPerToken);
                }
                emit DAARDistributed(i, epoch.totalStake, epoch.reward);
            }
        }
    }

    function stakeDAARION(uint256 _amount) external {
        require(DAARION.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        stakedAmount[msg.sender] += _amount;
    }

    function unstakeDAARION(uint256 _amount) external {
        require(stakedAmount[msg.sender] >= _amount, "Insufficient stake");
        stakedAmount[msg.sender] -= _amount;
        require(DAARION.transfer(msg.sender, _amount), "Transfer failed");
    }

    function getTotalStake() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < epochs.length; i++) {
            total += stakedAmount[getAccount(i)];
        }
        return total;
    }

    function getAccount(uint256 _index) public view returns (address) {
        return address(uint160(_index));
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAARDistributor is Ownable {
    IERC20 public daar;
    IERC20 public daarion;

    struct Epoch {
        uint256 totalDAARAccumulated;
        uint256 timestamp;
    }

    Epoch[] public epochs;
    uint256 public currentEpoch;

    constructor(address _daar, address _daarion) {
        daar = IERC20(_daar);
        daarion = IERC20(_daarion);
        currentEpoch = 0;
    }

    function distribute() public onlyOwner {
        // Get the total DAAR accumulated in walletD
        uint256 totalDAAR = daar.balanceOf(address(this));

        require(totalDAAR > 0, "No DAAR to distribute");

        Epoch memory epoch = Epoch({
            totalDAARAccumulated: totalDAAR,
            timestamp: block.timestamp
        });

        epochs.push(epoch);

        // Get the total supply of DAARION
        uint256 totalDAARIONSupply = daarion.totalSupply();

        address[] memory holders = new address[](totalDAARIONSupply);
        uint256[] memory amounts = new uint256[](totalDAARIONSupply);
        
        uint256 index = 0;
        for (uint256 i = 0; i < totalDAARIONSupply; i++) {
            address holder = daarion.holderAt(i);
            uint256 balance = daarion.balanceOf(holder);

            if (balance > 0) {
                // Calculate the share of DAAR based on the stake
                uint256 share = (totalDAAR * balance) / totalDAARIONSupply;

                holders[index] = holder;
                amounts[index] = share;
                index++;
            }
        }

        daar.distributeDAAR(holders, amounts);

        // Increment the current epoch
        currentEpoch++;
    }

    function setDAAR(address _daar) external onlyOwner {
        daar = IERC20(_daar);
    }

    function setDAARION(address _daarion) external onlyOwner {
        daarion = IERC20(_daarion);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DAARION is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public wallet1;
    address public walletD;
    IERC20 public daarToken;

    EnumerableSet.AddressSet private holders;

    uint256 public constant FEE_PERCENTAGE = 5; 
    uint256 public constant BURN_PERCENTAGE = 50; 
    uint256 public lastDistributed;

    event Burn(address indexed burner, uint256 burnedAmount);
    event FeeTransferred(address indexed from, uint256 feeAmount, uint256 amountAfterFee);
    event HolderUpdated(address indexed holder, bool isAdded);

    constructor(address _wallet1, address _walletD, address _daarToken, address _initialOwner) ERC20("DAARION", "DAARION") 
Ownable(_initialOwner) {
        require(_wallet1 != address(0) && _walletD != address(0) && _daarToken != address(0), "Invalid addresses");
        wallet1 = _wallet1;
        walletD = _walletD;
        daarToken = IERC20(_daarToken);
        lastDistributed = block.timestamp;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (msg.sender != wallet1 && recipient != wallet1) {
            uint256 feeAmount = _calculateFee(amount, FEE_PERCENTAGE);
            uint256 burnAmount = _calculateFee(amount, BURN_PERCENTAGE);
            uint256 transferAmount = amount - feeAmount - burnAmount;

            _burn(_msgSender(), burnAmount);
            _executeTransfer(_msgSender(), walletD, feeAmount);
            _executeTransfer(_msgSender(), recipient, transferAmount);

            _updateHolders(_msgSender(), recipient);

            emit FeeTransferred(_msgSender(), feeAmount, transferAmount);
            emit Burn(_msgSender(), burnAmount);
        } else {
            require(super.transfer(recipient, amount), "Transfer failed");
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (sender != wallet1 && recipient != wallet1) {
            uint256 feeAmount = _calculateFee(amount, FEE_PERCENTAGE);
            uint256 burnAmount = _calculateFee(amount, BURN_PERCENTAGE);
            uint256 transferAmount = amount - feeAmount - burnAmount;

            _burn(sender, burnAmount);
            _executeTransfer(sender, walletD, feeAmount);
            _executeTransfer(sender, recipient, transferAmount);

            _updateHolders(sender, recipient);
            _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);

            emit FeeTransferred(sender, feeAmount, transferAmount);
            emit Burn(sender, burnAmount);
        } else {
            require(super.transferFrom(sender, recipient, amount), "TransferFrom failed");
        }
        return true;
    }

    function distributeFees() external nonReentrant {
        require(block.timestamp >= lastDistributed + 1 weeks, "Distribution allowed once a week");

        uint256 balance = daarToken.balanceOf(walletD);
        uint256 totalSupplyExcludingWallet1 = totalSupply() - balanceOf(wallet1);
        require(totalSupplyExcludingWallet1 > 0, "No tokens to distribute");

        for (uint256 i = 0; i < holders.length(); i++) {
            address holder = holders.at(i);
            if (holder != wallet1) {
                uint256 holderBalance = balanceOf(holder);
                uint256 amount = (balance * holderBalance) / totalSupplyExcludingWallet1;
                daarToken.safeTransferFrom(walletD, holder, amount);
            }
        }

        lastDistributed = block.timestamp;
    }

    function _calculateFee(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return (amount * percentage) / 1000;
    }

    function _executeTransfer(address from, address to, uint256 amount) internal {
        _transfer(from, to, amount);
    }

    function _updateHolders(address sender, address recipient) internal {
        if (balanceOf(sender) == 0) {
            holders.remove(sender);
            emit HolderUpdated(sender, false);
        }
        if (balanceOf(recipient) > 0) {
            holders.add(recipient);
            emit HolderUpdated(recipient, true);
        }
    }

    function setWallet1(address _wallet1) external onlyOwner {
        require(_wallet1 != address(0), "Invalid Wallet1 address");
        wallet1 = _wallet1;
    }

    function setWalletD(address _walletD) external onlyOwner {
        require(_walletD != address(0), "Invalid WalletD address");
        walletD = _walletD;
    }

    function setDaarToken(address _daarToken) external onlyOwner {
        require(_daarToken != address(0), "Invalid DaarToken address");
        daarToken = IERC20(_daarToken);
    }
}


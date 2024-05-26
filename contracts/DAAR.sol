// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAAR is ERC20, Ownable {
    address public walletD;
    uint256 public constant FEE_PERCENTAGE = 5; // 0.5% represented as 5 (0.5 * 10)

    event FeeTransferred(address indexed from, uint256 feeAmount, uint256 amountAfterFee);

    constructor(address _walletD, address _initialOwner) ERC20("DAAR", "DAAR") Ownable(_initialOwner) {
        require(_walletD != address(0), "Invalid WalletD address");
        walletD = _walletD;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 feeAmount = _calculateFee(amount);
        uint256 amountAfterFee = amount - feeAmount;

        _executeTransfer(_msgSender(), walletD, feeAmount);
        _executeTransfer(_msgSender(), recipient, amountAfterFee);

        emit FeeTransferred(_msgSender(), feeAmount, amountAfterFee);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 feeAmount = _calculateFee(amount);
        uint256 amountAfterFee = amount - feeAmount;

        _executeTransfer(sender, walletD, feeAmount);
        _executeTransfer(sender, recipient, amountAfterFee);

        _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);

        emit FeeTransferred(sender, feeAmount, amountAfterFee);

        return true;
    }

    function _calculateFee(uint256 amount) internal pure returns (uint256) {
        return amount * FEE_PERCENTAGE / 1000;
    }

    function _executeTransfer(address from, address to, uint256 amount) internal {
        _transfer(from, to, amount);
    }

    function setWalletD(address _walletD) external onlyOwner {
        require(_walletD != address(0), "Invalid WalletD address");
        walletD = _walletD;
    }
}


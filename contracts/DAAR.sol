// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DAAR is ERC20, ERC20Burnable, Pausable, Ownable {
    address public walletD;
    uint256 public transactionFee = 50; // 0.5%
    mapping(address => bool) private _isExcludedFromFee;
    address public distributor; // Authorized distributor contract

    constructor(address _walletD) ERC20("DAAR", "DAAR") {
        walletD = _walletD;
        _isExcludedFromFee[owner()] = true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            super._transfer(sender, recipient, amount);
        } else {
            uint256 feeAmount = amount * transactionFee / 10000; // calculate 0.5% fee
            uint256 transferAmount = amount - feeAmount;
            super._transfer(sender, walletD, feeAmount);
            super._transfer(sender, recipient, transferAmount);
        }
    }

    function setTransactionFee(uint256 fee) external onlyOwner {
        require(fee <= 100, "Fee cannot exceed 1%");
        transactionFee = fee;
    }

    function setWalletD(address _walletD) external onlyOwner {
        walletD = _walletD;
    }

    function setDistributor(address _distributor) external onlyOwner {
        distributor = _distributor;
    }

    function distributeDAAR(address[] calldata recipients, uint256[] calldata amounts) external {
        require(msg.sender == distributor, "Only the authorized distributor can distribute DAAR");
        require(recipients.length == amounts.length, "Mismatched arrays");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(walletD, recipients[i], amounts[i]);
        }
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public override onlyOwner {
        _burn(_msgSender(), amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
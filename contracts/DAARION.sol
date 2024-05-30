// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DAARION is ERC20, ERC20Burnable, Pausable, Ownable {
    address public wallet1;
    uint256 public salesTax = 500; // 5%
    mapping(address => bool) private _isExcludedFromTax;
    address[] internal _holders; // List of holders
    mapping(address => bool) internal _isHolder; // Ensure no duplicates

    constructor(address _wallet1) ERC20("DAARION", "DAR") {
        wallet1 = _wallet1;
        _isExcludedFromTax[wallet1] = true;
        _isExcludedFromTax[owner()] = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != address(0) && balanceOf(from) == amount) {
            // When transferring all tokens, remove the holder
            _isHolder[from] = false;
        }
        if (to != address(0) && !_isHolder[to]) {
            // Add new holder
            _holders.push(to);
            _isHolder[to] = true;
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function getHolders() external view returns (address[] memory) {
        return _holders;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (_isExcludedFromTax[sender] || _isExcludedFromTax[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 taxAmount = amount * salesTax / 10000; // calculate 5% tax
            uint256 transferAmount = amount - taxAmount;
            super._transfer(sender, address(0), taxAmount); // burn tax amount
            super._transfer(sender, recipient, transferAmount);
        }
    }

    function setSalesTax(uint256 tax) external onlyOwner {
        require(tax <= 500, "Tax cannot exceed 5%");
        salesTax = tax;
    }

    function setWallet1(address _wallet1) external onlyOwner {
        wallet1 = _wallet1;
    }

    function excludeFromTax(address account) external onlyOwner {
        _isExcludedFromTax[account] = true;
    }

    function includeInTax(address account) external onlyOwner {
        _isExcludedFromTax[account] = false;
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
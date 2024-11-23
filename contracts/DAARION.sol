// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract DAARION is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public salesTax;

    mapping(address => bool) private _isExcludedFromTax;
    address public wallet1;
    address public walletD;
    address public walletR;

    event SalesTaxSet(uint256 newTax);
    event ExcludedFromTax(address account);
    event IncludedInTax(address account);
    event TransferWithTax(address indexed sender, address indexed recipient, uint256 amount, uint256 taxAmount);

    function initialize(address _wallet1, address _walletD, address _walletR) public initializer {
        __ERC20_init("DAARION", "DAARION");
        __ERC20Burnable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        __Ownable_init();

        // Transfer ownership to _wallet1
        _transferOwnership(_wallet1);
        
        salesTax = 500; // 5%
        wallet1 = _wallet1;
        walletD = _walletD;
        walletR = _walletR;
        _isExcludedFromTax[msg.sender] = true;

        _grantRole(DEFAULT_ADMIN_ROLE, _wallet1);
        _grantRole(MINTER_ROLE, _wallet1);
    }

    function setWallets(address _wallet1, address _walletD, address _walletR) external onlyOwner {
        wallet1 = _wallet1;
        walletD = _walletD;
        walletR = _walletR;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWithTax(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transferWithTax(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function _transferWithTax(address sender, address recipient, uint256 amount) internal {
        require(amount <= balanceOf(sender), "ERC20: transfer amount exceeds balance");
        if (sender == wallet1 || sender == walletD || sender == walletR || recipient == wallet1 || recipient == walletD || recipient == walletR) {
            // Exclude transfers involving wallet1, walletD, and walletR
            _transfer(sender, recipient, amount);
        } else {
            uint256 taxAmount = (amount * salesTax) / 10000;
            uint256 transferAmount = amount - taxAmount;
            _transfer(sender, BURN_ADDRESS, taxAmount); // Burn the tax amount
            _transfer(sender, recipient, transferAmount);
            emit TransferWithTax(sender, recipient, transferAmount, taxAmount);
        }
    }

    function setSalesTax(uint256 tax) external onlyOwner {
        require(tax <= 500, "Tax cannot exceed 5%");
        salesTax = tax;
        emit SalesTaxSet(tax);
    }

    function excludeFromTax(address account) external onlyOwner {
        _isExcludedFromTax[account] = true;
        emit ExcludedFromTax(account);
    }

    function includeInTax(address account) external onlyOwner {
        _isExcludedFromTax[account] = false;
        emit IncludedInTax(account);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract DAARION is 
    Initializable, 
    ERC20Upgradeable, 
    ERC20BurnableUpgradeable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    UUPSUpgradeable, 
    ERC20PermitUpgradeable
{
    // **Special Wallet Addresses**
    address public wallet1; // Multisig wallet (Gnosis Safe)
    address public walletD; // DAARDistributor (fee recipient for DAAR)
    address public walletR; // APRStaking contract

    // **Tax Configuration**
    uint256 public constant SALES_TAX = 500; // 5% burn tax (in basis points)

    // **Events for Transparency**
    event TransferWithTax(address indexed sender, address indexed recipient, uint256 amount, uint256 taxAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with initial parameters.
     * @param _wallet1 Multisig wallet (Gnosis Safe) for admin and governance.
     * @param _walletD DAARDistributor contract address.
     * @param _walletR APRStaking contract address.
     */
    function initialize(address _wallet1, address _walletD, address _walletR) public initializer {
        __ERC20_init("DAARION", "DAARION");
        __ERC20Burnable_init();
        __Ownable_init(_wallet1);
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ERC20Permit_init("DAARION");

        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_walletD != address(0), "Invalid walletD address");
        require(_walletR != address(0), "Invalid walletR address");

        wallet1 = _wallet1;
        walletD = _walletD;
        walletR = _walletR;
    }

    /**
     * @dev Updates special wallet addresses (onlyOwner).
     */
    function setWallets(address _wallet1, address _walletD, address _walletR) external onlyOwner {
        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_walletD != address(0), "Invalid walletD address");
        require(_walletR != address(0), "Invalid walletR address");
        wallet1 = _wallet1;
        walletD = _walletD;
        walletR = _walletR;
    }

    /**
     * @dev Overrides ERC20 transfer with tax logic.
     */
    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        _transferWithTax(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Overrides ERC20 transferFrom with tax logic.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transferWithTax(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    /**
     * @dev Internal function to handle transfers with burn tax.
     */
    function _transferWithTax(address sender, address recipient, uint256 amount) internal {
        require(amount <= balanceOf(sender), "ERC20: insufficient balance");
        if (sender == wallet1 || recipient == wallet1 ||
            sender == walletD || recipient == walletD ||
            sender == walletR || recipient == walletR) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 taxAmount = (amount * SALES_TAX) / 10000; // 5% burn
            uint256 transferAmount = amount - taxAmount;
            _burn(sender, taxAmount);
            _transfer(sender, recipient, transferAmount);
            emit TransferWithTax(sender, recipient, transferAmount, taxAmount);
        }
    }

    /**
     * @dev Mints new tokens (onlyOwner).
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from the caller's balance (open to all users).
     */
    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Pauses the contract (onlyOwner).
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract (onlyOwner).
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Authorizes contract upgrades (onlyOwner).
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Reserved storage gap for future upgrades.
     */
    uint256[50] private __gap;
}
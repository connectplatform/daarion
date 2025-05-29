// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract DAAR is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    ERC20PermitUpgradeable
{
    // **Special Wallet Addresses**
    address public walletD; // Fee recipient (DAARDistributor)
    address public wallet1; // Multisig wallet (Gnosis Safe) for governance
    address public walletR; // APRStaking contract

    // **PinkSale Factory Address**
    address public constant PINKSALE_FACTORY = 0x62a63F21c96170D6a9B2EE1685892bDC97a3A11d;

    // **Fee Configuration**
    uint256 public transactionFee; // Fee in basis points (e.g., 50 = 0.5%)
    uint256 public constant MAX_TRANSACTION_FEE = 500; // Max 5%

    // **Fee Exemption Mapping**
    mapping(address => bool) private isExcludedFromFee;

    // **Events for Transparency**
    event WalletDSet(address indexed newWallet);
    event Wallet1Set(address indexed newWallet);
    event WalletRSet(address indexed newWallet);
    event TransactionFeeSet(uint256 newFee);
    event TransferWithFee(address indexed sender, address indexed recipient, uint256 amount, uint256 feeAmount);
    event ExcludedFromFee(address indexed account);
    event IncludedInFee(address indexed account);
    event Upgraded(address newImplementation);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with initial parameters.
     * @param _walletD Fee recipient address (DAARDistributor).
     * @param _initialFee Transaction fee in basis points (e.g., 50 for 0.5%).
     * @param _wallet1 Multisig wallet (Gnosis Safe) for admin and governance.
     * @param _walletR APRStaking contract address.
     */
    function initialize(
        address _walletD,
        uint256 _initialFee,
        address _wallet1,
        address _walletR
    ) public initializer {
        __ERC20_init("DAAR", "DAAR");
        __ERC20Burnable_init();
        __Ownable_init(_wallet1);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __ERC20Permit_init("DAAR");
        // Input validation
        require(_walletD != address(0), "Invalid walletD address");
        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_walletR != address(0), "Invalid walletR address");
        require(_initialFee <= MAX_TRANSACTION_FEE, "Fee exceeds maximum");

        walletD = _walletD;
        wallet1 = _wallet1;
        walletR = _walletR;
        transactionFee = _initialFee;

        // Set fee exemptions
        isExcludedFromFee[_wallet1] = true;
        isExcludedFromFee[_walletD] = true;
        isExcludedFromFee[_walletR] = true;
        isExcludedFromFee[PINKSALE_FACTORY] = true;
    }

    /**
     * @dev Authorizes contract upgrades (restricted to owner).
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        emit Upgraded(newImplementation); // Added: Event for upgrade
    }

    /**
     * @dev Updates special wallet addresses (onlyOwner).
     */
    function setWallets(address _wallet1, address _walletD, address _walletR) external onlyOwner {
        require(_walletD != address(0), "Invalid walletD address");
        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_walletR != address(0), "Invalid walletR address");

        // Update fee exemptions for old and new addresses
        isExcludedFromFee[wallet1] = false;
        isExcludedFromFee[_wallet1] = true;
        isExcludedFromFee[walletD] = false;
        isExcludedFromFee[_walletD] = true;
        isExcludedFromFee[walletR] = false;
        isExcludedFromFee[_walletR] = true;

        walletD = _walletD;
        wallet1 = _wallet1;
        walletR = _walletR;

        emit WalletDSet(_walletD);
        emit Wallet1Set(_wallet1); // Added: Event for wallet1
        emit WalletRSet(_walletR); // Added: Event for walletR
    }

    /**
     * @dev Updates the transaction fee (onlyOwner).
     */
    function setTransactionFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_TRANSACTION_FEE, "Fee exceeds maximum");
        transactionFee = newFee;
        emit TransactionFeeSet(newFee);
    }

    /**
     * @dev Excludes an account from fees (onlyOwner).
     */
    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }

    /**
     * @dev Includes an account in fees (onlyOwner).
     */
    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
        emit IncludedInFee(account);
    }

    /**
     * @dev Overrides ERC20 transfer with fee logic.
     */
    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        _transferWithFee(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Overrides ERC20 transferFrom with fee logic.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _transferWithFee(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    /**
     * @dev Internal function to handle transfers with fees.
     */
    function _transferWithFee(address sender, address recipient, uint256 amount) internal nonReentrant {
        // Removed redundant check: balance check is handled in _transfer

        if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 feeAmount = (amount * transactionFee) / 10000; // e.g., 0.5% = 50/10000
            uint256 transferAmount = amount - feeAmount;
            _transfer(sender, walletD, feeAmount); // Fee to DAARDistributor
            _transfer(sender, recipient, transferAmount);
            emit TransferWithFee(sender, recipient, transferAmount, feeAmount);
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
     * @dev Reserved storage gap for future upgrades.
     */
    uint256[50] private __gap;
}
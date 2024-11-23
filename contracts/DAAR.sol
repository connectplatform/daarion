// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Importing OpenZeppelin upgradeable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; // For upgradeable contracts
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol"; // Standard ERC20 functions
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol"; // Burnable functionality
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol"; // Ownership management
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol"; // Pause functionality
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol"; // Role-based access control
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol"; // Reentrancy protection

contract DAAR is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    // Defining the MINTER_ROLE constant
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Addresses for fee recipient and special wallets
    address public walletD; // Fee recipient wallet
    address public wallet1; // Special wallet 1
    address public walletR; // Special wallet R

    // Transaction fee in basis points (e.g., 50 = 0.5%)
    uint256 public transactionFee;

    // Events for logging changes
    event WalletDSet(address indexed newWallet);
    event TransactionFeeSet(uint256 newFee);
    event TransferWithFee(address indexed sender, address indexed recipient, uint256 amount, uint256 feeAmount);

    // Maximum transaction fee cap (e.g., 5%)
    uint256 public constant MAX_TRANSACTION_FEE = 500; // 5% in basis points

    /**
     * @dev Initializer function (replaces constructor for upgradeable contracts)
     * @param _walletD Address of the fee recipient wallet
     * @param _initialFee Initial transaction fee in basis points
     * @param _wallet1 Address of wallet1 (special wallet)
     * @param _walletR Address of walletR (special wallet)
     */
    function initialize(address _walletD, uint256 _initialFee, address _wallet1, address _walletR) public initializer {
    // Initialize parent contracts
    __ERC20_init("DAAR", "DAAR");
    __ERC20Burnable_init();
    __Pausable_init();
    __AccessControl_init();
    __Ownable_init(); 
    __ReentrancyGuard_init();

    // Transfer ownership to _wallet1
    _transferOwnership(_wallet1);

        // Validate input addresses
        require(_walletD != address(0), "Invalid walletD address");
        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_walletR != address(0), "Invalid walletR address");
        require(_initialFee <= MAX_TRANSACTION_FEE, "Initial fee exceeds maximum");

        // Set initial state variables
        walletD = _walletD;
        wallet1 = _wallet1;
        walletR = _walletR;
        transactionFee = _initialFee; // 0.5% in basis points (50 = 0.5%)

        // Grant roles to wallet1
        _grantRole(DEFAULT_ADMIN_ROLE, _wallet1);
        _grantRole(MINTER_ROLE, _wallet1);
    }

    /**
     * @dev Sets the special wallets (only callable by the owner)
     * @param _wallet1 New address for wallet1
     * @param _walletD New address for walletD (fee recipient)
     * @param _walletR New address for walletR
     */
    function setWallets(address _wallet1, address _walletD, address _walletR) external onlyOwner {
        // Validate input addresses
        require(_walletD != address(0), "Invalid walletD address");
        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_walletR != address(0), "Invalid walletR address");

        // Update wallets
        walletD = _walletD;
        wallet1 = _wallet1;
        walletR = _walletR;
    }

    /**
     * @dev Overrides the ERC20 transfer function to include transaction fee
     * @param recipient Recipient address
     * @param amount Amount to transfer
     * @return True if transfer succeeds
     */
    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        _transferWithFee(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Overrides the ERC20 transferFrom function to include transaction fee
     * @param sender Sender address
     * @param recipient Recipient address
     * @param amount Amount to transfer
     * @return True if transfer succeeds
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _transferWithFee(sender, recipient, amount);

        // Adjust the allowance by the total amount (including fee)
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    /**
     * @dev Internal function to handle transfers with fee
     * @param sender Sender address
     * @param recipient Recipient address
     * @param amount Amount to transfer
     */
    function _transferWithFee(address sender, address recipient, uint256 amount) internal nonReentrant {
        require(amount <= balanceOf(sender), "ERC20: transfer amount exceeds balance");

        // Check if the transfer involves special wallets
        if (
            sender == wallet1 || sender == walletD || sender == walletR ||
            recipient == wallet1 || recipient == walletD || recipient == walletR
        ) {
            // Exclude transfers involving special wallets from fee
            _transfer(sender, recipient, amount);
        } else {
            // Calculate the fee amount
            uint256 feeAmount = (amount * transactionFee) / 10000;
            uint256 transferAmount = amount - feeAmount;

            // Transfer the fee to walletD (fee recipient)
            _transfer(sender, walletD, feeAmount);

            // Transfer the remaining amount to the recipient
            _transfer(sender, recipient, transferAmount);

            // Emit a custom event for transparency
            emit TransferWithFee(sender, recipient, transferAmount, feeAmount);
        }
    }

    /**
     * @dev Sets a new transaction fee (only callable by the owner)
     * @param newFee New transaction fee in basis points
     */
    function setTransactionFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_TRANSACTION_FEE, "Transaction fee exceeds maximum");
        transactionFee = newFee;
        emit TransactionFeeSet(newFee);
    }

    /**
     * @dev Sets a new fee recipient walletD (only callable by the owner)
     * @param newWallet New walletD address
     */
    function setWalletD(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid walletD address");
        walletD = newWallet;
        emit WalletDSet(newWallet);
    }

    /**
     * @dev Mints new tokens (only callable by accounts with MINTER_ROLE)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(to != address(0), "Cannot mint to zero address");
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from the owner's balance (only callable by the owner)
     * @param amount Amount to burn
     */
    function burn(uint256 amount) public override onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Pauses contract operations (only callable by the owner)
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract operations (only callable by the owner)
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Reserved storage space to allow for layout changes in the future.
     */
    uint256[50] private __gap;
}

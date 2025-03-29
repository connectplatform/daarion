// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract DAAR is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    ERC20PermitUpgradeable
{
    // **Roles for Access Control**
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // **Special Wallet Addresses**
    address public walletD; // Fee recipient wallet
    address public wallet1; // Multisig wallet (Gnosis Safe) for governance and admin
    address public walletR; // Special wallet R

    // **Fee Configuration**
    uint256 public transactionFee; // Fee in basis points (e.g., 50 = 0.5%)
    uint256 public constant MAX_TRANSACTION_FEE = 500; // Max 5%

    // **Distributor Roles**
    address public distributor; // Primary distributor
    address public aprDistributor; // APR-specific distributor

    // **Fee Exemption Mapping**
    mapping(address => bool) private isExcludedFromFee;

    // **Events for Transparency**
    event WalletDSet(address indexed newWallet);
    event TransactionFeeSet(uint256 newFee);
    event TransferWithFee(address indexed sender, address indexed recipient, uint256 amount, uint256 feeAmount);
    event ExcludedFromFee(address indexed account);
    event IncludedInFee(address indexed account);
    event DistributorSet(address indexed distributor);
    event APRDistributorSet(address indexed distributor);
    event DAARDistributed(address indexed distributor, address[] recipients, uint256[] amounts);
    event EmergencyPauseTriggered(address indexed pauser);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with initial parameters.
     * @param _walletD Fee recipient address.
     * @param _initialFee Transaction fee in basis points.
     * @param _wallet1 Multisig wallet (Gnosis Safe) for admin and governance.
     * @param _walletR Special wallet R address.
     */
    function initialize(
        address _walletD,
        uint256 _initialFee,
        address _wallet1,
        address _walletR
    ) public initializer {
        __ERC20_init("DAAR", "DAAR");
        __ERC20Burnable_init();
        __Ownable_init(_wallet1); // Moved before Pausable
        __Pausable_init();
        __AccessControlEnumerable_init();
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

        // Assign roles to the multisig wallet
        _grantRole(DEFAULT_ADMIN_ROLE, _wallet1);
        _grantRole(MINTER_ROLE, _wallet1);
        _grantRole(PAUSER_ROLE, _wallet1);
        _grantRole(UPGRADER_ROLE, _wallet1);
    }

    /**
     * @dev Authorizes contract upgrades (restricted to UPGRADER_ROLE).
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev Updates special wallet addresses (onlyOwner).
     */
    function setWallets(address _wallet1, address _walletD, address _walletR) external onlyOwner {
        require(_walletD != address(0), "Invalid walletD address");
        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_walletR != address(0), "Invalid walletR address");

        walletD = _walletD;
        wallet1 = _wallet1;
        walletR = _walletR;
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
     * @dev Updates the transaction fee (onlyOwner).
     */
    function setTransactionFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_TRANSACTION_FEE, "Fee exceeds maximum");
        transactionFee = newFee;
        emit TransactionFeeSet(newFee);
    }

    /**
     * @dev Updates the fee recipient wallet (onlyOwner).
     */
    function setWalletD(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid walletD address");
        walletD = newWallet;
        emit WalletDSet(newWallet);
    }

    /**
     * @dev Sets the primary distributor (onlyOwner).
     */
    function setDistributor(address _distributor) external onlyOwner {
        require(_distributor != address(0), "Invalid distributor address");
        distributor = _distributor;
        emit DistributorSet(_distributor);
    }

    /**
     * @dev Sets the APR distributor (onlyOwner).
     */
    function setAPRDistributor(address _distributor) external onlyOwner {
        require(_distributor != address(0), "Invalid APR distributor address");
        aprDistributor = _distributor;
        emit APRDistributorSet(_distributor);
    }

    /**
     * @dev Distributes tokens to multiple recipients (onlyOwner).
     */
    function distributeDAAR(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Array length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
        emit DAARDistributed(distributor, recipients, amounts);
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
        require(amount <= balanceOf(sender), "ERC20: insufficient balance");

        if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 feeAmount = (amount * transactionFee) / 10000;
            uint256 transferAmount = amount - feeAmount;
            _transfer(sender, walletD, feeAmount);
            _transfer(sender, recipient, transferAmount);
            emit TransferWithFee(sender, recipient, transferAmount, feeAmount);
        }
    }

    /**
     * @dev Mints new tokens (only MINTER_ROLE).
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
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
     * @dev Pauses the contract (only PAUSER_ROLE).
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract (only PAUSER_ROLE).
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Triggers an emergency pause (only PAUSER_ROLE).
     */
    function emergencyPause() external onlyRole(PAUSER_ROLE) {
        _pause();
        emit EmergencyPauseTriggered(_msgSender());
    }

    /**
     * @dev Reserved storage gap for future upgrades.
     */
    uint256[50] private __gap;
}
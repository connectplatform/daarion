// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";

interface ICrossChainBridge {
    function bridgeTokens(address token, address recipient, uint256 amount, uint256 destinationChainId) external;
    function receiveTokens(address token, address recipient, uint256 amount) external;
}

contract DAARION is 
    Initializable, 
    ERC20Upgradeable, 
    ERC20BurnableUpgradeable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    AccessControlUpgradeable, 
    UUPSUpgradeable, 
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    uint256 public salesTax;
    mapping(address => bool) private _isExcludedFromTax;
    address public wallet1; // Multisig wallet (Gnosis Safe)
    address public walletD; // Fee recipient for DAAR
    address public walletR; // APR staking contract
    address public bridgeContract; // Cross-chain bridge contract

    event SalesTaxSet(uint256 newTax);
    event ExcludedFromTax(address indexed account);
    event IncludedInTax(address indexed account);
    event TransferWithTax(address indexed sender, address indexed recipient, uint256 amount, uint256 taxAmount);
    event BridgeContractSet(address indexed bridgeContract);
    event CrossChainTransfer(address indexed sender, address indexed recipient, uint256 amount, uint256 destinationChainId);

    function initialize(address _wallet1, address _walletD, address _walletR) public initializer {
        __ERC20_init("DAARION", "DAARION");
        __ERC20Burnable_init();
        __Ownable_init(_wallet1);
        __Pausable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC20Permit_init("DAARION");
        __ERC20Votes_init();

        _transferOwnership(_wallet1);

        salesTax = 500; // 5% (in basis points: 500 = 5%)
        wallet1 = _wallet1;
        walletD = _walletD;
        walletR = _walletR;
        _isExcludedFromTax[msg.sender] = true;
        _isExcludedFromTax[_wallet1] = true;
        _isExcludedFromTax[_walletD] = true;
        _isExcludedFromTax[_walletR] = true;

        _grantRole(DEFAULT_ADMIN_ROLE, _wallet1);
        _grantRole(MINTER_ROLE, _wallet1);
        _grantRole(BRIDGE_ROLE, _wallet1); // For setting bridge contract
    }

    function setWallets(address _wallet1, address _walletD, address _walletR) external onlyOwner {
        require(_wallet1 != address(0), "Invalid wallet1 address");
        require(_walletD != address(0), "Invalid walletD address");
        require(_walletR != address(0), "Invalid walletR address");
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
        if (sender == wallet1 || sender == walletD || sender == walletR ||
            recipient == wallet1 || recipient == walletD || recipient == walletR) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 taxAmount = (amount * salesTax) / 10000;
            uint256 transferAmount = amount - taxAmount;
            _burn(sender, taxAmount);
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

    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBridgeContract(address _bridgeContract) external onlyOwner {
        require(_bridgeContract != address(0), "Invalid bridge contract");
        bridgeContract = _bridgeContract;
        _grantRole(BRIDGE_ROLE, _bridgeContract);
        emit BridgeContractSet(_bridgeContract);
    }

    function crossChainTransfer(address recipient, uint256 amount, uint256 destinationChainId) external nonReentrant {
        require(bridgeContract != address(0), "Bridge contract not set");
        require(amount <= balanceOf(_msgSender()), "Insufficient balance");
        _burn(_msgSender(), amount);
        ICrossChainBridge(bridgeContract).bridgeTokens(address(this), recipient, amount, destinationChainId);
        emit CrossChainTransfer(_msgSender(), recipient, amount, destinationChainId);
    }

    function receiveCrossChain(address recipient, uint256 amount) external onlyRole(BRIDGE_ROLE) {
        _mint(recipient, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._update(from, to, amount);
    }

    function _getVotingUnits(address account)
        internal
        view
        override
        returns (uint256)
    {
        return balanceOf(account);
    }

    // Correctly override nonces from NoncesUpgradeable
    function nonces(address owner)
        public
        view
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    uint256[49] private __gap;
}
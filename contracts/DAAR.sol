// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract DAAR is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {

    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant APR_DISTRIBUTOR_ROLE = keccak256("APR_DISTRIBUTOR_ROLE");
    address public walletD;
    uint256 public transactionFee; // 0.5%

    mapping(address => bool) private isExcludedFromFee;

    event TransactionFeeSet(uint256 newFee);
    event WalletDSet(address newWallet);
    event DistributorSet(address distributor);
    event APRDistributorSet(address distributor);
    event ExcludedFromFee(address account);
    event IncludedInFee(address account);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event DAARDistributed(address indexed distributor, address[] recipients, uint256[] amounts);
    event TransferWithFee(address indexed sender, address indexed recipient, uint256 amount, uint256 feeAmount);

    function initialize(address _walletD, address _owner, address _walletR) initializer public {
        __ERC20_init("DAAR", "DAAR");
        __ERC20Burnable_init();
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        __AccessControl_init();

        walletD = _walletD;
        transactionFee = 50; // 0.5%

        // Exclude from fee
        isExcludedFromFee[_owner] = true;
        isExcludedFromFee[_walletD] = true;
        isExcludedFromFee[_walletR] = true;

        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(DISTRIBUTOR_ROLE, _walletD);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (isExcludedFromFee[_msgSender()]) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            uint256 feeAmount = (amount * transactionFee) / 10000;
            uint256 transferAmount = amount - feeAmount;
            _transfer(_msgSender(), walletD, feeAmount);
            _transfer(_msgSender(), recipient, transferAmount);
            emit TransferWithFee(_msgSender(), recipient, transferAmount, feeAmount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if (isExcludedFromFee[sender]) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 feeAmount = (amount * transactionFee) / 10000;
            uint256 transferAmount = amount - feeAmount;
            _transfer(sender, walletD, feeAmount);
            _transfer(sender, recipient, transferAmount);
            emit TransferWithFee(sender, recipient, transferAmount, feeAmount);
        }
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function setTransactionFee(uint256 newFee) external onlyOwner {
        transactionFee = newFee;
        emit TransactionFeeSet(newFee);
    }

    function setWalletD(address newWallet) external onlyOwner {
        walletD = newWallet;
        emit WalletDSet(newWallet);
    }

    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
        emit IncludedInFee(account);
    }

    function setDistributor(address _distributor) external onlyOwner {
        _grantRole(DISTRIBUTOR_ROLE, _distributor);
        emit DistributorSet(_distributor);
    }

    function setAPRDistributor(address _distributor) external onlyOwner {
        _grantRole(APR_DISTRIBUTOR_ROLE, _distributor);
        emit APRDistributorSet(_distributor);
    }

    function distributeDAAR(address[] calldata recipients, uint256[] calldata amounts) external {
        require(
            hasRole(DISTRIBUTOR_ROLE, msg.sender) || hasRole(APR_DISTRIBUTOR_ROLE, msg.sender),
            "Caller is not a distributor"
        );
        require(recipients.length == amounts.length, "Mismatched arrays");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);  // Use the transfer function with fee mechanism
        }
        
        emit DAARDistributed(msg.sender, recipients, amounts);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function burn(uint256 amount) public override onlyOwner {
        _burn(_msgSender(), amount);
        emit Burn(_msgSender(), amount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract DAARION is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    address public wallet1;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public salesTax; // 5% in basis points (500 basis points = 5%)
    mapping(address => bool) private _isExcludedFromTax;

    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    event SalesTaxSet(uint256 newTax);
    event Wallet1Set(address newWallet);
    event ExcludedFromTax(address account);
    event IncludedInTax(address account);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event DAARIONDistributed(address indexed distributor, address[] recipients, uint256[] amounts);

    function initialize(address _wallet1, address _distributor, address initialOwner) initializer public {
        __ERC20_init("DAARION", "DAARION");
        __ERC20Burnable_init();
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
        __AccessControl_init();

        wallet1 = _wallet1;
        salesTax = 500; // 5%
        _isExcludedFromTax[wallet1] = true;
        _isExcludedFromTax[initialOwner] = true;
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(DISTRIBUTOR_ROLE, _distributor);

        // Set the initial owner
        transferOwnership(initialOwner);
    }

    function transferWithFee(address sender, address recipient, uint256 amount) public {
        require(sender == _msgSender(), "Not authorized");
        if (_isExcludedFromTax[sender] || _isExcludedFromTax[recipient]) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 taxAmount = amount * salesTax / 10000; // calculate 5% tax
            uint256 transferAmount = amount - taxAmount;
            _transfer(sender, BURN_ADDRESS, taxAmount); // transfer tax amount to burn address
            _transfer(sender, recipient, transferAmount);
        }
    }

    function setSalesTax(uint256 tax) external onlyOwner {
        require(tax <= 500, "Tax cannot exceed 5%");
        salesTax = tax;
        emit SalesTaxSet(tax);
    }

    function setWallet1(address _wallet1) external onlyOwner {
        wallet1 = _wallet1;
        emit Wallet1Set(_wallet1);
    }

    function excludeFromTax(address account) external onlyOwner {
        _isExcludedFromTax[account] = true;
        emit ExcludedFromTax(account);
    }

    function includeInTax(address account) external onlyOwner {
        _isExcludedFromTax[account] = false;
        emit IncludedInTax(account);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function burn(uint256 amount) public override onlyOwner {
        _burn(_msgSender(), amount);
        emit Burn(_msgSender(), amount);
    }

    function distributeDAARION(address[] calldata recipients, uint256[] calldata amounts) external {
        require(hasRole(DISTRIBUTOR_ROLE, msg.sender), "Caller is not a distributor");
        require(recipients.length == amounts.length, "Mismatched arrays");
        for (uint256 i = 0; i < recipients.length; i++) {
            transferWithFee(wallet1, recipients[i], amounts[i]);
        }
        emit DAARIONDistributed(msg.sender, recipients, amounts);
    }
}

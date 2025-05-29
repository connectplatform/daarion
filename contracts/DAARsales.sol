// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DAARsales is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable DAAR;
    address public immutable paymentReceiver;
    uint256 public daarUSDPrice; // DAAR price in USD with 8 decimals

    mapping(address => address) public tokenPriceFeeds;

    event BoughtDAAR(address indexed buyer, address indexed token, uint256 amount, uint256 daarAmount);
    event TokenPriceFeedSet(address indexed token, address indexed priceFeed);
    event DaarUSDPriceSet(uint256 newPrice);

    constructor(
        address _DAAR,
        address[] memory tokens,
        address[] memory priceFeeds,
        uint256 _daarUSDPrice,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_DAAR != address(0), "DAAR address cannot be zero");
        require(tokens.length == priceFeeds.length, "Mismatched arrays");

        DAAR = IERC20(_DAAR);
        paymentReceiver = 0x39c8e3807B864A633bd83C34995d7A3a18d0b7e8;
        daarUSDPrice = _daarUSDPrice;

        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "Invalid token");
            require(priceFeeds[i] != address(0), "Invalid price feed");
            tokenPriceFeeds[tokens[i]] = priceFeeds[i];
        }
    }

    function buyDAAR(address token, uint256 amount, uint256 minDAAR) external whenNotPaused {
        require(tokenPriceFeeds[token] != address(0), "Unsupported token");
        uint256 daarAmount = calculateDAARAmount(token, amount);
        require(daarAmount >= minDAAR, "Slippage too high");
        require(DAAR.balanceOf(address(this)) >= daarAmount, "Insufficient DAAR");

        IERC20(token).safeTransferFrom(msg.sender, paymentReceiver, amount);
        DAAR.safeTransfer(msg.sender, daarAmount);

        emit BoughtDAAR(msg.sender, token, amount, daarAmount);
    }

    function calculateDAARAmount(address token, uint256 amount) public view returns (uint256) {
        uint256 tokenUSDPrice = getTokenUSDPrice(token);
        require(tokenUSDPrice > 0, "Invalid price");
        uint256 tokenDecimals = IERC20Metadata(token).decimals();
        uint256 tokenAmountInUSD = (amount * tokenUSDPrice) / (10 ** tokenDecimals);
        uint256 daarAmount = (tokenAmountInUSD * (10 ** 18)) / daarUSDPrice;
        return daarAmount;
    }

    function getTokenUSDPrice(address token) public view returns (uint256) {
        address priceFeed = tokenPriceFeeds[token];
        require(priceFeed != address(0), "No price feed");
        return getLatestPrice(AggregatorV3Interface(priceFeed));
    }

    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price,, uint256 updatedAt,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        require(block.timestamp - updatedAt < 3600, "Price feed is stale");
        return uint256(price);
    }

    function setTokenPriceFeed(address token, address priceFeed) external onlyOwner {
        require(token != address(0), "Invalid token");
        require(priceFeed != address(0), "Invalid price feed");
        tokenPriceFeeds[token] = priceFeed;
        emit TokenPriceFeedSet(token, priceFeed);
    }

    function setDaarUSDPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Invalid price");
        daarUSDPrice = newPrice;
        emit DaarUSDPriceSet(newPrice);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawDAAR(uint256 amount) external onlyOwner {
        DAAR.safeTransfer(owner(), amount);
    }

    function rescueTokens(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(owner(), amount);
    }
}
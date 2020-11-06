// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "../../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../../node_modules/@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./CitadelToken.sol";


contract CitadelExchange is CitadelToken {

    bool private _isInitialized;
    uint256 private _rate;
    AggregatorV3Interface private _oraclePriceFeed;
    address private _marketContract;
    uint256 private _marketRate;
    IERC20 private _USDTContract;
    uint256 public _publicSaleLimit;
    uint256 private _buyerLimit;
    mapping (address => uint256) private _buyers;
    bool private _marketClosed;

    modifier openMarketOnly() {
        require(_marketClosed == false, "CitadelExchange: market closed");
        _;
    }

    function _initCitadelExchange (
        uint256 rate_,
        uint256 buyerLimit_
    ) internal {
        require(!_isInitialized);
        _marketClosed = false;
        _rate = rate_;
        _buyerLimit = buyerLimit_;
        _isInitialized = true;
    }

    receive () external payable openMarketOnly {

        require(_publicSaleLimit > 0, "CitadelExchange: tokens already sold");
        require(_buyers[msg.sender] < _buyerLimit, "CitadelExchange: buyer reached limit");

        address payable sender = msg.sender;
        uint256 finalAmount = 0;
        uint256 payment = msg.value;
        uint256 restSum = 0;

        if (_marketContract != address(0)) {
            // get currency
            ( , uint256 price , , , ) = _getLatestOraclePrice();
            // _marketRate * 1e8
            uint256 rate_ = price.mul(_marketRate).div(1e8);
            finalAmount = payment.div(rate_);
            // check buyer limit
            if (_buyers[sender].add(finalAmount) > _buyerLimit) finalAmount = _buyerLimit.sub(_buyers[sender]);
            // check sale limit
            if (finalAmount > _publicSaleLimit) finalAmount = _publicSaleLimit;
            // calculate rest sum
            restSum = payment.sub(finalAmount.mul(rate_));
        } else if (_rate > 0) {
            finalAmount = payment.div(_rate);
            // check buyer limit
            if (_buyers[sender].add(finalAmount) > _buyerLimit) finalAmount = _buyerLimit.sub(_buyers[sender]);
            // check sale limit
            if (finalAmount > _publicSaleLimit) finalAmount = _publicSaleLimit;
            // calculate rest sum
            restSum = payment.sub(finalAmount.mul(_rate));
        } else {
            revert("CitadelExchange: buying rate cannot be zero");
        }

        require(finalAmount > 0, "CitadelExchange: too low amount");

        if (restSum > 0) msg.sender.transfer(restSum);

        _transfer(_bankAddress, sender, finalAmount);
        _buyers[msg.sender] = _buyers[msg.sender].add(finalAmount);
        _publicSaleLimit = _publicSaleLimit.sub(finalAmount);
    }

    function transferEth(address payable account, uint256 amount) external multisig(bytes4("FF")) {
        if (!_isMultisigReady(bytes4("FF"))) return;
        account.transfer(amount);
    }

    function buyViaUSDT (uint256 amount) external openMarketOnly {
        require(_marketRate > 0, "CitadelExchange: undefined market rate");
        address sender = msg.sender;
        require(
            _USDTContract.allowance(sender, _bankAddress) >= amount,
            "CitadelExchange: allow us transfer your usdt"
        );
        uint256 finalAmount = amount.div(_marketRate);
        uint256 restSum = amount.sub(finalAmount.mul(_marketRate));
        if (restSum > 0) amount = amount.sub(restSum);
        _USDTContract.transferFrom(sender, _bankAddress, amount);
        _transfer(_bankAddress, sender, finalAmount);
    }

    function transferUSDT(address account, uint256 amount) external multisig(bytes4("FF")) {
        if (!_isMultisigReady(bytes4("FF"))) return;
        _USDTContract.transferFrom(_bankAddress, account, amount);
    }

    function calculateTokensEther (uint256 amount) external view openMarketOnly returns (uint256) {
        if (_marketContract != address(0)) {
            ( , uint256 price , , , ) = _getLatestOraclePrice();
            uint256 rate_ = price.mul(_marketRate).div(1e8);
            return amount.div(rate_);
        } else if (_rate > 0) {
            return amount.div(_rate);
        }
        revert("CitadelExchange: buying rate cannot be zero");
    }

    function calculateTokensUSD (uint256 amount) external view openMarketOnly returns (uint256) {
        require(_marketRate > 0, "CitadelExchange: undefined market rate");
        return amount.div(_marketRate);
    }

    function changeRate (uint256 rate_) external openMarketOnly onlyOwner {
        require(rate_ > 0, "CitadelExchange: buying rate cannot be zero");
        _rate = rate_;
    }

    function getRate () external view openMarketOnly returns (uint256) {
        return _rate;
    }

    function changeMarketContract (address marketContract_, uint256 marketRate_) external openMarketOnly onlyOwner {
        if (_marketContract != address(0)) {
            require(marketContract_.isContract(), "CitadelExchange: address should be contract");
        }
        _marketContract = marketContract_;
        _marketRate = marketRate_;
        if (_marketContract != address(0)) _oraclePriceFeed = AggregatorV3Interface(marketContract_);
    }

    function removeMarketContract () external openMarketOnly onlyOwner {
        _marketContract = address(0);
    }

    function getMarketContract () external view openMarketOnly returns (address marketContract, uint256 marketRate) {
        marketContract = _marketContract;
        marketRate = _marketRate;
    }

    function changeUSDTContract (address usdtContract_) external openMarketOnly onlyOwner {
        require(usdtContract_.isContract(), "CitadelExchange: address should be contract");
        _USDTContract = IERC20(usdtContract_);
    }

    function getUSDTContract () external view returns (address) {
        return address(_USDTContract);
    }

    function changeBuyerLimit (uint256 buyerLimit_) external openMarketOnly onlyOwner {
        _buyerLimit = buyerLimit_;
    }

    function getBuyerLimit () external view openMarketOnly returns (uint256) {
        return _buyerLimit;
    }

    function closeMarket () external openMarketOnly onlyOwner {
        if (_publicSaleLimit > 0) _burn(_bankAddress, _publicSaleLimit);
        _marketClosed = true;
    }

    function isClosedMarket () external view returns (bool) {
        return _marketClosed;
    }

    function _getLatestOraclePrice() internal view returns (
        uint80 roundID,
        uint256 price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) {
        int256 price_ = 0;
        (
            roundID,
            price_,
            startedAt,
            timeStamp,
            answeredInRound
        ) = _oraclePriceFeed.latestRoundData();
        price = uint256(price_);
    }

}

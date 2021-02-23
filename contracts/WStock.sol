// SPDX-License-Identifier: MIT

// done
// contract must verify price offer is not too old
// may want to store is buy/sell on the contract
// remove fractional share support
// check that someone sent enough payment
// server must sign/confirm the buy price
// change acceptable tolerance value
// functions available to authAddress


// some notes...
// order revert
// blacklist
// possibly mint reward token on any interaction and reduce mint rate over time?

pragma solidity 0.7.3;

import "./lib/SafeMath.sol";
import "./lib/IERC20.sol";
import "./lib/Context.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/Ownable.sol";

contract WStock is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  constructor (address _stockToken, address _rewardToken ,address _authAddress, address payable _feeAddress, address payable _holdingAddress, uint256 _feeRate, uint256 _mintRate, uint256 _burnRate) {
    REWARD_TOKEN = IERC20(_rewardToken);
	  STOCK_TOKEN = IERC20(_stockToken);
    authAddress = _authAddress;
    feeAddress = _feeAddress;
    holdingAddress = _holdingAddress;
	  feeRate = _feeRate;
    mintRate = _mintRate;
	  burnRate = _burnRate;
    isFrozen = false;
    acceptableTolerance = 150;
  }
  struct Trade {
    uint256 amount;
    uint256 total;
    bool isBuy;
    address payable account;
    bool completed;
  }

  modifier onlyAuthorized() {
    require(authAddress == _msgSender(), "Unauthorized usage");
    _;
  }

  IERC20 private REWARD_TOKEN;
  IERC20 private STOCK_TOKEN;

  address private authAddress;
  address payable private feeAddress;
  address payable private holdingAddress;
  uint256 private feeRate;
  uint256 private mintRate;
  uint256 private burnRate;
  bool private isFrozen;
  uint256 private frozenTimestamp;
  uint256 private acceptableTolerance;

  uint256 public totalTrades;

  uint256[] public pendingTrades;
  mapping(uint256 => Trade) public trades;


  event PendingTrade(uint256 indexed tradeId, address indexed account, bool isBuy, uint256 amount, uint256 total);
  event CompletedTrade(uint256 indexed tradeId, address indexed account, bool isBuy, uint256 amount, uint256 total, uint256 fee, uint256 mint);

  function orderBuy(uint256 amount, uint256 total, uint256 timestamp, uint8 v, bytes32 r, bytes32 s) public payable nonReentrant {
    require(amount > 0, "Must pay an amount of tokens");
    require(!isFrozen, "Contract is frozen");
    bytes32 hash = keccak256(abi.encode(_msgSender(), amount, total, timestamp));
    address signer = ecrecover(hash, v, r, s);
    require(signer == authAddress, "Invalid signature");
    require(msg.value == total, "Incorrect payment amount");
    require(timestamp + acceptableTolerance > block.timestamp, "Expired Order");

    uint256 tradeId = totalTrades.add(1);
    trades[tradeId] = Trade({amount: amount, total: total, isBuy: true, account: _msgSender(), completed: false});
    pendingTrades.push(tradeId);
    emit PendingTrade(tradeId, _msgSender(), true, amount, total);
    totalTrades = tradeId;
  }

  function revertBuy(uint256 tradeId) public onlyAuthorized nonReentrant {
    Trade storage trade = trades[tradeId];
    require(trade.amount > 0, "quantity must be greater than zero");
    require(trade.total > 0, "total must be greater than zero");
    require(trade.isBuy, "trade isnt a buy order");
    require(!isFrozen, "Contract is frozen");
    require(!trade.completed, "trade is completed");
    _safeTransfer(trade.account, trade.total);
    clearPendingTrade(tradeId);
  }

  function executeBuy(uint256 tradeId) public onlyAuthorized nonReentrant {
    Trade storage trade = trades[tradeId];
    require(trade.amount > 0, "quantity must be greater than zero");
    require(trade.total > 0, "total must be greater than zero");
    require(trade.isBuy, "trade isnt a buy order");
    require(!isFrozen, "Contract is frozen");
    require(!trade.completed, "trade is completed");
    uint256 fee = trade.total.div(feeRate);
    uint256 cost = trade.total.sub(fee);
    uint256 mint = trade.total.mul(mintRate);
    STOCK_TOKEN.mint(trade.account, trade.amount);
    REWARD_TOKEN.mint(trade.account, mint);
    _safeTransfer(feeAddress, fee);
    _safeTransfer(holdingAddress, cost);
    emit CompletedTrade(tradeId, trade.account, true, trade.amount, trade.total, fee, mint);
    clearPendingTrade(tradeId);
  }

  function orderSell(uint256 amount, uint256 total, uint256 timestamp, uint8 v, bytes32 r, bytes32 s) public payable nonReentrant {
    require(amount > 0, "Must select an amount of tokens");
    require(!isFrozen, "Contract is frozen");
    require(amount <= STOCK_TOKEN.balanceOf(_msgSender()), "Cannot sell more than balance");
    // uint256 burn = total.mul(burnRate);
    // require(burn <= REWARD_TOKEN.balanceOf(_msgSender()), "Cannot burn more than balance");
    bytes32 hash = keccak256(abi.encode(_msgSender(), amount, total, timestamp));
    address signer = ecrecover(hash, v, r, s);
    require(signer == authAddress, "Invalid signature");
    require(timestamp + acceptableTolerance > block.timestamp, "Expired Order");

    uint256 tradeId = totalTrades.add(1);
    STOCK_TOKEN.transferFrom(_msgSender(), address(this), amount);
    // REWARD_TOKEN.transferFrom(_msgSender(), address(this), burn);
    trades[tradeId] = Trade({amount: amount, total: total, isBuy: false, account: _msgSender(), completed: false});
    pendingTrades.push(tradeId);
    emit PendingTrade(tradeId, _msgSender(), false, amount, total);
    totalTrades = tradeId;
  }

  function revertSell(uint256 tradeId) public onlyAuthorized nonReentrant {
    Trade storage trade = trades[tradeId];
    require(trade.amount > 0, "quantity must be greater than zero");
    require(trade.total > 0, "total must be greater than zero");
    require(!trade.isBuy, "trade isnt a sell order");
    require(!isFrozen, "Contract is frozen");
    require(!trade.completed, "trade is completed");
    // uint256 burn = trade.total.mul(burnRate);
    STOCK_TOKEN.transfer(trade.account, trade.amount);
    // REWARD_TOKEN.transfer(trade.account, burn); 
    clearPendingTrade(tradeId);
  }

  function executeSell(uint256 tradeId) public onlyAuthorized payable nonReentrant {
    Trade storage trade = trades[tradeId];
    require(trade.amount > 0, "quantity must be nonzero");
    require(trade.total > 0, "total must be greater than zero");
    require(!trade.isBuy, "trade isnt a sell order");
    require(!isFrozen, "Contract is frozen");
    require(!trade.completed, "trade is completed");
    uint256 fee = trade.total.div(feeRate);
    uint256 value = trade.total.sub(fee);
    // uint256 burn = trade.total.mul(burnRate);
    STOCK_TOKEN.burn(trade.amount);
    // REWARD_TOKEN.burn(burn);
    _safeTransfer(feeAddress, fee);
    _safeTransfer(trade.account, value);
    emit CompletedTrade(tradeId, trade.account, false, trade.amount, trade.total, fee, 0);
    clearPendingTrade(tradeId);
  }

  function getPendingTrades() public view returns(uint256[] memory) {
    return pendingTrades;
  }

  function clearPendingTrade(uint256 trade) internal {
    for (uint256 i = 0; i < pendingTrades.length; i++) {
      if (pendingTrades[i] == trade) {
        pendingTrades[i] = pendingTrades[pendingTrades.length - 1];
        pendingTrades.pop();
        break;
      }
    }
  }

  function getAuthAddress() public view returns (address) {
    return authAddress;
  }
  function setAuthAddress(address payable _authAddress) public onlyOwner nonReentrant {
    authAddress = _authAddress;
  }

  function getFeeAddress() public view returns (address) {
    return feeAddress;
  }
  function setFeeAddress(address payable _feeAddress) public onlyOwner nonReentrant {
    feeAddress = _feeAddress;
  }

  function getFeeRate() public view returns (uint256) {
    return feeRate;
  }
  function setFeeRate(uint256 _feeRate) public onlyOwner nonReentrant {
    feeRate = _feeRate;
  }

  function getMintRate()  public view returns(uint256) {
    return mintRate;
  }
  function setMintRate(uint256 _mintRate) public onlyOwner nonReentrant {
    mintRate = _mintRate;
  }

  function getBurnRate()  public view returns(uint256) {
    return burnRate;
  }
  function setBurnRate(uint256 _burnRate) public onlyOwner nonReentrant {
    burnRate = _burnRate;
  }

  function getAcceptableTolerance()  public view returns(uint256) {
    return acceptableTolerance;
  }
  function setAcceptableTolerance(uint256 _acceptableTolerance) public onlyOwner nonReentrant {
    acceptableTolerance = _acceptableTolerance;
  }

  function _safeTransfer(address payable to, uint256 amount) internal {
    uint256 balance;
    balance = address(this).balance;
    if (amount > balance) {
        amount = balance;
    }
    Address.sendValue(to, amount);
  }

}
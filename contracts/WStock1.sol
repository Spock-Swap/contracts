// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./lib/SafeMath.sol";
import "./lib/IERC20.sol";
import "./lib/Context.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/Ownable.sol";

contract WStock1 is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  constructor (address _stockToken, address _rewardToken ,address _authAddress, address payable _feeAddress, address payable _holdingAddress, uint256 _feeRate, uint256 _mintRate, uint256 _acceptableTolerance, uint256 _reserve) {
    REWARD_TOKEN = IERC20(_rewardToken);
	  STOCK_TOKEN = IERC20(_stockToken);
    authAddress = _authAddress;
    feeAddress = _feeAddress;
    holdingAddress = _holdingAddress;
	  feeRate = _feeRate;
    mintRate = _mintRate;
    isFrozen = false;
    acceptableTolerance = _acceptableTolerance;
    reserve = _reserve;
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
  bool private isFrozen;
  uint256 private frozenTimestamp;
  uint256 private acceptableTolerance;
  uint256 private reserve;
  uint256 public totalTrades;

  event Trade(uint256 indexed tradeId, address indexed account, bool isBuy, uint256 amount, uint256 total, uint256 fee, uint256 mint);
  event Reload(uint256 indexed amount, uint256 timestamp);

  function buy(uint256 amount, uint256 total, uint256 timestamp, uint8 v, bytes32 r, bytes32 s) public payable nonReentrant {
    require(amount > 0, "Must pay an amount of tokens");
    require(total > 0, "total must be greater than zero");
    require(!isFrozen, "Contract is frozen");
    bytes32 hash = keccak256(abi.encode(_msgSender(), amount, total, timestamp));
    address signer = ecrecover(hash, v, r, s);
    require(signer == authAddress, "Invalid signature");
    require(msg.value == total, "Incorrect payment amount");
    require(timestamp.add(acceptableTolerance) > block.timestamp, "Expired Order");

    totalTrades = totalTrades.add(1);
    uint256 fee = total.div(feeRate);
    uint256 hold = total.sub(fee);
    uint256 mint = total.mul(mintRate);
    emit Trade(totalTrades, _msgSender(), true, amount, total, fee, mint);
    STOCK_TOKEN.mint(_msgSender(), amount);
    REWARD_TOKEN.mint(_msgSender(), mint);
    if (address(this).balance >= reserve) {
      _safeTransfer(feeAddress, fee);
      _safeTransfer(holdingAddress, hold);
    }
    else {
      emit Reload(reserve.sub(address(this).balance), block.timestamp);
    }
  }

  function sell(uint256 amount, uint256 total, uint256 timestamp, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
    require(amount > 0, "Must select an amount of tokens");
    require(total > 0, "total must be greater than zero");
    require(!isFrozen, "Contract is frozen");
    require(amount <= STOCK_TOKEN.balanceOf(_msgSender()), "Cannot sell more than balance");
    bytes32 hash = keccak256(abi.encode(_msgSender(), amount, total, timestamp));
    address signer = ecrecover(hash, v, r, s);
    require(signer == authAddress, "Invalid signature");
    require(timestamp.add(acceptableTolerance) > block.timestamp, "Expired Order");
    require(total <= address(this).balance, "insufficient funds, try again later");

    totalTrades = totalTrades.add(1);
    uint256 fee = total.div(feeRate);
    emit Trade(totalTrades, _msgSender(), false, amount, total, fee, 0);
    uint256 value = total.sub(fee);
    STOCK_TOKEN.transferFrom(_msgSender(), address(this), amount);
    STOCK_TOKEN.burn(amount);
    _safeTransfer(_msgSender(), value);
    if (address(this).balance >= reserve) {
      _safeTransfer(feeAddress, fee);
    }
    else {
      emit Reload(reserve.sub(address(this).balance), block.timestamp);
    }
  }

  function getReserve()  public view returns(uint256) {
    return reserve;
  }
  function setReserve(uint256 _reserve) public onlyOwner nonReentrant {
    reserve = _reserve;
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
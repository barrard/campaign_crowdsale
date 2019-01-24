pragma solidity ^0.5.0;

import "../../math/SafeMath.sol";
import "../Crowdsale.sol";
import "../../ownership/Ownable.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  uint256 private _openingTime;
  uint256 private _closingTime;
  uint256 private _time_limit;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(isOpen(), "Only while open");
    _;
  }

  event Forced_Campaign_Closed(
    address msg_sender,
    uint256 time
  );

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param time_limit of Crowdsale used to calc opening and ending time
   */
  constructor(
    uint256 time_limit,
    uint256 rate, address payable wallet, address token_address

    ) 
    Crowdsale(rate, wallet, token_address)
    internal {
    // solium-disable-next-line security/no-block-members
    require(time_limit > 0, "time limit must be > 0");
    _time_limit = time_limit;

    _openingTime = block.timestamp;
    _closingTime = _openingTime.add(_time_limit);
    require(_openingTime >= block.timestamp, "opening time must be >= block timestamp");
    require(_closingTime > _openingTime, "closing time must be > opening time");

  }

  /**
   * @dev Force campaign to end.
   */
  function end_campaign() public onlyOwner returns(bool) {
    return _end_campaign();
    // _closingTime = block.timestamp;
    // emit Forced_Campaign_Closed(msg.sender, block.timestamp);
    // return true;
  }

  /**
   * @dev Internal Force campaign to end.
   */
  function _end_campaign() internal returns(bool) {
    _closingTime = block.timestamp;
    emit Forced_Campaign_Closed(msg.sender, block.timestamp);
    return true;
  }
    /**
   * @return the crowdsale opening time.
   */
  function openingTime() public view returns(uint256) {
    return _openingTime;
  }

  /**
   * @return the crowdsale closing time.
   */
  function closingTime() public view returns(uint256) {
    return _closingTime;
  }

  /**
   * @return the crowdsale time limt.
   */
  function time_limit() public view returns(uint256) {
    return _time_limit;
  }

  /**
   * @return true if the crowdsale is open, false otherwise.
   */
  function isOpen() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp >= _closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    onlyWhileOpen
    view
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

}

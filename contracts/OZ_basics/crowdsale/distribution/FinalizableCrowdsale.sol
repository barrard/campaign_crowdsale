pragma solidity ^0.5.0;

import "../../math/SafeMath.sol";
import "../validation/TimedCrowdsale.sol";

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale with a one-off finalization action, where one
 * can do extra work after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  bool private _finalized;

  event CrowdsaleFinalized();

  constructor(
    uint rate, 
    address payable wallet, 
    address token_address, 
    uint time_limit
  ) 
    TimedCrowdsale(time_limit, rate, wallet, token_address)
  internal {
    _finalized = false;
  }

  /**
   * @return true if the crowdsale is finalized, false otherwise.
   */
  function finalized() public view returns (bool) {
    return _finalized;
  }

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() public {
    require(!_finalized, "Cannot finalize, already is finalized");
    require(hasClosed(), "Cannot finalize, until has closed");

    _finalized = true;

    _finalization();
    emit CrowdsaleFinalized();
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super._finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function _finalization() internal {
  }
}

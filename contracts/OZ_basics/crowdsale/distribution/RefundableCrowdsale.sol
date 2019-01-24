pragma solidity ^0.5.0;

import "../../math/SafeMath.sol";
import "./FinalizableCrowdsale.sol";
import "../../payment/escrow/RefundEscrow.sol";

/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * WARNING: note that if you allow tokens to be traded before the goal 
 * is met, then an attack is possible in which the attacker purchases 
 * tokens from the crowdsale and when they sees that the goal is 
 * unlikely to be met, they sell their tokens (possibly at a discount).
 * The attacker will be refunded when the crowdsale is finalized, and
 * the users that purchased from them will be left with worthless 
 * tokens. There are many possible ways to avoid this, like making the
 * the crowdsale inherit from PostDeliveryCrowdsale, or imposing 
 * restrictions on token trading until the crowdsale is finalized.
 * This is being discussed in 
 * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/877
 * This contract will be updated when we agree on a general solution
 * for this problem.
 */
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  uint256 private _goal;

  // refund escrow used to hold funds while crowdsale is running
  RefundEscrow private _escrow;

  event Not_yet(uint indexed _goal, uint indexed _weiRaised, uint indexed _diff );

  /**
   * @dev Constructor, creates RefundEscrow.
   * @param goal Funding goal
   */
  constructor(
    uint256 goal, 
    uint256 rate, 
    address payable wallet, 
    address token_address, 
    uint256 time_limit) 
    FinalizableCrowdsale(rate, wallet, token_address, time_limit)
    internal {
    require(goal > 0, "Goal must be > 0");
    _escrow = new RefundEscrow(wallet);
    _goal = goal;
  }

  /**
   * @return minimum amount of funds to be raised in wei.
   */
  function goal() public view returns(uint256) {
    return _goal;
  }

  /**
   * @dev Investors can claim refunds here if crowdsale is unsuccessful
   * @param beneficiary Whose refund will be claimed.
   */
  function claimRefund(address payable beneficiary) public {
    require(finalized(), "Not yet finailized, cannot refund");
    require(!goalReached(), "Goal was reached, cannot refund");

    _escrow.withdraw(beneficiary);
  }

  /**
   * @dev Checks whether funding goal was reached.
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return weiRaised() >= _goal;
  }

  /**
   * @return address of escrow account
   */
  function escrow_address() public view returns (address) {
    return address(_escrow);
  }

  /**
   * @dev escrow finalization task, called when finalize() is called
   */
  function _finalization() internal {
    if (goalReached()) {
      _escrow.close();
      _escrow.beneficiaryWithdraw();
    } else {
      _escrow.enableRefunds();
    }

    super._finalization();
  }

  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    
  {
    if(this.weiRaised() >= this.goal()){
      _end_campaign();
      this.finalize();
    }else{
      uint weiRaised = this.weiRaised();
      uint diff = _goal.sub(weiRaised);
      emit Not_yet(_goal, weiRaised, diff);

    }

    // super._postValidatePurchase(beneficiary, weiAmount);
  }


  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to escrow.
   */
  function _forwardFunds(uint256 _weiAmount) internal {
    _escrow.deposit.value(_weiAmount)(msg.sender);
  }

}

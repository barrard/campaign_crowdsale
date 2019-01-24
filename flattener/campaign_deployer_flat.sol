pragma solidity ^0.5.0;

// File: contracts/OZ_basics/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/OZ_basics/utils/ReentrancyGuard.sol

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

// File: contracts/OZ_basics/crowdsale/Crowdsale.sol

// import "../token/ERC20/IERC20.sol";

// import "../token/ERC20/SafeERC20.sol";


contract CS_ERC777Token{
    function send(address to, uint256 amount) external;
    function send(address to, uint256 amount, bytes calldata userData) external;
    function mint(address _tokenHolder, uint256 _amount, bytes calldata _operatorData) external;
    function set_campaign_address(address campaign_address) external;
/*     function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
 */

}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    //address of token
    address private _token_address;

    // The token being sold
    CS_ERC777Token private _token;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     * @param token_address Address of the token being sold
     */
    constructor (uint256 rate, address payable wallet, address token_address) internal {
        require(rate > 0);
        require(wallet != address(0));
        require(token_address != address(0));

        _rate = rate;
        _wallet = wallet;
        _token_address = token_address;
        _token = CS_ERC777Token(token_address);
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer fund with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (CS_ERC777Token) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address beneficiary, 
        uint256 weiAmount) 
        internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(
        address beneficiary, 
        uint256 weiAmount) 
        internal 
         {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(
        address beneficiary, 
        uint256 tokenAmount) 
        internal {
        _token.send(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(
        address beneficiary, 
        uint256 tokenAmount) 
        internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(
        address beneficiary, 
        uint256 weiAmount) 
        internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

// File: contracts/OZ_basics/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Only the owner can do this");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/OZ_basics/crowdsale/validation/TimedCrowdsale.sol

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
  constructor(uint256 time_limit) internal {
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
    _closingTime = block.timestamp;
    emit Forced_Campaign_Closed(msg.sender, block.timestamp);
    return true;
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

// File: contracts/OZ_basics/crowdsale/distribution/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale with a one-off finalization action, where one
 * can do extra work after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  bool private _finalized;

  event CrowdsaleFinalized();

  constructor() internal {
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

// File: contracts/OZ_basics/ownership/Secondary.sol

/**
 * @title Secondary
 * @dev A Secondary contract can only be used by its primary account (the one that created it)
 */
contract Secondary {
    address private _primary;

    event PrimaryTransferred(
        address recipient
    );

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    constructor () internal {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(msg.sender == _primary);
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0));
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}

// File: contracts/OZ_basics/payment/escrow/Escrow.sol

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 * @dev Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the Escrow rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its primary, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Secondary {
    using SafeMath for uint256;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
    * @dev Stores the sent amount as credit to be withdrawn.
    * @param payee The destination address of the funds.
    */
    function deposit(address payee) public onlyPrimary payable {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].add(amount);

        emit Deposited(payee, amount);
    }

    /**
    * @dev Withdraw accumulated balance for a payee.
    * @param payee The address whose funds will be withdrawn and transferred to.
    */
    function withdraw(address payable payee) public onlyPrimary {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.transfer(payment);

        emit Withdrawn(payee, payment);
    }
}

// File: contracts/OZ_basics/payment/escrow/ConditionalEscrow.sol

/**
 * @title ConditionalEscrow
 * @dev Base abstract escrow to only allow withdrawal if a condition is met.
 * @dev Intended usage: See Escrow.sol. Same usage guidelines apply here.
 */
contract ConditionalEscrow is Escrow {
    /**
    * @dev Returns whether an address is allowed to withdraw their funds. To be
    * implemented by derived contracts.
    * @param payee The destination address of the funds.
    */
    function withdrawalAllowed(address payee) public view returns (bool);

    function withdraw(address payable payee) public {
        require(withdrawalAllowed(payee));
        super.withdraw(payee);
    }
}

// File: contracts/OZ_basics/payment/escrow/RefundEscrow.sol

/**
 * @title RefundEscrow
 * @dev Escrow that holds funds for a beneficiary, deposited from multiple
 * parties.
 * @dev Intended usage: See Escrow.sol. Same usage guidelines apply here.
 * @dev The primary account (that is, the contract that instantiates this
 * contract) may deposit, close the deposit period, and allow for either
 * withdrawal by the beneficiary, or refunds to the depositors. All interactions
 * with RefundEscrow will be made through the primary contract. See the
 * RefundableCrowdsale contract for an example of RefundEscrow’s use.
 */
contract RefundEscrow is ConditionalEscrow {
    enum State { Active, Refunding, Closed }

    event RefundsClosed();
    event RefundsEnabled();

    State private _state;
    address payable private _beneficiary;

    /**
     * @dev Constructor.
     * @param beneficiary The beneficiary of the deposits.
     */
    constructor (address payable beneficiary) public {
        require(beneficiary != address(0));
        _beneficiary = beneficiary;
        _state = State.Active;
    }

    /**
     * @return the current state of the escrow.
     */
    function state() public view returns (State) {
        return _state;
    }

    /**
     * @return the beneficiary of the escrow.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Stores funds that may later be refunded.
     * @param refundee The address funds will be sent to if a refund occurs.
     */
    function deposit(address refundee) public payable {
        require(_state == State.Active);
        super.deposit(refundee);
    }

    /**
     * @dev Allows for the beneficiary to withdraw their funds, rejecting
     * further deposits.
     */
    function close() public onlyPrimary {
        require(_state == State.Active);
        _state = State.Closed;
        emit RefundsClosed();
    }

    /**
     * @dev Allows for refunds to take place, rejecting further deposits.
     */
    function enableRefunds() public onlyPrimary {
        require(_state == State.Active);
        _state = State.Refunding;
        emit RefundsEnabled();
    }

    /**
     * @dev Withdraws the beneficiary's funds.
     */
    function beneficiaryWithdraw() public {
        require(_state == State.Closed);
        _beneficiary.transfer(address(this).balance);
    }

    /**
     * @dev Returns whether refundees can withdraw their deposits (be refunded). The overriden function receives a
     * 'payee' argument, but we ignore it here since the condition is global, not per-payee.
     */
    function withdrawalAllowed(address) public view returns (bool) {
        return _state == State.Refunding;
    }
}

// File: contracts/OZ_basics/crowdsale/distribution/RefundableCrowdsale.sol

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
  constructor(uint256 goal) internal {
    require(goal > 0, "Goal must be > 0");
    _escrow = new RefundEscrow(wallet());
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

// File: contracts/ERC820/ERC820Client.sol

contract ERC820Registry_iface {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) public;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) public view returns (address);
    function setManager(address _addr, address _newManager) public;
    function getManager(address _addr) public view returns(address);
}


/// Base client to interact with the registry.
contract ERC820Client {
    // ERC820Registry constant ERC820REGISTRY = ERC820Registry(0x820b586C8C28125366C998641B09DCbE7d4cBF06);
    
    /* ADDED CONSTRUCTOR FOR TESTING */
    ERC820Registry_iface ERC820REGISTRY;
    constructor(address erc820_addr) internal {
        ERC820REGISTRY = ERC820Registry_iface(erc820_addr);
    }


    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC820REGISTRY.setManager(address(this), _newManager);
    }
}

// File: contracts/Campaign_Crowdsale.sol

contract Campaign_Crowdsale is RefundableCrowdsale, ERC820Client{
  using SafeMath for uint256;

  address private _token_address;
  uint256 private _total_token_bits;//18 decimals, 1 token = 1*10^18 token bits
  uint256 private _wei_token_rate;
  uint private _goal_in_wei;
  address private _campaign_deployer;
  
  CS_ERC777Token private _token;
  event  Send_It(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData); 
  event Receive_It(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData);

  constructor(
    uint goal_in_wei,
    uint wei_token_rate, 
    address payable wallet, 
    uint total_token_bits,
    address token_address,
    uint time_limit,
    address campaign_deployer,
    address ERC820Registry_Address
  )
    Crowdsale(wei_token_rate, wallet, token_address)
    RefundableCrowdsale(goal_in_wei)
    TimedCrowdsale(time_limit)
    ERC820Client(ERC820Registry_Address)
    public
  {

    _token_address = token_address;
    _total_token_bits = total_token_bits;
    _wei_token_rate = wei_token_rate;
    _goal_in_wei = goal_in_wei;
    _campaign_deployer = campaign_deployer;
    setInterfaceImplementation('ERC777TokensRecipient', address(this));
    setInterfaceImplementation('ERC777TokensSender', address(this));


    // _token = CS_ERC777Token(token_address);
    /* Tell token the campaign address */
    // _token.set_campaign_address(address(this));
    /* Mint the totalSupply */
    // _token.mint(address(this), total_token_bits, "Initial Total Supply of Tokens");

  }

  function tokensToSend(
    address _operator, 
    address _from, 
    address _to, 
    uint _amount,
    bytes memory _userData,
    bytes memory _operatorData) public{
      emit Send_It(
        _operator,
        _from,
        _to,
        _amount,
        _userData,
        _operatorData);
        /* Here we could go to the restricted token contract and
         use its logic to dermine isf this token is good to go */
  }

/* Only receive tokens from 0x0 address */
  function tokensReceived(
    address _operator, 
    address _from, 
    address _to, 
    uint _amount,
    bytes memory _userData,
    bytes memory _operatorData) public{
      /* Tokens Received should only be from the inital minting */
      require(_from == address(0), "Only receive tokens from minting frocess, i.e. _From address 0x0");

      emit Receive_It(
        _operator,
        _from,
        _to,
        _amount,
        _userData,
        _operatorData);
  }

  function token_address() public view returns(address){
    return _token_address;
  }

  function cal_goal() public view returns (uint, uint){
    uint _cal_goal = (_total_token_bits.div(1 ether)).mul(_wei_token_rate); 
    return (_cal_goal, _goal_in_wei);
  }

  function time_limt() public view returns (uint256 start_time, uint256 end_time, uint256 time_limit){
    return (this.openingTime(), this.closingTime(), this.time_limit());

  }

}

// File: contracts/Eth_price_Oracle.sol

contract Eth_price_Oracle is Ownable {

  uint public _block;//block number
  uint private _price;//in pennies
  uint private _price_timestamp;//seconds
  string private _url;


    // event Get_ETH_Price(
    //     address msg_sender,
    //   uint price_timestamp,
    //   uint price
    // );

  event NEW_URL_SET(
    string old_url, string new_url
  );

  event NEW_ETH_PRICE(
    uint price,
    uint price_timestamp
  );

  constructor () public {
    _price = 10000;//13900;//$100.00
    _price_timestamp = block.timestamp;
    _block = block.number;
    _url = 'google.com';

  }

  function set_url(string memory _new_url) public onlyOwner returns (bool) {
    string memory old_url = _url;
    _url = _new_url;
    emit NEW_URL_SET(old_url, _new_url);
    return true;
  }

  function set_price(uint _new_price) public onlyOwner {
    _price = _new_price;
    _price_timestamp = block.timestamp;
    emit NEW_ETH_PRICE(_price, _price_timestamp);
  }

  function get_eth_price() public view returns (uint, uint, string memory){
    // emit Get_ETH_Price(msg.sender, _price, _price_timestamp);
    return (_price, _price_timestamp, _url);
  }
}

// File: contracts/Campaign_Deployer.sol

// import './Della_Security_Token.sol';

contract Token_creator_iface {
    function create_token(    
    string memory _name,
    string memory _symbol,
    uint256 _granularity
    /* For testing only */
    ,address ERC820Registry_Address) public returns(address);
}
/* Campaign Deployer token prototype */
contract CD_Della_Token_iface{
  function mint(address _tokenHolder, uint256 _amount, bytes memory _operatorData) public;
  function transferOwnership(address newOwner) public;
}

contract Campaign_Deployer is Ownable {
  using SafeMath for uint256;

  // Crowdsale _new_campaign;
  // ERC20 _token;
  uint TOKEN_RATE= 5000;// Price of tokens in PENNIES

  address private _Eth_price_Oracle_address;
  address private _della_address;
  address private _resitricted_token_service_address;
  address private _token_creator;

  uint private campaign_count;
  /* FOR TESTING ONLY */
  address public ERC820Registry_Address;

  
  constructor(address della_address, address registry_address ) public {
    campaign_count = 0; 

    ERC820Registry_Address = registry_address;
    _della_address = della_address;
    
  }


  event token_cal(
    uint indexed goal_in_wei,
    uint indexed rate,
    uint indexed total_token_bits
  );

  modifier only_della(){
    require(msg.sender == _della_address, "Only Della may call this function");
    _;
  }

  function get_campaign_count() public returns(uint){
    return campaign_count;
  }
  function set_restricted_token_address(address resitricted_token_service_address) public onlyOwner {
    _resitricted_token_service_address = resitricted_token_service_address;
  }

  function set_token_creator_address(address token_creator) public onlyOwner {
    _token_creator = token_creator;
  }

  function set_oracle_address(address oracle_address) public onlyOwner{
    _Eth_price_Oracle_address = oracle_address;
  }
  function get_oracle_address() public returns (address){
    return _Eth_price_Oracle_address;
  }

  function _create_token() internal returns(address){
    Token_creator_iface tc = Token_creator_iface(_token_creator);  /* FOR TESTING ONLY */
    address token_addr = tc.create_token("Della", "DLA", 10**18, ERC820Registry_Address);

    // Della_Security_Token _Della_Security_Token = new Della_Security_Token("Della", "DLA", 18, ERC820Registry_Address);
    return address(token_addr);
  }


  function _calculate_token_supply_and_rate( uint _goal_usd) 
    internal returns(uint, uint, uint) {
      uint price;//pennies per 1 ether
      uint goal_pennies = _goal_usd.mul(100);
      uint goal_pennies_per_wei = goal_pennies.mul(1 ether);//val in pennies time 10^18 to remove decimals      

      Eth_price_Oracle oracle = Eth_price_Oracle(_Eth_price_Oracle_address);
      (price, , ) = oracle.get_eth_price();

      uint rate = TOKEN_RATE.mul(1 ether).div(price);
      rate = ceil(rate, 1 szabo);
      uint total_token_bits = goal_pennies_per_wei.div(TOKEN_RATE);
      uint goal_in_wei = (total_token_bits.div(1 ether)).mul(rate);

      emit token_cal(goal_in_wei, rate, total_token_bits);
      return (goal_in_wei, rate, total_token_bits);

  }
      function cal_Multiple(uint256 _amount) public pure returns(uint, uint) {
        uint cal =  (_amount.div(10**18).mul(10**18));
        return (_amount, cal);
    }

  function create_campaign(
    uint goal, //USD i.e. 500000
    address payable wallet, 
    uint time_limit
    //may also need bytes32 data, tell token to register with ERC820
  )
    public only_della returns (address, address){
      // uint goal_in_pennies;
      uint goal_in_wei;
      uint wei_token_rate;
      uint total_tokens;
      string memory url;
      // goal_in_pennies = goal.mul(100);
      (goal_in_wei, wei_token_rate, total_tokens) = _calculate_token_supply_and_rate(goal);
   
    /* Create the new token for the new campaign */
    address Della_Security_Token_address = _create_token();
    /* Make local instance of the token */
    CD_Della_Token_iface token = CD_Della_Token_iface(Della_Security_Token_address);
    
    /* Create new Campaign */
    Campaign_Crowdsale  new_campaign = new Campaign_Crowdsale(
      goal_in_wei,
      wei_token_rate,
      wallet,
      total_tokens,
       Della_Security_Token_address,
      time_limit,
      address(this),
      /* FOR TESTING ONLY */
      ERC820Registry_Address
    );

    /* Mint the tokems for the new campaign */
    token.mint(address(new_campaign), total_tokens,  "Initiating Crowdsale with token supply");
    
    /* Transfer ownership of tokens to the new campaign */
    token.transferOwnership(address(new_campaign));


    // Della_Security_Token.set_campaign_address(address(new_campaign));
    // new_campaign.transferOwnership(msg.sender);
    // emit Event_String("Hello World", true, 12312);
    campaign_count++;

    return (address(new_campaign), Della_Security_Token_address);
  }

  function ceil(uint a, uint m) public pure returns (uint ) {
      return ((a + m - 1) / m) * m;
  }

}

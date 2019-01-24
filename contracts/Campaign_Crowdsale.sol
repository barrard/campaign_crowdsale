pragma solidity ^0.5.0;

import './OZ_basics/crowdsale/distribution/RefundableCrowdsale.sol';
import './ERC820/ERC820Client.sol';


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
        address indexed from,
        address indexed to,
        uint indexed amount,
        bytes userData,
        bytes operatorData); 

  event Receive_It(
        address operator,
        address indexed from,
        address indexed to,
        uint indexed amount,
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
    // Crowdsale(wei_token_rate, wallet, token_address)
    // TimedCrowdsale(time_limit)
    RefundableCrowdsale(goal_in_wei, wei_token_rate, wallet, token_address, time_limit)
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
         use its logic to determine if this token is good to go */
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
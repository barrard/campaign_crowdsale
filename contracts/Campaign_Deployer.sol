pragma solidity ^0.5.0;

import "./Campaign_Crowdsale.sol";
import './Eth_price_Oracle.sol';
import './OZ_basics/ownership/Ownable.sol';
import './OZ_basics/math/SafeMath.sol';
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
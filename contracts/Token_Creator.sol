pragma solidity ^0.5.0;

import './Della_Security_Token.sol';


contract Token_Creator {

  address private _deployer_address;
  address private _Della_address;

  constructor(address deployer_address, address Della_address) public {
    _deployer_address = deployer_address;
    _Della_address = Della_address;
  }

  modifier only_deployer(){
    require(msg.sender == _deployer_address, "Only Campaign Deployer");
    _;
  }


  function create_token(    
    string memory _name,
    string memory _symbol,
    uint256 _granularity
    /* For testing only */
    ,address ERC820Registry_Address) public /* only_deployer */ returns(address){
    Della_Security_Token new_token = new Della_Security_Token(
      _name,
      _symbol,
      _granularity,
      _Della_address
      /* For testing only */
      ,ERC820Registry_Address);
      new_token.transferOwnership(_deployer_address);

    address new_token_address = address(new_token);
    return new_token_address;
  }

  // function transfer_token_ownership(address token_address, address new_owner) public only_deployer{
  //   Della_Security_Token token = Della_Security_Token(token_address);
  //   token.transferOwnership(new_owner);
  // }
} 
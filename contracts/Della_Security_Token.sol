pragma solidity ^0.5.0;

// import './ERC777/examples/ReferenceToken.sol';
// import './OZ_basics/ownership/Ownable.sol';
import './ERC1400/ERC1400.sol';

contract Della_Security_Token is ERC1400 /* ERC777ReferenceToken */ {

  address private _campaign_address;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _granularity,
    address _controller
    /* For testing only */
    ,address ERC820Registry_Address
  )
  ERC1400(_name, _symbol, _granularity, _controller, ERC820Registry_Address)
  public {
    

  }

    /* DELLA FUNCTIONS */
  function set_campaign_address(address campaign_address) public onlyOwner {
      _campaign_address = campaign_address;
      // emit Campaign_address_set(_campaign_address);
  }


}
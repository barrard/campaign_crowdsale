pragma solidity ^0.5.0;

import './OZ_basics/ownership/Ownable.sol';


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
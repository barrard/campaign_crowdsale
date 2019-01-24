pragma solidity ^0.5.0;

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

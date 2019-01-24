pragma solidity ^0.5.0;

import './OZ_basics/ownership/Ownable.sol';

contract FinalizableCrowdsale_interface {
  function finalized() public view returns(bool){}
}

contract Data_Storage_iface {
  function get_authorized_investor(address investor) view external returns(bool){}
  function get_enabled_campaign(address capaign_address) view external returns(bool){}
  function get_controllers_for(address token_address) view external returns(address[] memory){}
  function is_controller_for(address token_address, address controller_address) external view returns(bool){}
  function add_document_to_token(address document_setter, address token_address, bytes32 doc_name, string calldata doc_uri, bytes32 doc_hash ) external {}
  function get_document_to_token(address token_address, bytes32 doc_name) view external returns (string memory, bytes32, uint256) {}

}


contract Restricted_transfer_service is Ownable {

  // address private _Della_address;
  address private _data_store_address;
  

  // constructor(address Della_address) internal {
  //   _Della_address = Della_address;
  // }

    // Document Management
  function get_document_to_token(
    bytes32 _name) 
    public view returns 
    (string memory, bytes32, uint256){
    // string doc_uri;
    bytes32 doc_hash;
    string memory doc_uri;
    uint doc_modified;
    Data_Storage_iface data_store = Data_Storage_iface(_data_store_address);
    (doc_uri, doc_hash, doc_modified) = data_store.get_document_to_token(address(this), _name);
    return (doc_uri, doc_hash, doc_modified);
  }

  function add_document_to_token(
    address document_setter, 
    bytes32 doc_name, 
    bytes32 doc_hash, 
    string calldata doc_uri) external {
    // require(false, "This is meant for the token");
    Data_Storage_iface data_store = Data_Storage_iface(_data_store_address);
    data_store.add_document_to_token(document_setter, msg.sender, doc_name, doc_uri, doc_hash);

  }



  function set_data_store_address(address data_store_address) public onlyOwner{
    _data_store_address = data_store_address;
  }
  function get_data_store_address() public view onlyOwner returns (address){
    return _data_store_address;
  }

  function is_finalized(address campaign_address) external view returns(bool){
    FinalizableCrowdsale_interface campaign = FinalizableCrowdsale_interface(campaign_address);
    bool finalized = campaign.finalized();

    return finalized;

  }
  /* Check is the receiver is authorized */
  function is_authorized(address _token_receiver) external view returns(bool){
    Data_Storage_iface data_store = Data_Storage_iface(_data_store_address);
    bool authorized = data_store.get_authorized_investor(_token_receiver);
    return authorized;
  }
  function is_trading_endabled (address campaign_address) external view returns(bool){
    Data_Storage_iface data_store = Data_Storage_iface(_data_store_address);
    bool is_enabled = data_store.get_enabled_campaign(campaign_address);
    return is_enabled;
  }

  function is_controller_for(address token_address, address controller_address) external view returns(bool){
    Data_Storage_iface data_store = Data_Storage_iface(_data_store_address);
    // return true;
    return data_store.is_controller_for(token_address, controller_address);
  }

  function controllers_for(address token_address) public view returns (address[] memory){
    Data_Storage_iface data_store = Data_Storage_iface(_data_store_address);
    return data_store.get_controllers_for(token_address);

  }



}

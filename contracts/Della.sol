pragma solidity ^0.5.0;

import './OZ_basics/ownership/Ownable.sol';

contract Campaign_Deployer_interface{
  function create_campaign(
    uint goal, address payable wallet, uint time_limit
  ) public returns (address, address){}
}

contract Data_Storage_Contract{
  function add_token_and_campaign(address token_address, address campaign_address) external{}
  function get_terms_and_agreement_signed(address investor_address) external view returns(bool){}
  function set_terms_and_agreement_signed(address investor_address, string calldata name, string calldata IP) external{}
  function can_start_campaign(address investor_address) view external returns(bool){}

}

contract Della is Ownable {

  address private _campaign_deployer_address;
  address private _data_storage_address;


  //  EVENTS
/* Emit an event when the Campaigns is deployed */
  event Campaign_Deployed(
    address indexed campaign_address,
    address indexed token_address,
    address indexed wallet_address
  );

  // event Approved_fundraiser(
  //     uint256 event_time,
  //     address indexed fundraiser_address); 
      
  event Terms_and_agreement_signed(
    uint256 event_time,
    address indexed fundraiser_address,
    string name
  );



  //keep track of campaign count/ID //TODO

/* Function to make Campaigns */
/* Goal in USD */
/* Wallet address who receives completed fundraise */
/* Time limit in seconds */
  function make_tokenized_campaign(

      uint goal, //USD i.e. 500000
      address payable wallet_address, 
      uint time_limit
    ) public {
      /*  Verify user can start a campaign by cheching the sata store */
      Data_Storage_Contract data_storage = Data_Storage_Contract(_data_storage_address);
      require(data_storage.can_start_campaign(wallet_address), "Please sign terms and agrremment first");

      address token_address;
      address campaign_address;
      /* Create instance of deployer */
      Campaign_Deployer_interface deployer = Campaign_Deployer_interface(_campaign_deployer_address);
      /* Execute create campaign function with the goal, payable wallet address and time limit*/
      (campaign_address, token_address) = deployer.create_campaign(goal, wallet_address, time_limit);
      /* Write to data storage the token and campaign addess */
      data_storage.add_token_and_campaign(token_address, campaign_address);
      /* Emit the event Campaign Deployed with the new addresses */
      emit Campaign_Deployed(
        address(campaign_address), address(token_address), address(wallet_address)
      );
      
    }

  function set_data_storage_address(address data_storage_address) public onlyOwner{
    _data_storage_address = data_storage_address;
  }
  function set_crowdsale_deployer_address(address campaign_deployer_address) public onlyOwner{
    _campaign_deployer_address = campaign_deployer_address;
  }

  function sign_terms_and_agreement(string memory name, string memory IP) public {
    Data_Storage_Contract data_storage = Data_Storage_Contract(_data_storage_address);
    bool flag = data_storage.get_terms_and_agreement_signed(msg.sender);
    require(!flag, "You already Signed Terms and agreement" );
    data_storage.set_terms_and_agreement_signed(msg.sender, name, IP);
    emit Terms_and_agreement_signed(
      block.timestamp,
      msg.sender,
      name);


  }


}
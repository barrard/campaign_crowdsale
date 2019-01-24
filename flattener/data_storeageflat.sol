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

// File: contracts/Data_Storage.sol

/**
 * @title Contract that will store data.
 */
 
contract Data_Storage is Ownable{ 

  /* Document Management ERC1643 */
  struct Doc {
    string docURI;
    bytes32 docName;
    bytes32 docHash;
    uint modified;
    uint id;
    
  }

  mapping(address=>mapping(bytes32 =>Doc)) private _token_document;
  mapping(address =>Doc[]) private _all_token_documents;
    //Sender_address, Token_address bool
  mapping(address=>mapping(address=>bool)) private _can_edit_documents_for;

  mapping(address => bool) private _can_write_data;

  /* List / count total campaigns/tokens addresses */
  uint private _tokenized_campaign_count;

  address[] private _campaign_address_list;
  address[] private _token_address_list;

  struct User_Signature{
    string name;
    string IP;
    uint time;
  }

  /* Makaging tokens mapping to campaigns */
  mapping(address=>address) private _campaign_to_token;
  mapping(address=>address) private _token_to_campaign;


/* Restricted token managment */
  mapping(address=>bool) private _terms_and_agreement_signed;
  mapping(address=>User_Signature) private _user_signature;
  mapping(address=>bool) private _enabled_campaigns;
  mapping(address=>bool) private _authorized_investors;
  mapping(address => mapping(address=>bool)) private _is_controller_for;
  mapping(address => address[]) private _controllers_for;




  constructor() public {
    _tokenized_campaign_count = 0;
    _can_write_data[address(this)] = true;
    _can_write_data[msg.sender] = true;

  }
/* Determine if address can edit focuments for given tokem address */
  modifier only_document_setter (address document_setter,address token_address){
    require(_can_edit_documents_for[document_setter][token_address], "Not authorized Document Manager");
    _;
  }

/* Modifier to determin if address has write access */
  modifier write_access(){
    require(_can_write_data[msg.sender], "You dont have write access");
    _;
  }
  /* Set address to have given write access to the data store */
  function set_write_access(
    address writer_address, 
    bool flag) public onlyOwner {
    _can_write_data[writer_address] = flag;
  }

  /* set the rights of address to have access to edit documents for given token address */
  function set_document_manager(
    address document_manager, 
    address token_address, 
    bool flag) public onlyOwner {
    _can_edit_documents_for[document_manager][token_address] = flag;
  }

/* Get document doc_name for given token address */
  function get_document_to_token(
    address token_address, 
    bytes32 doc_name
    ) 
    public view returns (string memory, bytes32, uint256) 
  {
    Doc memory doc = _token_document[token_address][doc_name];
    return (doc.docURI, doc.docHash, doc.modified);
  }

/* Attatch document to given token address */
  function add_document_to_token(
    address document_setter,
    address token_address,
    bytes32 doc_name, 
    string memory doc_uri, 
    bytes32 doc_hash
    ) 
    public only_document_setter(document_setter, token_address){
    Doc memory doc;
    doc.docName = doc_name;
    doc.docURI = doc_uri;
    doc.docHash = doc_hash;
    doc.modified = block.timestamp;
    doc.id = _all_token_documents[token_address].length;

    _all_token_documents[token_address].push(doc);
    _token_document[token_address][doc_hash] = doc;

  }
/* Get list of contrellers for given token address */
  function get_controllers_for(address token_address) public view returns(address[] memory){
    return _controllers_for[token_address];
  }

/* check is token address can be controlled by said controller address */
  function is_controller_for(address token_address, address controller_address) public view returns(bool){
    // return true;
    return _is_controller_for[token_address][controller_address];
  }

/* Add controller rights to controller address for token address */
  function add_controller_for(address token_address, address controller_address) public onlyOwner{
    _add_controller_for(token_address, controller_address);
  }
  

  /* INTERNAL */
  function _add_controller_for(address token_address, address controller_address) internal{
    _is_controller_for[token_address][controller_address] = true;
    _controllers_for[token_address].push(controller_address);
  }
  
  function get_tokenized_campaign_count() view public returns(uint){
    return _tokenized_campaign_count;
  }

  function can_start_campaign(address investor_address) view external returns(bool){
    /* ensure they signed the terms and agreement */
    bool terms_signed = _terms_and_agreement_signed[investor_address];
    return terms_signed;
  }


  function add_token_and_campaign(address token_address, address campaign_address) public write_access{
    _campaign_address_list.push(campaign_address);
    _token_address_list.push(token_address);
    _campaign_to_token[campaign_address] = token_address;
    _token_to_campaign[token_address] = campaign_address;
    _tokenized_campaign_count++;
    _add_controller_for(token_address, this.owner());

  }

  function set_token_to_campaign(address token_address, address campaign_address) public write_access{
    _token_to_campaign[token_address] = campaign_address;
  }

  function get_token_to_campaign(address token_address) public view returns(address){
    return _token_to_campaign[token_address];
  }

  function set_campaign_to_token(address campaign_address, address token_address) public write_access{
    _campaign_to_token[campaign_address] = token_address;
  }

  function get_campaign_to_token(address campaign_address) public view returns(address){
    return _campaign_to_token[campaign_address];
  }



  function set_terms_and_agreement_signed(address investor_address, string memory name, string memory IP) public write_access{
    _terms_and_agreement_signed[investor_address] = true;
    _user_signature[investor_address] = User_Signature(name, IP, block.timestamp);
  }

  function get_terms_and_agreement_signed(address investor_address) public view returns(bool){
    return _terms_and_agreement_signed[investor_address];
  }




  function set_authorized_investor(address investor_address, bool flag) public write_access{
    _authorized_investors[investor_address] = flag;
  }

  function get_authorized_investor(address investor_address) public view returns(bool){
    return _authorized_investors[investor_address];
  }

  function set_enabled_campaign(address capaign_address, bool flag) public write_access{
    _enabled_campaigns[capaign_address] = flag;
  }

  function get_enabled_campaign(address capaign_address) public view returns(bool){
    return _enabled_campaigns[capaign_address];
  }
  
}

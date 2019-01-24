var colors = require('colors');
var logger = require('tracer').colorConsole({
  format: "{{timestamp.green}} <{{title.yellow}}> {{message.cyan}} (in {{file.red}}:{{line}})",
  dateformat: "HH:MM:ss.L"
});

/* FOR TESTING ONLY */
var ERC820Registry = artifacts.require("./ERC820/ERC820Registry.sol");

/* DellaContracts */
/* Della is the main link to campaign deployer */
var Della = artifacts.require("./Della.sol");
var Eth_price_Oracle = artifacts.require("./Eth_price_Oracle.sol");
var Campaign_Deployer = artifacts.require("./Campaign_Deployer.sol");
var Token_Creator = artifacts.require("./Token_Creator.sol");

var Restricted_transfer_service = artifacts.require("./Restricted_transfer_service.sol");
var Data_Storage = artifacts.require("./Data_Storage.sol");



module.exports = function(deployer, netowrk, accounts) {
  /* Deploy ERC820 Registry ONLY FOR TESTING */
  let ERC820Registry_addr = ERC820Registry.address;

  /* Deploy Della */
  deployer.deploy(Della).then(async ()=>{
/* Deploy Eth Price Oracle */
    await deployer.deploy(Eth_price_Oracle); 
    let Eth_price_Oracle_inst = await Eth_price_Oracle.deployed();
    let Eth_price_Oracle_addr = await Eth_price_Oracle_inst.address;

    let Della_inst = await Della.deployed();
  /* Get Della Address */
    let Della_addr = await Della_inst.address;

    // logger.log({Della_addr});

    /* Deploy Campaign Creator (Deployer)  */
    await deployer.deploy(Campaign_Deployer , Della_addr, ERC820Registry_addr);
    /* Get Campaign Deployer address */
    let Campaign_Deployer_inst = await Campaign_Deployer.deployed()
    let Campaign_Deployer_addr = await Campaign_Deployer_inst.address
    /* Deploy Token Creator */
    await deployer.deploy(Token_Creator , Campaign_Deployer_addr, Della_addr);
    let Token_Creator_inst = await Token_Creator.deployed();
    let Token_Creator_addr = await Token_Creator_inst.address;


/* Storage and Restricted token logic */
    await deployer.deploy(Restricted_transfer_service)
    let Restricted_transfer_service_inst = await Restricted_transfer_service.deployed()
    let Restricted_transfer_service_addr = await Restricted_transfer_service_inst.address;
  
    await deployer.deploy(Data_Storage)
    let Data_Storage_inst = await Data_Storage.deployed();
    let Data_Storage_addr = await Data_Storage_inst.address
    /* Set Della write access to true */
    await Data_Storage_inst.set_write_access(Della_addr, true);

    /* ALL ADDRESS */
    /* Eth Price Oracle */logger.log({})
    /* DELLA */ logger.log({Della_addr})
    /* Campaign Deployer */ logger.log({Campaign_Deployer_addr})
    /* Token Creator */ logger.log({Token_Creator_addr})
    /* Restricted token serbive */ logger.log({Restricted_transfer_service_addr})
    /* Della Data */ logger.log({Data_Storage_addr})

    /* Register address of services */
    await Della_inst.set_data_storage_address(Data_Storage_addr)
    await Della_inst.set_crowdsale_deployer_address(Campaign_Deployer_addr)
    //TODO transfer ownership
    await Campaign_Deployer_inst.set_oracle_address(Eth_price_Oracle_addr)
    await Campaign_Deployer_inst.set_restricted_token_address(Restricted_transfer_service_addr)
    await Campaign_Deployer_inst.set_token_creator_address(Token_Creator_addr)
    



  });



};


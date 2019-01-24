colors = require('colors');
logger = require('tracer').colorConsole({
 format: "{{timestamp.green}} <{{title.yellow}}> {{message.cyan}} (in {{file.red}}:{{line}})",
 dateformat: "HH:MM:ss.L"
})
const assert = require('assert');
var expectThrow = require('./helper.js');
const M = require('./methods.js');
var event_parser = require('./event_parser.js');
// var web3 = require('web3');
// var web3 = new web3();
var Eth_price_Oracle = artifacts.require('Eth_price_Oracle')
var Campaign_Deployer = artifacts.require('Campaign_Deployer')
var Campaign_Crowdsale = artifacts.require('Campaign_Crowdsale')
var RefundEscrow = artifacts.require('RefundEscrow')
var Della = artifacts.require('Della')
var Della_Security_Token = artifacts.require('Della_Security_Token')
var Data_Storage = artifacts.require("./Data_Storage.sol");
var Token_Creator = artifacts.require("./Token_Creator.sol");
var ERC820Registry = artifacts.require("./ERC820Registry.sol");



contract('Campaign_Deployer', async (accounts)=>{
 try {
   one = accounts[0]
   two = accounts[1]
   three = accounts[2]

   let Della_inst = await Della.deployed();
   let Data_Storage_inst = await Data_Storage.deployed();
   let eth_price_oracle = await Eth_price_Oracle.deployed();
   let Token_Creator_inst = await Token_Creator.deployed()
   let ERC820Registry_inst = await ERC820Registry.deployed()
   let Campaign_Deployer_inst = await Campaign_Deployer.deployed()

   let ERC820Registry_addr = await ERC820Registry_inst.address
   let Della_addr = await Della_inst.address
   logger.log(`~~~~~~~~~   TEST    ~~~~~~~~~~~~~`.cyan)

   let campaign_deployer_addr = Campaign_Deployer_inst.address
   // logger.log({campaign_deployer_address})
   // var campaign_count = await campaign_deployer.campaign_count.call()
   //  campaign_count = campaign_count.toNumber()
   // logger.log({campaign_count})

   //deploy 10 campaigns.....
   // let ten_deployed_campaign_tx = await deploy_ten_campaigns(accounts, Della_inst)
   
   /* SIGN TERMS AND AGREEMENT */
   let sign_agreement = await Della_inst.sign_terms_and_agreement("Dave", "111.111.111.111", {from:one})
  //  logger.log(sign_agreement)

  //  let tc = await Token_Creator_inst.create_token('name', 'symbol', new web3.utils.BN('1000000000000000000'), ERC820Registry_addr);
  //  logger.log(tc)
  //  event_parser.parse_logs(tc.receipt.rawLogs)
  let cal_mul = await Campaign_Deployer_inst.cal_Multiple(new web3.utils.BN('20000000000000000000'))
  logger.log(cal_mul)
  logger.log(cal_mul[0])
  logger.log(cal_mul['0'])
  logger.log(cal_mul['0'].toString())
  logger.log(cal_mul['1'].toString())
  //   logger.log(token_made)
  logger.log(`FFUUUCCCKKK TTTHIIISSSS`)


  
    let deploy_first_campaign_transaction = await Della_inst.make_tokenized_campaign(
     1000,//uint goal, in USD? 
     one,//address wallet, 
     10000//uint256 time_limit, in seconds
   , {
     from:one
   })

   
   logger.log(deploy_first_campaign_transaction)
  //  logger.log(deploy_first_campaign_transaction.logs)
  //  logger.log(deploy_first_campaign_transaction.receipt.rawLogs)
  //  logger.log(deploy_first_campaign_transaction.logs)
   event_parser.parse_logs(deploy_first_campaign_transaction.receipt.rawLogs)

   var {campaign_address, token_address, wallet_address} = event_parser.parse_new_campaign_details(deploy_first_campaign_transaction.logs)
   let first_campaign_address = campaign_address
   let first_token_address = token_address


   logger.log({first_campaign_address, first_token_address})
   
   //create instance of the first campaign
   let first_Campaign_Crowdsale = await Campaign_Crowdsale.at(first_campaign_address)
   let first_Della_Security_Token = await Della_Security_Token.at(first_token_address)
   let escrow_address = await first_Campaign_Crowdsale.escrow_address()
   logger.log({escrow_address})
   let escrow_inst = await RefundEscrow.at(escrow_address)
   let bene = await escrow_inst.beneficiary()
   logger.log({bene})

   var rate = await first_Campaign_Crowdsale.rate()//20000000000000000000
   rate = new web3.utils.BN(rate);
   logger.log(`Rate is ${rate}`)
   logger.log(web3.utils.fromWei(rate, 'ether'))//  35971223021582733
   //Loging a token balance          
   M.log_token_balance(first_Della_Security_Token, 'first_Della_Security_Token', first_campaign_address, 'first_campaign_address')    
   var one_eth_balance_before = await M.log_eth_balance(one, 'one_eth_balance_before')
   // one_eth_balance_before = one_eth_balance_before.toString();
   // logger.log({one_eth_balance_before})
   // 100000000000000000000   
   //35971223021582733000 
   M.log_eth_balance(first_campaign_address, 'first_campaign_address');


  //  var cal_goal_res = await first_Campaign_Crowdsale.cal_goal();
  //  logger.log({cal_goal_res})
  //  var cal_goal = cal_goal_res[0]
  //  var goal_in_wei = cal_goal_res[1]

   
  //  let cal_eth_goal = web3.utils.fromWei(cal_goal, 'ether');
  //  let goal_in_eth = web3.utils.fromWei(goal_in_wei, 'ether');
  //  logger.log({goal_in_eth});
  //  logger.log({cal_eth_goal});
  //  let calculated_goal_diff = cal_goal.sub(goal_in_wei).toNumber();
  //  logger.log('Should be Zero'.yellow)
  //  logger.log({calculated_goal_diff})

   //get total token supply
   var first_token_supply = await first_Della_Security_Token.totalSupply()
     first_token_supply = first_token_supply.toString()
   logger.log({first_token_supply})

   //get total token decimals
   var first_token_decimals = await first_Della_Security_Token.decimals()
   first_token_decimals = first_token_decimals.toNumber()
   logger.log({first_token_decimals})
   // logger.log(first_Campaign_Crowdsale)
   // logger.log(web3._extend.utils.toWei(1, 'ether'))//1000000000000000000                  3597122302158273381
   var token_count = new web3.utils.BN(18)
   let val_for_tokens = rate.mul(token_count)
   logger.log(`Val for tokens is ${val_for_tokens}`)

   /* AUTHORIZE THIS USER */
   Data_Storage_inst.set_authorized_investor(one, true)
   Data_Storage_inst.set_authorized_investor(two, true)
   // Data_Storage_inst.set_authorized_investor(three, true)
   var BN = web3.utils.BN
   let granularity = await first_Della_Security_Token.granularity()
   let granularity_ = granularity.toString()
   logger.log({granularity_})

   logger.log(`------------------------------  PURCHASE ${token_count} TOKENS  ------------------------------------`)
   let buy_token_receipt = await first_Campaign_Crowdsale.sendTransaction({from:two, value: val_for_tokens})
   logger.log('buy_token_receipt'.green)
   logger.log(buy_token_receipt)
  //  event_parser.parse_logs(buy_token_receipt.receipt.logs)
   event_parser.parse_logs(buy_token_receipt.receipt.rawLogs)
   event_parser.parse_token_purchase(buy_token_receipt.logs)
   //Loging a token balance
   M.log_token_balance(first_Della_Security_Token, 'first_Della_Security_Token', first_campaign_address, 'first_campaign_address')    
   M.log_token_balance(first_Della_Security_Token, 'first_Della_Security_Token', one, 'account one')    

   //     9106100000000000
   //   359712230215827300
   //   359712230215827300
   //   7194244604316546

   // 98736549800000000000
   // 98727443700000000000

   var one_eth_balance_after = await M.log_eth_balance(one, 'one_eth_balance_after')
   await M.log_eth_balance(first_campaign_address, 'first_campaign_address')
   await M.log_eth_balance(escrow_address, 'escrow_address')
   
   var total_spend_on_tokens = new BN(new BN(one_eth_balance_before).sub(new BN(one_eth_balance_after)))
   var tx_cost = new BN(total_spend_on_tokens.sub((new BN)))

   total_spend_on_tokens = web3.utils.fromWei(total_spend_on_tokens, 'ether')
   // total_spend_on_tokens=total_spend_on_tokens.toString()

   
   tx_cost = new BN(web3.utils.fromWei(tx_cost, 'ether'))
   // tx_cost=tx_cost.toNumber()
   
   val_for_tokens = new BN(web3.utils.fromWei(new BN(val_for_tokens), 'ether'))
   val_for_tokens = val_for_tokens.toString()

   logger.log({val_for_tokens})
   logger.log({total_spend_on_tokens})
   logger.log({tx_cost})
   var weiRaised = await first_Campaign_Crowdsale.weiRaised()
   var ethRaised = web3.utils.fromWei(new BN(weiRaised), 'ether')
   // ethRaised = ethRaised.toNumber()
   logger.log({ethRaised})
   logger.log(`======================   `+`should be finalized  `.magenta+`  ================================`.cyan)
   var is_finalized = await first_Campaign_Crowdsale.finalized()
   var goal = await first_Campaign_Crowdsale.goal()
   var raised = await first_Campaign_Crowdsale.weiRaised()
   var goal_reached = await first_Campaign_Crowdsale.goalReached()
   logger.log({goal_reached})
   // goal=goal.toNumber()
   // raised=raised.toNumber()
   logger.log({is_finalized})
   logger.log({goal})
   logger.log({raised})
   let is_goal_met = raised >= goal 
   logger.log({is_goal_met})
   // let flag = await first_Campaign_Crowdsale.flag()
   // logger.log({flag})
   var goal_reached = await first_Campaign_Crowdsale.goalReached()
   logger.log({goal_reached})

//Enable trading
   await Data_Storage_inst.set_enabled_campaign(first_campaign_address, true, {from:one});

//transfer to another account...


var transfer_to_two = await first_Della_Security_Token.transfer(two, web3.utils.toWei(new BN(10), "ether"), {from:one})
/* SHOULD FAIL GRANULARITY TEST */
// let transfer_to_two = await first_Della_Security_Token.transfer(two, 10, {from:one})
// logger.log({transfer_to_two})
   // event_parser.parse_logs(transfer_to_two.receipt.logs)

M.log_token_balance(first_Della_Security_Token, 'first_Della_Security_Token', one, 'account one')    
M.log_token_balance(first_Della_Security_Token, 'first_Della_Security_Token', two, 'account two')    

/* CONTROLLER TRANSFERS ERC1644 */
let is_controllable = await first_Della_Security_Token.isControllable()
logger.log({is_controllable})
var can_transfer = await first_Della_Security_Token.controllerTransfer( 
 two,  three, 
 // 1,//should fail granularity test
 web3.utils.toWei(new BN(1), 'ether'), //1 token @ 1*10^18
 web3.utils.fromAscii("TEST!!"),  
 web3.utils.fromAscii("TEST!!"),
 {from:accounts[0]}
)
// can_transfer = can_transfer.toNumber()
// logger.log({can_transfer})    
logger.log(can_transfer.logs)
M.log_token_balance(first_Della_Security_Token, 'first_Della_Security_Token', one, 'account one')    
M.log_token_balance(first_Della_Security_Token, 'first_Della_Security_Token', two, 'account two')    
M.log_token_balance(first_Della_Security_Token, 'first_Della_Security_Token', three, 'account three')    

/* Document Managememt ERC1643 */
var doc_name = web3.utils.toHex("doc name");
var doc_uri = "www.google.com"
var doc_hash = web3.utils.toHex('Document text')
logger.log({doc_hash, doc_name, doc_uri})
var setting_document_resp = await first_Della_Security_Token.setDocument(doc_name, doc_uri, doc_hash, {from:one});
 logger.log({setting_document_resp})

// event_parser.parse_logs(can_transfer.receipt.logs)
//Try to transfer tokens to a smart contract
   // let token_transfer_atempt = await first_Della_Security_Token.transfer(first_campaign_address, 10, {from:one})
   // logger.log({token_transfer_atempt})
   // event_parser.parse_logs(token_transfer_atempt.receipt.logs)
  

   // get_known_addresses
   // let known_addresses = await first_Della_Security_Token.get_known_addresses()
   // logger.log({known_addresses})
   // let rtoken = await first_Della_Security_Token.get_rToken_service()
   // logger.log({rtoken})


 } catch (err) {
   logger.log('err'.bgRed)
   logger.log(err)
 }

})


// async function deploy_ten_campaigns(accounts, Della_inst){
//  new Promise(function(resolve, reject){
//    accounts.forEach(async account =>{
//      let deploy_first_campaign_transaction = await Della_inst.make_tokenized_campaign(
//        100000,//uint goal, 
//        account,//address wallet, 
//        10000//uint256 time_limit, in seconds
//      , {
//        from:account
//      })
     
//    })
//    resolve()
//  })
// }

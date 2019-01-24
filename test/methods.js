colors = require('colors');
logger = require('tracer').colorConsole({
 format: "{{timestamp.green}} <{{title.yellow}}> {{message.cyan}} (in {{file.red}}:{{line}})",
 dateformat: "HH:MM:ss.L"
})

module.exports = {
  async log_eth_balance(addr, log_msg){
      var bal = await web3.eth.getBalance(addr)
      // logger.log(bal.toString())
      var bal = web3.utils.fromWei(bal.toString(), 'ether')
      if(log_msg) logger.log(`Balance`.yellow+` of ${log_msg}`.blue +` is `+`${bal}`.green)
      
      return(bal)
 
  },
  async log_token_balance(token, token_name, addr, addr_name){
    var balance = await token.balanceOf(addr);

    let BN = web3.utils.BN;

    let one_ether = new BN(web3.utils.toWei('1', 'ether'))
    // logger.log(web3.utils.isBN(one_ether))
    // balance = balance.div(one_ether)
    // logger.log({balance})//100.000000000000000000
    if(token_name && addr_name){
      logger.log(`${token_name}`.yellow+` Token balance for `+`${addr_name}`.blue+` is `+`${balance}`.green)
    }
    return balance
  
  }
}






// 02:20:51.99 <log> Balance of one_eth_balance_before is 86010846000000000000 (in methods.js:10)
// 02:20:52.44 <log> Balance of one_eth_balance_after is  86001739900000000000 (in methods.js:10)
//                                                            9106100000000000

// 02:20:52.44 <log> { total_spend_on_tokens: 9106100000000000 } (in eth_price.js:113)
// 02:20:52.44 <log> { val_for_tokens: 359712230215827300 } (in eth_price.js:115)
// 02:20:52.44 <log> { tx_cost: -350606130215827300 } (in eth_price.js:117)
// 02:20:52.46 <log> { balance: '1.999e+22' } (in methods.js:18)

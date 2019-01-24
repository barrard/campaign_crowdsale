const fs = require('fs')
// const abiDecoder = require('abi-decoder'); // NodeJS
readFiles(__dirname + '/../build/contracts/')
// logger.log(__dirname)

/* EVENT HASH MAP */
var hash_map = {
  /* 
    name:{
      hash:'',
      inputs:[{indexed:'bool', name:'str', type:'uint256'}]
      THIS IS JUST AN EXAMPLE
  }
  */
}

module.exports = {
  hash_map, parse_logs, parse_new_campaign_details, parse_token_purchase
}

function _get_event_data_from_logs(logs, event_name) {
  // logger.log(logs.length)
  logger.log(`${event_name}`.magenta)
  let event_index = logs.findIndex(detail => detail.event == event_name)
  logger.log(event_index)
  if (event_index < 0) throw `Didnt find the ${event_name} event`
  let data = logs[event_index].args
  logger.log(data)
  // let {campaign_address, token_address, wallet_address} = data
  return data

}

function parse_token_purchase(logs) {
  var { purchaser, beneficiary, value, amount, refund_amount } = _get_event_data_from_logs(logs, "TokensPurchased")
  value = value.toString()
  amount = amount.toString()
  refund_amount = refund_amount.toString()
  logger.log({purchaser, beneficiary, value, amount, refund_amount})
}

function parse_new_campaign_details(logs) {
  //find the log with Campaign_Deployed event
  logger.log(`logs length is ${logs.length}`)
  // logger.log(logs)
  let Campaign_Deployed_index = logs.findIndex(detail => detail.event == 'Campaign_Deployed')
  if (Campaign_Deployed_index < 0) throw "Didnt find the Campaign_Deployed event"
  let data = logs[Campaign_Deployed_index].args
  // let {campaign_address, token_address, wallet_address} = data
  return data
}



function parse_logs(logs) {
  // logger.log(logs)
  logs.forEach(log => {
    // logger.log(log)
    let topics = log.topics
    let func = topics[0]//first item in topics is the hash function signature
    // logger.log(func)
    //find func in hash map
    for (let event in hash_map) {
      // logger.log(event)
      // logger.log(hash_map[event].hash)
      if (hash_map[event].hash == func) {
        logger.log('----------------- Event Parser ---------------'.yellow)
        logger.log({ event })
        if (topics.length <= 1) return
        topics.shift()//skip the first topic to get input data
        let input_data = topics.map((input_data) => { return input_data })
        input_data.forEach((data, i) => {
          // logger.log(data)
          let type = hash_map[event].inputs[i].type
          let name = hash_map[event].inputs[i].name
          // logger.log(type)
          // logger.log(name)
          if (type == "address") logger.log(`${name} = 0x${data.slice(26)}`)
          else if (type == "string") logger.log(`${name} = ${web3.toAscii(data)}`)
          else if (type == "uint256") logger.log(`${name} = ${parseInt(data)}`)
          else logger.log(`${name} of type ${type} val = ${data}`)


        });
        logger.log('                 end                 '.blue)
      }
    }
  });
}


function parse(abi) {
  // logger.log(abi)
  let events = abi.filter((i) => {
    return (i.type == "event");
  })
  events.forEach(event => {
    // logger.log(event)

    // if(hash_map[event.name])throw 'Already seen this event ' + event.name
    hash_map[event.name] = {}
    hash_map[event.name].inputs = []


    // logger.log(event.inputs)
    let inputs = event.inputs
    let s = `${event.name}(`//createing the string forms on function name, and parmeter types
    for (let i = 0; i < inputs.length; i++) {
      // logger.log(inputs[i])
      let { indexed, name, type } = inputs[i]
      hash_map[event.name].inputs.push({ indexed, name, type })//track the inputs, why?
      s += `${inputs[i].type}`//comma seperated parameter types, ofcourse this could be done any ways, but this one works
      if (i !== inputs.length - 1) s += `,`
    }
    s += `)`//finshed function signature string
    // logger.log(s)
    hash_map[event.name].hash = web3.utils.sha3(s)//save hased signature

  });
}

function onFileContent(filename, content) {
  // logger.log({filename})
  let abi = JSON.parse(content).abi
  // logger.log(abi.length)
  parse(abi)

}

function onError(err) {
  // logger.log(err)
}


function readFiles(dirname) {
  // logger.log('READ '+dirname)
  fs.readdir(dirname, function (err, filenames) {
    if (err) {
      onError(err);
      return;
    }
    filenames.forEach(function (filename) {
      fs.readFile(dirname + filename, 'utf-8', function (err, content) {
        if (err) {
          onError(err);
          return;
        }
        onFileContent(filename, content);
      });
    });
  });
}





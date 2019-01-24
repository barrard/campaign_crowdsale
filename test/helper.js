var colors = require('colors');
var logger = require('tracer').colorConsole({
  format: "{{timestamp.green}} <{{title.yellow}}> {{message.cyan}} (in {{file.red}}:{{line}})",
  dateformat: "HH:MM:ss.L"
})


module.exports =  async (promise) => {
  try {
    await promise;
  } catch (err) {
    return true;
  }
  throw('this contract should throw')
  return false
}
var ERC820Registry = artifacts.require("./ERC820/ERC820Registry.sol");
var Della_Security_Token = artifacts.require("./ERC820/Della_Security_Token.sol");

module.exports = function(deployer) {
  deployer.deploy(ERC820Registry).then(async()=>{
    // let erc820_inst = await ERC820Registry.deployed();
    // let addr = await erc820_inst.address;
    // await deployer.deploy(Della_Security_Token, "name", "sm", 18, addr)
  });
};

pragma solidity ^0.5.0;

import "./ERC820Client.sol";


contract ExampleClient is ERC820Client {

    address private owner;

    constructor() public {
        setInterfaceImplementation("ExampleClient", address(this));
        owner = msg.sender;
    }

    function delegateManager() public {
        require(owner == msg.sender, "Not the owner");
        delegateManagement(msg.sender);
    }

}

pragma solidity ^0.5.0;


contract ERC820Registry_iface {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) public;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) public view returns (address);
    function setManager(address _addr, address _newManager) public;
    function getManager(address _addr) public view returns(address);
}


/// Base client to interact with the registry.
contract ERC820Client {
    // ERC820Registry constant ERC820REGISTRY = ERC820Registry(0x820b586C8C28125366C998641B09DCbE7d4cBF06);
    
    /* ADDED CONSTRUCTOR FOR TESTING */
    ERC820Registry_iface ERC820REGISTRY;
    constructor(address erc820_addr) internal {
        ERC820REGISTRY = ERC820Registry_iface(erc820_addr);
    }


    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC820REGISTRY.setManager(address(this), _newManager);
    }
}

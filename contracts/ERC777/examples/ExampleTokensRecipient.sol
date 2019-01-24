/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
pragma solidity ^0.5.0;

import "../ERC777TokensRecipient.sol";
import "../../ERC820/ERC820Client.sol";
import "../../ERC820/ERC820ImplementerInterface.sol";


contract ExampleTokensRecipient is ERC820Client, ERC820ImplementerInterface, ERC777TokensRecipient_proto {

    bool private preventTokenReceived;

    constructor(bool _setInterface, bool _preventTokenReceived) public {
        if (_setInterface) { setInterfaceImplementation("ERC777TokensRecipient", address(this)); }
        preventTokenReceived = _preventTokenReceived;
    }

    function tokensReceived(
        address operator,  // solhint-disable no-unused-vars
        address from,
        address to,
        uint amount,
        bytes memory userData,
        bytes memory operatorData
    )  // solhint-enable no-unused-vars
        public
    {
        if (preventTokenReceived) { require(false, "Prevent locking is on"); }
    }

    // solhint-disable-next-line no-unused-vars
    function canImplementInterfaceForAddress(address addr, bytes32 interfaceHash) public view returns(bytes32) {
        return ERC820_ACCEPT_MAGIC;
    }

}

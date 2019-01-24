/* This Source Code Form is subject to the terms of the Mozilla public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
pragma solidity ^0.5.0; 


interface ERC777Token_iface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function granularity() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);

    function send(address to, uint256 amount) external;
    function send(address to, uint256 amount, bytes calldata userData) external;

    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
    function operatorSend(address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    ); // solhint-disable-next-line separate-by-one-line-in-contract
    event Minted(address indexed operator, address indexed to, uint256 indexed amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 indexed amount, bytes userData, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

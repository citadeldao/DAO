// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


import "./ICitadelDaoTransport.sol";
import "./DAO/Rewarding.sol";


// version 1
contract CitadelDao is Rewarding {

    constructor (address token) public {
        _Token = ICitadelDaoTransport(token);
    }

    function version() external pure returns (string memory) {
        return '1.0.0';
    }

}

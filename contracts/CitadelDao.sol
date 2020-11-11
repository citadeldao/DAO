// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


import "./ICitadelDaoTransport.sol";
import "./DAO/Voting.sol";


// version 1
contract CitadelDao is Voting {

    constructor (address token) public {
        _Token = ICitadelDaoTransport(token);
    }

    function version() external pure returns (string memory) {
        return '0.1.0';
    }

}

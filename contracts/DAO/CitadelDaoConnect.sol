// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "../../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../ICitadelDaoTransport.sol";


contract CitadelDaoConnect is Ownable {

    ICitadelDaoTransport internal _Token;

}

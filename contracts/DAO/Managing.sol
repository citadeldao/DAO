// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "../../node_modules/openzeppelin-solidity/contracts/access/AccessControl.sol";
import "../../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../ICitadelDaoTransport.sol";


contract Managing is Ownable, AccessControl {

    ICitadelDaoTransport internal _Token;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VOTING_ROLE = keccak256("VOTING_ROLE");

    constructor () public {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(VOTING_ROLE, ADMIN_ROLE);
    }

    function addAdmin(address account) public onlyOwner {
        _setupRole(ADMIN_ROLE, account);
    }

}

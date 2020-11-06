// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./CitadelDaoConnect.sol";
import "../../node_modules/openzeppelin-solidity/contracts/access/AccessControl.sol";


contract Managing is CitadelDaoConnect, AccessControl {

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

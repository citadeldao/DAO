// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./Managing.sol";
import "../IERC1202.sol";


contract Voting is IERC1202, Managing {

    event OnVote(uint issueId, address indexed _from, uint _value);
    event OnStatusChange(uint issueId, bool newIsOpen);

    function vote(uint issueId, uint option) external override
    returns (bool success) {

    }

    function setStatus(uint issueId, bool isOpen) external override
    returns (bool success) {

    }

    function issueDescription(uint issueId) external view override
    returns (string memory desc) {

    }

    function availableOptions(uint issueId) external view override
    returns (uint[] memory options) {

    }

    function optionDescription(uint issueId, uint option) external view override
    returns (string memory desc) {

    }

    function ballotOf(uint issueId, address addr) external view override
    returns (uint option) {

    }

    function weightOf(uint issueId, address addr) external view override
    returns (uint weight) {

    }

    function getStatus(uint issueId) external view override
    returns (bool isOpen) {

    }

    function weightedVoteCountsOf(uint issueId, uint option) external view override
    returns (uint count) {

    }

    function topOptions(uint issueId, uint limit) external view override
    returns (uint[] memory topOptions_) {

    }

}

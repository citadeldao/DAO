// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;


/**
 * https://eips.ethereum.org/EIPS/eip-1202
 * - Multiple issue
 * - Multiple selection
 * - Ordered multiple result
 **/
interface IERC1202 {
/*
    function vote(uint issueId, uint option) external returns (bool success);
    function setStatus(uint issueId, bool isOpen) external returns (bool success);

    function issueDescription(uint issueId) external view returns (string memory desc);
    function availableOptions(uint issueId) external view returns (uint[] memory options);
    function optionDescription(uint issueId, uint option) external view returns (string memory desc);
    function ballotOf(uint issueId, address addr) external view returns (uint option);
    function weightOf(uint issueId, address addr) external view returns (uint weight);
    function getStatus(uint issueId) external view returns (bool isOpen);
    function weightedVoteCountsOf(uint issueId, uint option) external view returns (uint count);
    function topOptions(uint issueId, uint limit) external view returns (uint[] memory topOptions_);

    event OnVote(uint issueId, address indexed _from, uint _value);
    event OnStatusChange(uint issueId, bool newIsOpen);
*/
}

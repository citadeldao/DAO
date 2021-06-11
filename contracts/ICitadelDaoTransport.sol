// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;


interface ICitadelDaoTransport {

    function balanceOf(address account) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);
    function lockedSupply() external view returns (uint256);

    function withdraw(address to, uint amount) external;

    function updateInflation(uint issueId, uint pct) external;
    function updateVesting(uint issueId, uint pct) external;

    function delegateToDAO(address from, uint amount) external;
    function redeemFromDAO(address to, uint amount) external;

}

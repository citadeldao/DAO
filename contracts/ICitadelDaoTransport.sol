// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;


interface ICitadelDaoTransport {

    function lockedBalanceOf(address account) external view returns (uint256);
    function lockedSupply() external view returns (uint256);

    function transferStakingRewards(address account, uint256 amount) external;

    function changeInflationRatio(uint stakingPct, uint vestingPct) external;

}

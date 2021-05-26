// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;


interface ICitadelVestingTransport {

    function deployed() external view returns (uint);

    function lockedBalanceOf(address account) external view returns (uint256);
    function lockedSupply() external view returns (uint256);

    function getVestingInfo() external view returns (
        address addr,
        uint pct,
        uint256 budget,
        uint256 budgeUsed
    );
    function yearInflationEmission(uint timestamp) external view returns (uint);

    function getMaxSupply() external view returns (uint);

    function getInflationStartDate() external view returns (uint);
    function getSavedInflationYear() external view returns (uint);

    function countInflationPoints() external view returns (uint);
    function inflationPoint(uint index) external view
    returns (
        uint inflationPct,
        uint stakingPct,
        uint currentSupply,
        uint yearlySupply,
        uint date
    );

    function totalSupplyHistoryCount() external view returns (uint);
    function totalSupplyHistory(uint index) external view
    returns (
        uint value,
        uint date
    );

    function lockHistoryCount(address addr) external view returns (uint);
    function lockHistory(address addr, uint index) external view
    returns (
        uint value,
        uint date
    );

}

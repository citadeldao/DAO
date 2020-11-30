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

}

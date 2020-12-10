// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;


interface ICitadelVesting {

    function updateInflationPct(uint value) external;
    function userFrozeCoins(address user) external;
    function userUnfrozeCoins(address user) external;

}

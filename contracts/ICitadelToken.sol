// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;


interface ICitadelToken {

    function deployed() external view returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./CitadelDao.sol";


contract CitadelDaoTest is CitadelDao {

    uint private _fakeTime;

    constructor (
        address addressOfToken
    )
    CitadelDao(
        addressOfToken
    )
    public {
        _fakeTime = block.timestamp;
    }

    function setTimestamp(uint date) external onlyOwner {
        _fakeTime = date;
    }

    function _timestamp() internal override view returns (uint) {
        return _fakeTime;
    }
}
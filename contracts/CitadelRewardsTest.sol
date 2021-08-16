// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./CitadelRewards2.sol";


contract CitadelRewardsTest is CitadelRewards2 {

    uint private _fakeTime;

    constructor (
        address addressOfToken
    )
    CitadelRewards2(
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
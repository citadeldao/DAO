// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./CitadelRewards.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";


contract CitadelRewardsTest is Ownable, CitadelRewards {

    uint private _fakeTime;

    constructor (
        address addressOfToken
    )
    CitadelRewards(
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
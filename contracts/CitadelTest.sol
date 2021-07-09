// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


import "./Citadel.sol";


contract CitadelTest is Citadel() {

    uint private _fakeTime;

    constructor ()
    public {
        _fakeTime = block.timestamp;
    }

    function setTimestamp(uint date) external onlyOwner {
        _fakeTime = date;
    }

    function _timestamp() internal override view returns (uint) {
        return _fakeTime;
    }

    function setInflation(uint pct) external onlyOwner {
        require(pct >= 200 && pct <= 3000, "Percentage must be between 2% and 30%");
        _makeInflationSnapshot();
        _updateInflation(pct);
    }

}

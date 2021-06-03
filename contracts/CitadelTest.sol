// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


import "./Token/CitadelDaoTransport.sol";


contract CitadelTest is CitadelDaoTransport {

    uint private _fakeTime;

    constructor (
        uint initialSupply
    )
    public {
        _fakeTime = block.timestamp;

        // mint inflation
        uint inflation = uint(500000000).mul(1e6);
        _mint(address(1), inflation);

        initialSupply = initialSupply.mul(1e6);
        
        _initInflation(inflation, inflation, 800, 40, 60);

        _initCitadelTokenLocker(address(2));

        _mint(address(this), uint(500000000).mul(1e6));

        assert(totalSupply() == initialSupply);

    }

    function delegateTokens (address to, uint amount) external onlyOwner {
        _transfer(address(this), to, amount);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


import "./CitadelTokenLocker.sol";


contract CitadelDaoTransport is CitadelTokenLocker {

    address private _daoAddress;

    modifier onlyDaoContract() {
        require(msg.sender == _daoAddress);
        _;
    }

    function initDaoTransport(address daoAddress_) external onlyOwner {
        _daoAddress = daoAddress_;
    }

    function getDaoAddress() external view returns (address) {
        return _daoAddress;
    }

    function transferStakingRewards(address account, uint256 amount) external onlyDaoContract {
        _transferStakingRewards(account, amount);
    }

    function changeInflationRatio(uint stakingPct, uint vestingPct) external onlyDaoContract {
        _changeInflationRatio(stakingPct, vestingPct);
    }

    function changeVestingRatio(uint value) external onlyDaoContract {
        _updatedVestingRatio(value);
    }

}

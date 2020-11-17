// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./CitadelCommunityFund.sol";


contract CitadelInflation is CitadelCommunityFund {

    bool private _isInitialized;
    uint256 private _budgetAmount;

    address private _addressStaking;
    uint private _stakingPct;
    uint256 private _stakingAmount;
    uint256 private _stakingUsed;

    address private _addressVesting;
    uint private _vestingPct;
    uint private _vestingAmount;
    uint256 private _vestingUsed;

    event CitadelInflationRatio(uint stakingPct, uint vestingPct);

    function getStakingInfo() external view returns (
        address addr,
        uint pct,
        uint256 budget,
        uint256 budgeUsed
    ) {
        addr = _addressStaking;
        pct = _stakingPct;
        budget = _stakingAmount;
        budgeUsed = _stakingUsed;
    }

    function getVestingInfo() external view returns (
        address addr,
        uint pct,
        uint256 budget,
        uint256 budgeUsed
    ) {
        addr = _addressVesting;
        pct = _vestingPct;
        budget = _vestingAmount;
        budgeUsed = _vestingUsed;
    }

    function _changeInflationRatio(uint stakingPct, uint vestingPct) internal {
        require((stakingPct + vestingPct) == 100, "CitadelInflation: incorrect percentages");
        uint256 stakingAmount = _budgetAmount.mul(stakingPct).div(100);
        uint256 vestingAmount = _budgetAmount.sub(stakingAmount);
        if (stakingPct < _stakingPct) {
            require(stakingAmount < _stakingUsed, "CitadelInflation: new staking budget less than already used");
            uint256 diff = _stakingAmount.sub(stakingAmount);
            if (diff > 0) _transfer(_addressStaking, _addressVesting, diff);
        } else {
            require(vestingAmount < _vestingUsed, "CitadelInflation: new vesting budget less than already used");
            uint256 diff = _vestingAmount.sub(vestingAmount);
            if (diff > 0) _transfer(_addressVesting, _addressStaking, diff);
        }
        _stakingPct = stakingPct;
        _stakingAmount = stakingAmount;
        _vestingPct = vestingPct;
        _vestingAmount = vestingAmount;
        emit CitadelInflationRatio(stakingPct, vestingPct);
        _updatedInflationRatio(stakingAmount, vestingAmount);
    }

    function _updatedInflationRatio(uint stakingAmount, uint vestingAmount) internal virtual { }

    function _transferStakingRewards(address account, uint256 amount) internal {
        _stakingUsed = _stakingUsed.add(amount);
        require(_stakingAmount >= _stakingUsed, "CitadelInflation: too big amount");
        _transfer(_addressStaking, account, amount);
    }

    function _transferVesting(address account, uint256 amount) internal {
        _vestingUsed = _vestingUsed.add(amount);
        require(_vestingAmount >= _vestingUsed, "CitadelInflation: too big amount");
        _transfer(_addressVesting, account, amount);
    }

    function _initInflation(
        uint256 totalAmount,
        address stakeAddr,
        uint stakingPct,
        address vestAddr,
        uint vestingPct
    ) internal {

        require(!_isInitialized);
        require((stakingPct + vestingPct) == 100, "CitadelInflation: incorrect percentages");

        _isInitialized = true;

        _budgetAmount = totalAmount;

        _addressStaking = stakeAddr;
        _stakingPct = stakingPct;
        _stakingAmount = totalAmount.mul(stakingPct).div(100);
        if(_stakingAmount > 0) _transfer(_bankAddress, _addressStaking, _stakingAmount);

        _addressVesting = vestAddr;
        _vestingPct = vestingPct;
        _vestingAmount = totalAmount.sub(_stakingAmount);
        if(_vestingAmount > 0) _transfer(_bankAddress, _addressVesting, _vestingAmount);

        emit CitadelInflationRatio(stakingPct, vestingPct);

    }

}

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

    function yearInflationEmission(uint timestamp) external view
    returns (uint) {
        uint lastYears = timestamp.sub(deployDate).mul(1e10).div(365 days);
        if (lastYears > 0 && lastYears % 1e10 == 0) lastYears = lastYears.sub(1e9);
        lastYears = lastYears.div(1e10);
        (uint yem,) = _inflationEmission(lastYears);
        return yem;
    }

    function inflationEmission(uint lastYears) external pure
    returns (uint year, uint emission) {
        (year, emission) = _inflationEmission(lastYears);
    }

    function _inflationEmission(uint lastYears) internal pure
    returns (uint year, uint emission) {
        if (lastYears > 22) return (0, 0);
        uint circulatingSupply = 100000000;
        uint emissionPool = 600000000;
        // for 22 years
        for(uint y = 0; y <= lastYears+1; y++){
            if(y > 0){
                year = _countEmission(emissionPool, circulatingSupply);
                emissionPool -= year;
                emission += year;
                circulatingSupply += year;
            }
            if(y == 1) circulatingSupply += 15000000 + 10000000;
            if(y == 2) circulatingSupply += 22500000 + 15000000;
            if(y == 3) circulatingSupply += 45000000 + 30000000;
            if(y == 4) circulatingSupply += 67500000 + 45000000;
            if(y < 5) circulatingSupply += 10000000;
        }
        year = year.mul(1e6);
        emission = emission.mul(1e6);
    }

    function _countEmission(uint emissionPool, uint circulatingSupply) private pure
    returns (uint){
        if(emissionPool < circulatingSupply * 2 / 100){
            return emissionPool;
        }else{
            // choose max amount
            uint a = emissionPool / 10;
            uint b = circulatingSupply * 2 / 100;
            return a > b ? a : b;
        }
    }

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
            require(stakingAmount >= _stakingUsed, "CitadelInflation: new staking budget less than already used");
            uint256 diff = _stakingAmount.sub(stakingAmount);
            if (diff > 0) _transfer(_addressStaking, _addressVesting, diff);
        } else {
            require(vestingAmount >= _vestingUsed, "CitadelInflation: new vesting budget less than already used");
            uint256 diff = _vestingAmount.sub(vestingAmount);
            if (diff > 0) _transfer(_addressVesting, _addressStaking, diff);
        }
        _stakingPct = stakingPct;
        _stakingAmount = stakingAmount;
        _vestingPct = vestingPct;
        _vestingAmount = vestingAmount;
        emit CitadelInflationRatio(stakingPct, vestingPct);
        _updatedInflationRatio(vestingPct);
    }

    function _updatedInflationRatio(uint vestingAmount) internal virtual { }

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

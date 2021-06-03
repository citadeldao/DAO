// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./CitadelToken.sol";

contract CitadelInflation is CitadelToken {

    uint internal startInflationDate;

    bool private _isInitialized;
    //uint private _otherSum;
    //uint private _budgetAmount;
    uint private _maxSupply;
    uint private _unlockedSupply;
    uint private _savedInflationYear;
    uint private _yearUnlockedBudget;

    struct InflationValues {
        uint inflationPct;
        uint stakingPct;
        uint currentSupply;
        uint yearlySupply;
        uint date;
    }

    InflationValues[] private _inflationHistory;

    event CitadelInflationRatio(uint inflationPct, uint stakingPct);

    modifier activeInflation(){
        require(startInflationDate > 0 && startInflationDate <= _timestamp(), "CitadelInflation: coming soon");
        _;
    }

    function startInflation() external onlyOwner {
        require (startInflationDate == 0, "Inflation is already started");
        startInflationDate = _timestamp();
        _savedInflationYear = startInflationDate;
        _inflationHistory[0].date = _savedInflationYear;
    }

    function startInflationTo(uint date) external onlyOwner {
        require (startInflationDate == 0 || startInflationDate > _timestamp(), "Inflation is already started");
        require (date > _timestamp(), "Starting date must be in the future");
        startInflationDate = date;
        _savedInflationYear = startInflationDate;
        _inflationHistory[0].date = _savedInflationYear;
    }

    function getInflationStartDate() external view
    returns (uint) {
        return startInflationDate;
    }

    function getSavedInflationYear() external view
    returns (uint) {
        return _savedInflationYear;
    }

    function getMaxSupply() external view
    returns (uint) {
        return _maxSupply;
    }

    /*function calc() external view
    returns (uint) {

    }*/

    /*function yearInflationEmission(uint timestamp) external view
    returns (uint) {
        (uint yem,) = _inflationEmission(_lifeYears(timestamp));
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
            // team unlock + private sale unlock
            if(y == 1) circulatingSupply += 15000000 + 15000000;
            if(y == 2) circulatingSupply += 37500000 + 20000000;
            if(y == 3) circulatingSupply += 45000000 + 30000000;
            if(y == 4) circulatingSupply += 52500000 + 35000000;
            // Foundation Fund unlock
            if(y < 5) circulatingSupply += 10000000;
        }
        year = year.mul(1e6);
        emission = emission.mul(1e6);
    }*/

    /*function _countEmission(uint emissionPool, uint circulatingSupply) private pure
    returns (uint){
        if(emissionPool < circulatingSupply * 2 / 100){
            return emissionPool;
        }else{
            // choose max amount
            uint a = emissionPool / 10;
            uint b = circulatingSupply * 2 / 100;
            return a > b ? a : b;
        }
    }*/

    /*function inflationPoint(uint index) external view
    returns (
        uint inflationPct,
        uint stakingPct,
        uint currentSupply,
        uint yearlySupply,
        uint date
    ) {
        require(index < _inflationHistory.length, "CitadelInflation: unexpected index");
        inflationPct = _inflationHistory[index].inflationPct;
        stakingPct = _inflationHistory[index].stakingPct;
        currentSupply = _inflationHistory[index].currentSupply;
        yearlySupply = _inflationHistory[index].yearlySupply;
        date = _inflationHistory[index].date;
    }*/

    function inflationPoint(uint index) external view
    returns (InflationValues memory) {
        require(index < _inflationHistory.length, "CitadelInflation: unexpected index");
        return _inflationHistory[index];
    }

    function countInflationPoints() external view
    returns (uint) {
        return _inflationHistory.length;
    }

    function _changeInflationRatio(uint stakingPct, uint vestingPct) internal {
        require((stakingPct + vestingPct) == 100, "CitadelInflation: incorrect percentages");

        //uint256 stakingAmount = _budgetAmount.mul(stakingPct).div(100);
        //uint256 vestingAmount = _budgetAmount.sub(stakingAmount);
        /*if (stakingPct < _stakingPct) {
            require(stakingAmount >= _stakingUsed, "CitadelInflation: new staking budget less than already used");
            uint256 diff = _stakingAmount.sub(stakingAmount);
            if (diff > 0) _transfer(_addressStaking, _addressVesting, diff);
        } else {
            require(vestingAmount >= _vestingUsed, "CitadelInflation: new vesting budget less than already used");
            uint256 diff = _vestingAmount.sub(vestingAmount);
            if (diff > 0) _transfer(_addressVesting, _addressStaking, diff);
        }*/
        //_stakingPct = stakingPct;
        //_stakingAmount = stakingAmount;
        //_vestingPct = vestingPct;
        //_vestingAmount = vestingAmount;

        InflationValues memory last = _inflationHistory[_inflationHistory.length - 1];

        emit CitadelInflationRatio(last.inflationPct, stakingPct);
        _inflationHistory.push(InflationValues(last.inflationPct, stakingPct, _unlockedSupply, _yearUnlockedBudget, _timestamp()));
        _updatedInflationRatio(vestingPct);
    }

    // add checking address of contract
    function withdraw(address to, uint amount) external {
        _makeInflationSnapshot();
        _transfer(address(1), to, amount);
    }

    // add checking address of contract
    function updateInflation(uint pct) external {
        require(pct >= 200 && pct <= 3000, "Percentage must be between 2% and 30%");
        
        InflationValues memory lastPoint = _inflationHistory[_inflationHistory.length - 1];
        uint spentTime = _timestamp() - lastPoint.date;
        require(spentTime >= 30 days, "You have to wait 30 days after last changing");

        _makeInflationSnapshot();
        _updateInflation(pct);
    }

    function _updateInflation(uint pct) internal {
        require(_maxSupply != _unlockedSupply);

        InflationValues memory lastPoint = _inflationHistory[_inflationHistory.length - 1];
        uint spentTime = _timestamp() - lastPoint.date;

        _unlockedSupply += _yearUnlockedBudget * lastPoint.inflationPct * spentTime / 365 days / 10000;

        require(pct <= _restInflPct(), "Too high percentage");

        _inflationHistory.push(InflationValues(pct, lastPoint.stakingPct, _unlockedSupply, _yearUnlockedBudget, _timestamp()));
    }

    function _makeInflationSnapshot() internal {
        if (_maxSupply == _unlockedSupply) return;

        uint spentTime = _timestamp() - _savedInflationYear;
        if (spentTime < 365 days) return;

        InflationValues memory lastPoint = _inflationHistory[_inflationHistory.length - 1];

        uint infl = lastPoint.inflationPct;
        for (uint y = 0; y < spentTime / 365 days; y++) {
            _savedInflationYear += 365 days;
            uint updateUnlock = _yearUnlockedBudget * infl * (_savedInflationYear - lastPoint.date) / 365 days / 10000;
            if (updateUnlock + _unlockedSupply >= _maxSupply || infl < 200) {
                //infl = _restInflPct();
                _unlockedSupply = _maxSupply;
                _inflationHistory.push(InflationValues(_restInflPct(), lastPoint.stakingPct, _unlockedSupply, _unlockedSupply, _savedInflationYear));
                break;
            } else {
                _unlockedSupply += updateUnlock;
                if (infl > 200) {
                    if (infl > 50 && infl - 50 > 200) infl -= 50; // -0.5% each year
                    if (infl < 200) infl = 200; // 2% is minimum
                } else if (infl == 200) {
                    uint rest = _restInflPct();
                    if (rest < 200) infl = rest;
                }
                _inflationHistory.push(InflationValues(infl, lastPoint.stakingPct, _unlockedSupply, _unlockedSupply, _savedInflationYear));
            }

        }
        _yearUnlockedBudget = _unlockedSupply;
    }

    function _restInflPct() private view returns (uint) {
        return (_maxSupply - _unlockedSupply) * 10000 / _unlockedSupply;
    }

    function _updatedInflationRatio(uint vestingAmount) internal virtual { }

    function _initInflation(
        uint otherSum,
        uint totalAmount,
        uint inflationPct,
        uint stakingPct,
        uint vestingPct // has to be removed
    ) internal {

        require(!_isInitialized);
        require((stakingPct + vestingPct) == 100, "CitadelInflation: incorrect percentages");

        _isInitialized = true;

        //_otherSum = otherSum;
        //_budgetAmount = totalAmount;

        _maxSupply = otherSum + totalAmount;
        _unlockedSupply = otherSum;
        _yearUnlockedBudget = otherSum;

        emit CitadelInflationRatio(inflationPct, stakingPct);
        _inflationHistory.push(InflationValues(inflationPct, stakingPct, _unlockedSupply, _yearUnlockedBudget, _timestamp()));

    }

}

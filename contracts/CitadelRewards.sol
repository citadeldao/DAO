// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ICitadelVestingTransport.sol";


contract CitadelVesting is Ownable {

    ICitadelVestingTransport private _Token;
    uint private _tokenDeployed;
    bool private _isTest;
    uint private _testTimestamp;
    uint private _maxInflationSupply;

    struct Option {
        uint value;
        uint date;
    }

    struct InflationValues {
        uint inflationPct;
        uint stakingPct;
        uint date;
    }

    Option[] private _inflationsPct; // inflation %
    Option[] private _totalSupplyHistory;

    struct UserSnapshot {
        uint indexInflation;
        //uint inflationPct;
        //uint stakingPct;
        uint indexSupplyHistory;
        uint frozen;
        uint vested;
        uint claimed;
        uint dateUpdate;
    }

    mapping (address => UserSnapshot) private _userSnapshots;

    byte private constant NEXT_NOTHING = 0x00;
    byte private constant NEXT_INFLATION = 0x10;
    byte private constant NEXT_SUPPLY = 0x20;

    modifier onlyToken() {
        require(msg.sender == address(_Token));
        _;
    }

    constructor (
        address addressOfToken,
        bool isTest_
    ) public {
        _Token = ICitadelVestingTransport(addressOfToken);
        _tokenDeployed = _Token.deployed();
        _maxInflationSupply = _Token.getMaxSupply();
        ( , uint inflationPct, , ) = _Token.getVestingInfo();
        _inflationsPct.push(Option(inflationPct, block.timestamp));
        _totalSupplyHistory.push(Option(0, block.timestamp));
        _isTest = isTest_;
    }

    function setTestTimestamp(uint timestamp) external {
        require(_isTest);
        _testTimestamp = timestamp;
    }

    function getYearVesting() external view returns (uint) {
        return _yearVestingBudget(_timestamp());
    }

    function _yearVestingBudget(uint timestamp) internal view returns (uint) {
        uint yearEmission = _Token.yearInflationEmission(timestamp);
        return yearEmission * _inflationsPct[_inflationsPct.length-1].value / 100;
    }

    function _yearVestingBudget(uint timestamp, uint pct) internal view returns (uint) {
        uint yearEmission = _Token.yearInflationEmission(timestamp);
        return yearEmission * pct / 100;
    }

    function updateInflationPct(uint value) external onlyToken {
        _inflationsPct.push(Option(value, _timestamp()));
    }

    function userFrozeCoins(address userAddress) external onlyToken {
        uint totalSupply = _Token.lockedSupply();
        _totalSupplyHistory.push(Option(totalSupply, _timestamp()));
        _writeUserSnapshot(userAddress);
    }

    function userUnfrozeCoins(address userAddress) external onlyToken {
        uint totalSupply = _Token.lockedSupply();
        _totalSupplyHistory.push(Option(totalSupply, _timestamp()));
        _writeUserSnapshot(userAddress);
    }

    function getVestingPct() external view returns (uint) {
        return _inflationsPct[_inflationsPct.length-1].value;
    }

    function availableVestOf(address userAddress) external view returns (uint) {
        if (_userSnapshots[userAddress].dateUpdate == 0) return 0;
        UserSnapshot memory snapshot = _makeUserSnapshot(userAddress);
        return snapshot.vested - snapshot.claimed;
    }

    function _writeUserSnapshot(address userAddress) private {
        _userSnapshots[userAddress] = _makeUserSnapshot(userAddress);
    }

    function _makeUserSnapshot(address userAddress) private view returns (UserSnapshot memory snapshot) {
        uint frozenCurrent = _Token.lockedBalanceOf(userAddress);
        snapshot = _cloneUserSnapshot(_userSnapshots[userAddress]);
        if (snapshot.frozen > 0) {
            // if we have already staked

            // date when we started staking
            //uint startedInflationDate = _Token.getInflationStartDate();
            //require(startedInflationDate < block.timestamp);

            // last yearly checkoint
            uint savedInflationYear = _Token.getSavedInflationYear();
            require(savedInflationYear < block.timestamp);

            uint lastIndexInflation = _Token.countInflationPoints() - 1;
            uint lastIndexSupplyHistory = _Token.totalSupplyHistoryCount() - 1;

            (
                uint inflationPct,
                uint stakingPct,
                uint currentSupply,
                uint yearlySupply,
                uint inflDate
            ) = _Token.inflationPoint(snapshot.indexInflation);

            (uint totalStakedSupply,) = _Token.totalSupplyHistory(snapshot.indexSupplyHistory);

            if (snapshot.indexInflation == lastIndexInflation && currentSupply == _maxInflationSupply) return snapshot;

            uint startGas = gasleft();
            do {
                // check next options
                InflationValues memory nextInflation;
                Option memory nextSupply;
                uint nextCurrentSupply;
                uint nextYearlySupply;
                if (snapshot.indexInflation < lastIndexInflation) {
                    (
                        nextInflation.inflationPct,
                        nextInflation.stakingPct,
                        nextCurrentSupply,
                        nextYearlySupply,
                        nextInflation.date
                    ) = _Token.inflationPoint(snapshot.indexInflation + 1);
                }
                if (snapshot.indexSupplyHistory < lastIndexSupplyHistory) {
                    (nextSupply.value, nextSupply.date) = _Token.totalSupplyHistory(snapshot.indexSupplyHistory + 1);
                }
                (byte nextStep, uint time) = _findNextStep(nextInflation, nextSupply);
                if (nextStep == NEXT_NOTHING) time = _timestamp();
                // check new year
                //uint happyNewYear = savedInflationYear + ((snapshot.dateUpdate - savedInflationYear) / 365 days + 1) * 365 days;
                // save vesting inflation
                //uint vestInflPct = _inflationsPct[snapshot.indexInflation].value;
                // save user percent
                //uint userPct = (snapshot.frozen * 1e15 / _totalSupplyHistory[snapshot.indexSupplyHistory].value);
                // calculate
                if (nextStep != NEXT_INFLATION && time - savedInflationYear >= 365 days) {
                    savedInflationYear += 365 days;
                    time = savedInflationYear;
                    uint updateUnlock = yearlySupply * inflationPct * (savedInflationYear - inflDate) / 365 days / 10000;
                    inflDate = time;
                    if (currentSupply + updateUnlock >= _maxInflationSupply) {
                        // rest part = (_maxInflationSupply - currentSupply) * 10000 / _maxInflationSupply; // pct
                        // rest part of tokens = _maxInflationSupply - currentSupply;
                        currentSupply = _maxInflationSupply;
                        //yearlySupply = _maxInflationSupply;
                    } else {
                        if (inflationPct != 200) {
                            if (inflationPct > 50 && inflationPct - 50 > 200) inflationPct -= 50; // -0.5% each year
                            if (inflationPct < 200) inflationPct = 200; // 2% is minimum
                        }
                    }
                }
                //if (happyNewYear < time) {
                //    time = happyNewYear;
                //} else if (nextStep == NEXT_INFLATION) {
                //} else if (nextStep == NEXT_SUPPLY) {
                //}
                
                // перемножение
                // 1) yearlySupply * inflationPct // vested
                // 2) stakingPct
                // 3) snapshot.frozen
                // 4) time - snapshot.dateUpdate

                // деление
                // 1) 10000
                // 2) 100
                // 3) totalStakedSupply
                // 4) 365 days

                if (currentSupply == _maxInflationSupply) {
                    
                    uint upd = (currentSupply - yearlySupply) * stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                    upd = upd / totalStakedSupply / 365 days / 10000 / 100;

                    snapshot.vested += upd;
                    snapshot.dateUpdate = time;
                    break;

                }

                uint upd = yearlySupply * inflationPct * stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                upd = upd / totalStakedSupply / 365 days / 10000 / 100;

                snapshot.vested += upd;
                snapshot.dateUpdate = time;

                if (nextStep == NEXT_INFLATION) {

                    inflationPct = nextInflation.inflationPct;
                    stakingPct = nextInflation.stakingPct;
                    currentSupply = nextCurrentSupply;
                    yearlySupply = nextYearlySupply;
                    inflDate = time;
                    snapshot.indexInflation++;

                } else if (nextStep == NEXT_SUPPLY) {

                    totalStakedSupply = nextSupply.value;
                    snapshot.indexSupplyHistory++;

                }

                // check gas limit
                uint gasUsed = startGas - gasleft();
                if (gasUsed > 200000 || block.gaslimit - 10000 < gasUsed) break;
            } while (
                snapshot.indexInflation < lastIndexInflation ||
                snapshot.indexSupplyHistory < lastIndexSupplyHistory ||
                snapshot.dateUpdate < _timestamp()
            );
        } else {
            // first staking, just fixing indexes
            snapshot.indexInflation = _Token.countInflationPoints() - 1;
            snapshot.indexSupplyHistory = _Token.totalSupplyHistoryCount() - 1;
            snapshot.dateUpdate = _timestamp();
        }
        // final update
        snapshot.frozen = frozenCurrent;
    }

    function _findNextStep(
        InflationValues memory nextInflation,
        Option memory nextSupply
    ) private pure returns (byte lastByte, uint minDate) {

        uint dateInf = nextInflation.date;
        uint dateSup = nextSupply.date;

        lastByte = NEXT_NOTHING;

        if (dateInf > 0) {
            minDate = dateInf;
            lastByte = NEXT_INFLATION;
        }
        if (dateSup > 0 && (dateSup < minDate || minDate == 0)) {
            minDate = dateSup;
            lastByte = NEXT_SUPPLY;
        }

    }

    function _cloneUserSnapshot(UserSnapshot memory snapshot) private pure returns (UserSnapshot memory) {
        return UserSnapshot(
            snapshot.indexInflation,
            snapshot.indexSupplyHistory,
            snapshot.frozen,
            snapshot.vested,
            snapshot.claimed,
            snapshot.dateUpdate
        );
    }

    function _timestamp() private view returns (uint) {
        if (_isTest && _testTimestamp > 0) {
            return _testTimestamp;
        } else {
            return block.timestamp;
        }
    }

    function version() external pure returns (string memory) {
        return '0.1.0';
    }

}

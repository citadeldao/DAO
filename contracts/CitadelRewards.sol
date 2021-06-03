// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ICitadelVestingTransport.sol";


contract CitadelRewards is Ownable {

    ICitadelVestingTransport private _Token;
    uint private _tokenDeployed;
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

    struct InflationPointValues {
        uint inflationPct;
        uint stakingPct;
        uint currentSupply;
        uint yearlySupply;
        uint date;
    }

    //Option[] private _inflationsPct; // inflation %
    //Option[] private _totalSupplyHistory;

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
        address addressOfToken
    ) public {
        _Token = ICitadelVestingTransport(addressOfToken);
        _tokenDeployed = _Token.deployed();
        _maxInflationSupply = _Token.getMaxSupply();
        /*( , uint inflationPct, , ) = _Token.getVestingInfo();
        _inflationsPct.push(Option(inflationPct, block.timestamp));
        _totalSupplyHistory.push(Option(0, block.timestamp));*/
    }

    /*function getYearVesting() external view returns (uint) {
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
    }*/

    function updateSnapshot(address account) external onlyToken {
        _writeUserSnapshot(account);
    }

    function claimFor(address account) external onlyToken returns (uint amount) {
        _writeUserSnapshot(account);
        amount = _userSnapshots[account].vested - _userSnapshots[account].claimed;
        require(amount > 0, "Zero amount to claim");
        _userSnapshots[account].claimed = _userSnapshots[account].vested;
    }

    function claim() external returns (uint amount) {
        address account = msg.sender;
        _writeUserSnapshot(account);
        amount = _userSnapshots[account].vested - _userSnapshots[account].claimed;
        require(amount > 0, "Zero amount to claim");
        _userSnapshots[account].claimed = _userSnapshots[account].vested;
        _Token.withdraw(account, amount);
    }

    function claimable(address account) external view returns (uint) {
        if (_userSnapshots[account].dateUpdate == 0) return 0;
        UserSnapshot memory snapshot = _makeUserSnapshot(account);
        return snapshot.vested - snapshot.claimed;
    }

    function _writeUserSnapshot(address account) private {
        _userSnapshots[account] = _makeUserSnapshot(account);
    }

    function _makeUserSnapshot(address account) private view returns (UserSnapshot memory snapshot) {
        uint frozenCurrent = _Token.lockedBalanceOf(account);
        snapshot = _cloneUserSnapshot(_userSnapshots[account]);

        if (snapshot.frozen == 0) {
            // first staking, just fixing indexes
            snapshot.indexInflation = _Token.countInflationPoints() - 1;
            snapshot.indexSupplyHistory = _Token.totalSupplyHistoryCount() - 1;
            snapshot.dateUpdate = _timestamp();
            snapshot.frozen = frozenCurrent;
            return snapshot;
        }

        // if we have already staked

        // date when we started staking
        //uint startedInflationDate = _Token.getInflationStartDate();
        //require(startedInflationDate < block.timestamp);

        // last yearly checkoint
        uint savedInflationYear = _Token.getSavedInflationYear();
        //////require(savedInflationYear < _timestamp());

        uint lastIndexInflation = _Token.countInflationPoints() - 1;
        uint lastIndexSupplyHistory = _Token.totalSupplyHistoryCount() - 1;

        /*(
            uint inflationPct,
            uint stakingPct,
            uint currentSupply,
            uint yearlySupply,
            uint inflDate
        ) = _Token.inflationPoint(snapshot.indexInflation);*/
        ICitadelVestingTransport.InflationPointValues memory inflPoint = _Token.inflationPoint(snapshot.indexInflation);

        (uint totalStakedSupply,) = _Token.totalSupplyHistory(snapshot.indexSupplyHistory);

        if (snapshot.indexInflation == lastIndexInflation && inflPoint.currentSupply == _maxInflationSupply) return snapshot;

        //uint startGas = gasleft();
        do {
            // check next options
            ICitadelVestingTransport.InflationPointValues memory nextInflation;
            Option memory nextSupply;
            //uint nextCurrentSupply;
            //uint nextYearlySupply;
            if (snapshot.indexInflation < lastIndexInflation) {
                /*!!!(
                    nextInflation.inflationPct,
                    nextInflation.stakingPct,
                    nextCurrentSupply,
                    nextYearlySupply,
                    nextInflation.date
                ) = _Token.inflationPoint(snapshot.indexInflation + 1);*/
                //if (snapshot.indexInflation == 15) revert("TEST");
                nextInflation = _Token.inflationPoint(snapshot.indexInflation + 1);
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
            if (nextStep != NEXT_INFLATION && time > savedInflationYear && time - savedInflationYear >= 365 days) {
                nextStep = NEXT_INFLATION;
                savedInflationYear += 365 days;
                time = savedInflationYear;
                uint updateUnlock = inflPoint.yearlySupply * inflPoint.inflationPct * (savedInflationYear - inflPoint.date) / 365 days / 10000;
                inflPoint.date = savedInflationYear;
                if (inflPoint.currentSupply + updateUnlock >= _maxInflationSupply) {
                    // rest part = (_maxInflationSupply - currentSupply) * 10000 / _maxInflationSupply; // pct
                    // rest part of tokens = _maxInflationSupply - currentSupply;
                    inflPoint.currentSupply = _maxInflationSupply;
                    //yearlySupply = _maxInflationSupply;
                } else {
                    /*inflPoint.yearlySupply += inflPoint.yearlySupply * inflPoint.inflationPct / 10000;
                    if (inflPoint.inflationPct != 200) {
                        if (inflPoint.inflationPct > 50 && inflPoint.inflationPct - 50 > 200) inflPoint.inflationPct -= 50; // -0.5% each year
                        if (inflPoint.inflationPct < 200) inflPoint.inflationPct = 200; // 2% is minimum
                    }*/
                    nextInflation.currentSupply = inflPoint.currentSupply;
                    nextInflation.stakingPct = inflPoint.stakingPct;
                    nextInflation.yearlySupply = inflPoint.yearlySupply + inflPoint.yearlySupply * inflPoint.inflationPct / 10000;
                    if (inflPoint.inflationPct != 200) {
                        if (inflPoint.inflationPct > 50 && inflPoint.inflationPct - 50 > 200) nextInflation.inflationPct = inflPoint.inflationPct - 50; // -0.5% each year
                        if (inflPoint.inflationPct < 200) nextInflation.inflationPct = 200; // 2% is minimum
                    } else {
                        nextInflation.inflationPct = inflPoint.inflationPct;
                    }
                }
            }
            
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

            if (inflPoint.currentSupply == _maxInflationSupply) {
                
                uint upd = (inflPoint.currentSupply - inflPoint.yearlySupply) * inflPoint.stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                upd = upd / totalStakedSupply / 365 days / 100;

                //revert(uint2str(upd));

                snapshot.vested += upd;

                //revert(uint2str(snapshot.vested));

                snapshot.dateUpdate = time;
                break;

            }

            uint upd;
            if (inflPoint.inflationPct < 200) {
                upd = (_maxInflationSupply - inflPoint.yearlySupply) * inflPoint.stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                upd = upd / totalStakedSupply / 365 days / 100;
            } else {
                upd = inflPoint.yearlySupply * inflPoint.inflationPct * inflPoint.stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                upd = upd / totalStakedSupply / 365 days / 10000 / 100;
            }
            
            snapshot.vested += upd;
            snapshot.dateUpdate = time;

            if (nextStep == NEXT_INFLATION) {
                //if (snapshot.indexInflation == 15) revert(uint2str(upd));

                inflPoint.inflationPct = nextInflation.inflationPct;
                inflPoint.stakingPct = nextInflation.stakingPct;
                inflPoint.currentSupply = nextInflation.currentSupply;
                inflPoint.yearlySupply = nextInflation.yearlySupply;
                inflPoint.date = time;
                snapshot.indexInflation++;

            } else if (nextStep == NEXT_SUPPLY) {

                totalStakedSupply = nextSupply.value;
                snapshot.indexSupplyHistory++;

            }

            // check gas limit
            //uint gasUsed = startGas - gasleft();
            if (block.gaslimit - 30000 < gasleft()) break;
        } while (
            snapshot.indexInflation < lastIndexInflation ||
            snapshot.indexSupplyHistory < lastIndexSupplyHistory ||
            snapshot.dateUpdate < _timestamp()
        );
        // final update
        snapshot.frozen = frozenCurrent;
    }

    function _findNextStep(
        ICitadelVestingTransport.InflationPointValues memory nextInflation,
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

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
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

    function _timestamp() internal virtual view returns (uint) {
        return block.timestamp;
    }

    function version() external pure returns (string memory) {
        return '0.1.0';
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ICitadelVestingTransport.sol";


contract CitadelRewards is Ownable {

    ICitadelVestingTransport private _Token;
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

    struct UserSnapshot {
        uint indexInflation;
        uint indexSupplyHistory;
        uint frozen;
        uint vested;
        uint claimed;
        uint dateUpdate;
    }

    mapping (address => UserSnapshot) private _userSnapshots;
    mapping (address => mapping (uint => Option)) private _userStaked;

    byte private constant NEXT_NOTHING = 0x00;
    byte private constant NEXT_INFLATION = 0x10;
    byte private constant NEXT_SUPPLY = 0x20;

    event Claim(address recipient, uint amount);

    modifier onlyToken() {
        require(msg.sender == address(_Token));
        _;
    }

    constructor (
        address addressOfToken
    ) public {
        _Token = ICitadelVestingTransport(addressOfToken);
        _maxInflationSupply = _Token.getMaxSupply();
    }

    function claimable(address account) external view returns (uint) {
        if (_userSnapshots[account].dateUpdate == 0) return 0;
        UserSnapshot memory snapshot = _makeUserSnapshot(account);
        return snapshot.vested - snapshot.claimed;
    }

    function totalVestedOf(address account) external view returns (uint) {
        if (_userSnapshots[account].dateUpdate == 0) return 0;
        UserSnapshot memory snapshot = _makeUserSnapshot(account);
        return snapshot.vested;
    }

    function totalClaimedOf(address account) external view returns (uint) {
        return _userSnapshots[account].claimed;
    }

    function updateSnapshot(address account) external onlyToken {
        uint fixedTimestamp = _timestamp();
        uint frozenCurrent = _Token.lockedBalanceOf(account);
        uint lastIndexSupplyHistory = _Token.totalSupplyHistoryCount() - 1;
        _userStaked[account][lastIndexSupplyHistory] = Option({
            value: frozenCurrent,
            date: fixedTimestamp
        });
        // first staking, just fixing indexes
        if (_userSnapshots[account].frozen == 0) {
            UserSnapshot storage snapshot = _userSnapshots[account];
            snapshot.indexInflation = _Token.countInflationPoints() - 1;
            snapshot.indexSupplyHistory = lastIndexSupplyHistory;
            snapshot.dateUpdate = fixedTimestamp;
            snapshot.frozen = frozenCurrent;
        }
    }

    function claimFor(address account) external onlyToken returns (uint amount) {
        _writeUserSnapshot(account);
        amount = _userSnapshots[account].vested - _userSnapshots[account].claimed;
        require(amount > 0, "Zero amount to claim");
        _userSnapshots[account].claimed = _userSnapshots[account].vested;
        emit Claim(account, amount);
    }

    function claim() external returns (uint amount) {
        address account = msg.sender;
        _writeUserSnapshot(account);
        amount = _userSnapshots[account].vested - _userSnapshots[account].claimed;
        require(amount > 0, "Zero amount to claim");
        _userSnapshots[account].claimed = _userSnapshots[account].vested;
        emit Claim(account, amount);
        _Token.withdraw(account, amount);
    }

    function _timestamp() internal virtual view returns (uint) {
        return block.timestamp;
    }

    function _writeUserSnapshot(address account) private {
        _userSnapshots[account] = _makeUserSnapshot(account);
    }

    function _makeUserSnapshot(address account) private view returns (UserSnapshot memory snapshot) {
        snapshot = _userSnapshots[account];

        if (snapshot.frozen == 0) return snapshot;

        // last yearly checkoint
        uint savedInflationYear = _Token.getSavedInflationYear();

        uint lastIndexInflation = _Token.countInflationPoints() - 1;
        uint lastIndexSupplyHistory = _Token.totalSupplyHistoryCount() - 1;

        ICitadelVestingTransport.InflationPointValues memory inflPoint = _Token.inflationPoint(snapshot.indexInflation);

        (uint totalStakedSupply,) = _Token.totalSupplyHistory(snapshot.indexSupplyHistory);

        if (snapshot.indexInflation == lastIndexInflation && inflPoint.currentSupply == _maxInflationSupply) return snapshot;

        uint fixedTimestamp = _timestamp();

        do {
            // check gas limit
            if (gasleft() < 50000) break;

            // check next options
            ICitadelVestingTransport.InflationPointValues memory nextInflation;
            Option memory nextSupply;
            if (snapshot.indexInflation < lastIndexInflation) {
                nextInflation = _Token.inflationPoint(snapshot.indexInflation + 1);
            }
            if (snapshot.indexSupplyHistory < lastIndexSupplyHistory) {
                (nextSupply.value, nextSupply.date) = _Token.totalSupplyHistory(snapshot.indexSupplyHistory + 1);
            }
            (byte nextStep, uint time) = _findNextStep(nextInflation, nextSupply);
            if (nextStep == NEXT_NOTHING) time = fixedTimestamp;
            
            // calculate

            if (nextStep != NEXT_INFLATION && time > savedInflationYear && time - savedInflationYear >= 365 days) {
                nextStep = NEXT_INFLATION;
                savedInflationYear += 365 days;
                time = savedInflationYear;
                uint updateUnlock = inflPoint.yearlySupply * inflPoint.inflationPct * (savedInflationYear - inflPoint.date) / 365 days / 10000;
                inflPoint.date = savedInflationYear;
                if (inflPoint.currentSupply + updateUnlock >= _maxInflationSupply) {

                    inflPoint.currentSupply = _maxInflationSupply;

                } else {

                    nextInflation.currentSupply = inflPoint.currentSupply;
                    nextInflation.stakingPct = inflPoint.stakingPct;
                    nextInflation.yearlySupply = inflPoint.yearlySupply + inflPoint.yearlySupply * inflPoint.inflationPct / 10000;
                    if (inflPoint.inflationPct > 200) {
                        nextInflation.inflationPct = inflPoint.inflationPct - 50; // -0.5% each year
                        if (nextInflation.inflationPct < 200) nextInflation.inflationPct = 200; // 2% is minimum
                    } else {
                        nextInflation.inflationPct = inflPoint.inflationPct;
                    }

                }
            }
            
            // Multiplying
            // 1) yearlySupply * inflationPct // vested
            // 2) stakingPct
            // 3) snapshot.frozen
            // 4) time - snapshot.dateUpdate

            // Dividing
            // 1) 10000
            // 2) 100
            // 3) totalStakedSupply
            // 4) 365 days

            uint upd;

            if (totalStakedSupply > 0) {
                if (inflPoint.currentSupply == _maxInflationSupply) {
                    
                    upd = (inflPoint.currentSupply - inflPoint.yearlySupply) * inflPoint.stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                    upd = upd / totalStakedSupply / 365 days / 100;
                    snapshot.vested += upd;
                    snapshot.dateUpdate = time;
                    break;

                } else if (inflPoint.inflationPct < 200) {

                    upd = (_maxInflationSupply - inflPoint.yearlySupply) * inflPoint.stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                    upd = upd / totalStakedSupply / 365 days / 100;

                } else {

                    upd = inflPoint.yearlySupply * inflPoint.inflationPct * inflPoint.stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                    upd = upd / totalStakedSupply / 365 days / 10000 / 100;

                }
            }
            
            snapshot.vested += upd;
            snapshot.dateUpdate = time;

            if (nextStep == NEXT_INFLATION) {

                inflPoint.inflationPct = nextInflation.inflationPct;
                inflPoint.stakingPct = nextInflation.stakingPct;
                inflPoint.currentSupply = nextInflation.currentSupply;
                inflPoint.yearlySupply = nextInflation.yearlySupply;
                inflPoint.date = time;
                snapshot.indexInflation++;

            } else if (nextStep == NEXT_SUPPLY) {

                totalStakedSupply = nextSupply.value;
                snapshot.indexSupplyHistory++;

                Option memory updateStake = _userStaked[account][snapshot.indexSupplyHistory];
                if (updateStake.date > 0) {
                    snapshot.frozen = updateStake.value;
                }

            }
        } while (
            snapshot.indexInflation < lastIndexInflation ||
            snapshot.indexSupplyHistory < lastIndexSupplyHistory ||
            snapshot.dateUpdate < fixedTimestamp
        );
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

    function version() external pure returns (string memory) {
        return '1.0.0';
    }

}

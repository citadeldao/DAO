// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ICitadelVestingTransport.sol";


contract CitadelVesting is Ownable {

    ICitadelVestingTransport private _Token;
    bool private _isTest;
    uint private _testTimestamp;

    struct Option {
        uint value;
        uint date;
    }

    Option[] private _inflationsPct; // inflation %
    Option[] private _totalSupplyHistory;

    struct UserSnapshot {
        uint indexInflation;
        uint indexSupplyHistory;
        uint frozen;
        uint vested;
        uint claimed;
        uint dateUpdate;
    }

    mapping (address => UserSnapshot) private _userSnapshots;

    byte private constant NEXT_NOTHING = 0x00;
    byte private constant NEXT_INFLATION = 0x10;
    byte private constant NEXT_SUPPLY = 0x30;

    modifier onlyToken() {
        require(msg.sender == address(_Token));
        _;
    }

    constructor (
        address addressOfToken,
        bool isTest_
    ) public {
        _Token = ICitadelVestingTransport(addressOfToken);
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
            uint lastIndexInflation = _inflationsPct.length - 1;
            uint lastIndexSupplyHistory = _totalSupplyHistory.length - 1;
            uint startGas = gasleft();
            uint updatedDate;
            do {
                // check next options
                Option memory nextInflation;
                Option memory nextSupply;
                if (snapshot.indexInflation < lastIndexInflation) {
                    nextInflation = _inflationsPct[snapshot.indexInflation + 1];
                }
                if (snapshot.indexSupplyHistory < lastIndexSupplyHistory) {
                    nextSupply = _totalSupplyHistory[snapshot.indexSupplyHistory + 1];
                }
                (byte nextStep, uint time) = _findNextStep(nextInflation, nextSupply);
                // save vesting inflation
                uint vestInflPct = _inflationsPct[snapshot.indexInflation].value;
                // save user percent
                uint userPct = (snapshot.frozen * 1e8 / _totalSupplyHistory[snapshot.indexSupplyHistory].value);
                // calculate
                if (nextStep == NEXT_NOTHING) {
                    time = _timestamp();
                } else if (nextStep == NEXT_INFLATION) {
                    snapshot.indexInflation++;
                } else if (nextStep == NEXT_SUPPLY) {
                    snapshot.indexSupplyHistory++;
                }
                uint vestInfl = _yearVestingBudget(time) * vestInflPct / 100;
                updatedDate = time;
                uint period = time - snapshot.dateUpdate; // seconds
                snapshot.vested += vestInfl * userPct * period / 365 days / 1e8;
                // check gas limit
                uint gasUsed = startGas - gasleft();
                if (gasUsed > 200000 || block.gaslimit - 10000 < gasUsed) break;
            } while (
                snapshot.indexInflation < lastIndexInflation ||
                snapshot.indexSupplyHistory < lastIndexSupplyHistory ||
                updatedDate < _timestamp()
            );
        } else {
            // first staking, just fixing indexes
            snapshot.indexInflation = _inflationsPct.length - 1;
            snapshot.indexSupplyHistory = _totalSupplyHistory.length - 1;
        }
        // final update
        snapshot.frozen = frozenCurrent;
        snapshot.dateUpdate = _timestamp();
    }

    function _findNextStep(
        Option memory nextInflation,
        Option memory nextSupply
    ) private pure returns (byte lastByte, uint minDate) {

        uint dateInf = nextInflation.date;
        uint dateSup = nextSupply.date;

        lastByte = NEXT_NOTHING;

        if (dateInf > 0) {
            minDate = dateInf;
            lastByte = NEXT_INFLATION;
        }
        if (dateSup > 0 && dateSup < minDate) {
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

}

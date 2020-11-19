// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ICitadelVestingTransport.sol";


contract CitadelVesting is Ownable {

    ICitadelVestingTransport private _Token;

    struct Option {
        uint value;
        uint date;
    }

    Option[] private _inflations; // inflation per day
    Option[] private _vestingRatios;
    Option[] private _totalSupplyHistory;

    struct UserSnapshot {
        uint indexInflation;
        uint indexVestRatio;
        uint indexSupplyHistory;
        uint frozen;
        uint vested;
        uint claimed;
        uint dateUpdate;
    }

    mapping (address => UserSnapshot) private _userSnapshots;

    byte private constant NEXT_NOTHING = 0x00;
    byte private constant NEXT_INFLATION = 0x10;
    byte private constant NEXT_VESTING = 0x20;
    byte private constant NEXT_SUPPLY = 0x30;

    modifier onlyToken() {
        require(msg.sender == address(_Token));
        _;
    }

    constructor (
        address addressOfToken,
        uint vestingRatio
    ) public {
        _Token = ICitadelVestingTransport(addressOfToken);
        ( , , uint inflation, ) = _Token.getVestingInfo();
        _inflations.push(Option(inflation, block.timestamp));
        _vestingRatios.push(Option(vestingRatio, block.timestamp));
        _totalSupplyHistory.push(Option(0, block.timestamp));
    }

    function updateInflation(uint value) external onlyToken {
        _inflations.push(Option(value, block.timestamp));
    }

    function updateVestingRatio(uint value) external onlyToken {
        _vestingRatios.push(Option(value, block.timestamp));
    }

    function userFrozeCoins(address userAddress) external onlyToken {
        uint totalSupply = _Token.lockedSupply();
        _totalSupplyHistory.push(Option(totalSupply, block.timestamp));
        _writeUserSnapshot(userAddress);
    }

    function userUnfrozeCoins(address userAddress) external onlyToken {
        uint totalSupply = _Token.lockedSupply();
        _totalSupplyHistory.push(Option(totalSupply, block.timestamp));
        _writeUserSnapshot(userAddress);
    }

    function getVestingRatio() external view returns (uint) {
        return _vestingRatios[_vestingRatios.length - 1].value;
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
            uint lastIndexInflation = _inflations.length - 1;
            uint lastIndexVestRatio = _vestingRatios.length - 1;
            uint lastIndexSupplyHistory = _totalSupplyHistory.length - 1;
            uint startGas = gasleft();
            uint updatedDate;
            do {
                // check next options
                Option memory nextInflation;
                Option memory nextVestingRatio;
                Option memory nextSupply;
                if (snapshot.indexInflation < lastIndexInflation) {
                    nextInflation = _inflations[snapshot.indexInflation + 1];
                }
                if (snapshot.indexVestRatio < lastIndexVestRatio) {
                    nextVestingRatio = _vestingRatios[snapshot.indexVestRatio + 1];
                }
                if (snapshot.indexSupplyHistory < lastIndexSupplyHistory) {
                    nextSupply = _totalSupplyHistory[snapshot.indexSupplyHistory + 1];
                }
                (byte nextStep, uint time) = _findNextStep(nextInflation, nextVestingRatio, nextSupply);
                // save vesting inflation
                // where "curVestingRatio.value" was multiplied by 1e8
                uint vestInfl = _inflations[snapshot.indexInflation].value * _vestingRatios[snapshot.indexVestRatio].value / 1e8;
                // save user percent
                uint userPct = (snapshot.frozen * 1e8 / _totalSupplyHistory[snapshot.indexSupplyHistory].value);
                // calculate
                if (nextStep == NEXT_NOTHING) {
                    time = block.timestamp;
                } else if (nextStep == NEXT_INFLATION) {
                    snapshot.indexInflation++;
                } else if (nextStep == NEXT_VESTING) {
                    snapshot.indexVestRatio++;
                } else if (nextStep == NEXT_SUPPLY) {
                    snapshot.indexSupplyHistory++;
                }
                updatedDate = time;
                uint period = time - snapshot.dateUpdate; // seconds
                snapshot.vested += vestInfl * userPct * period / 365 days / 1e8;
                // check gas limit
                uint gasUsed = startGas - gasleft();
                if (gasUsed > 200000 || block.gaslimit - 10000 < gasUsed) break;
            } while (
                snapshot.indexInflation < lastIndexInflation ||
                snapshot.indexVestRatio < lastIndexVestRatio ||
                snapshot.indexSupplyHistory < lastIndexSupplyHistory ||
                updatedDate < block.timestamp
            );
        } else {
            // first staking, just fixing indexes
            snapshot.indexInflation = _inflations.length - 1;
            snapshot.indexVestRatio = _vestingRatios.length - 1;
            snapshot.indexSupplyHistory = _totalSupplyHistory.length - 1;
        }
        // final update
        snapshot.frozen = frozenCurrent;
        snapshot.dateUpdate = block.timestamp;
    }

    function _findNextStep(
        Option memory nextInflation,
        Option memory nextVestingRatio,
        Option memory nextSupply
    ) private pure returns (byte lastByte, uint minDate) {

        uint dateInf = nextInflation.date;
        uint dateVes = nextVestingRatio.date;
        uint dateSup = nextSupply.date;

        lastByte = NEXT_NOTHING;

        if (dateInf > 0) {
            minDate = dateInf;
            lastByte = NEXT_INFLATION;
        }
        if (dateVes > 0 && dateVes < minDate) {
            minDate = dateVes;
            lastByte = NEXT_VESTING;
        }
        if (dateSup > 0 && dateSup < minDate) {
            minDate = dateSup;
            lastByte = NEXT_SUPPLY;
        }

    }

    function _cloneUserSnapshot(UserSnapshot memory snapshot) private pure returns (UserSnapshot memory) {
        return UserSnapshot(
            snapshot.indexInflation,
            snapshot.indexVestRatio,
            snapshot.indexSupplyHistory,
            snapshot.frozen,
            snapshot.vested,
            snapshot.claimed,
            snapshot.dateUpdate
        );
    }

}

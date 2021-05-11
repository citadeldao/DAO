// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ICitadelToken.sol";

contract CitadelUnlockTeam is Ownable {

    struct Amount {
        uint total;
        uint used;
    }

    uint constant PCTDEC = 1000000;
    Amount public total;
    mapping (address => Amount) public list;
    ICitadelToken public token;
    uint public test_date;

    constructor (
        address _tokenAddress,
        address[] memory accounts,
        uint[] memory amounts,
        uint _test_date
    ) public {
        require(accounts.length > 0, "Empty list of addresses");
        require(accounts.length == amounts.length, "Incorrect number of amounts");
        
        for (uint i; i < accounts.length; i++) {
            list[accounts[i]] = Amount(amounts[i], 0);
            total.total += amounts[i];
        }

        token = ICitadelToken(_tokenAddress);
        test_date = _test_date;

    }

    function getTokenAddress () external view returns (address) {
        return address(token);
    }

    function calcUnlockOfTest (address _address, uint _testdate) external view returns (uint) {
        uint deployed = token.deployed();
        return _calcUnlockAmount(_address, int(_testdate) - int(deployed));
    }

    function calcUnlockOf (address _address) external view returns (uint) {
        uint deployed = token.deployed();
        return _calcUnlockAmount(_address, int(test_date > 0 ? test_date : block.timestamp) - int(deployed));
    }

    function claim () external returns (bool) {
        uint deployed = token.deployed();
        uint amount = _calcUnlockAmount(msg.sender, int(test_date > 0 ? test_date : block.timestamp) - int(deployed));
        return token.transfer(msg.sender, amount);
    }

    function _calcUnlockAmount (address _address, int period) public view returns (uint) {

        if (period == 0) return 0;
        Amount memory store = _address == address(0) ? total : list[_address];

        int yr = int(365 days);

        uint sum = 0;

        sum += _getPart(_getPercent(store.total, 10 * PCTDEC / 100), yr - period);

        if (period - yr > 0) {
            sum += _getPart(_getPercent(store.total, 25 * PCTDEC / 100), yr * 2 - period);
        }

        if (period - yr * 2 > 0) {
            sum += _getPart(_getPercent(store.total, 30 * PCTDEC / 100), yr * 3 - period);
        }

        if (period - yr * 3 > 0) {
            sum += _getPart(_getPercent(store.total, 35 * PCTDEC / 100), yr * 4 - period);
        }

        return sum - store.used;
    }

    function _getPart(uint amount, int time) private pure returns (uint) {
        if (time > 0) {
            return _getPercent(amount, (365 days - uint(time)) * PCTDEC / 365 days);
        } else {
            return amount;
        }
    }

    function _getPercent(uint amount, uint pct) private pure returns (uint) {
        return amount * pct / PCTDEC;
    }

}
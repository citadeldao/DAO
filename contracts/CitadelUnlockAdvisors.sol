// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ICitadelToken.sol";

contract CitadelUnlockAdvisors is Ownable {

    struct Amount {
        uint total;
        uint used;
    }

    uint constant PCTDEC = 1000000;
    Amount public total;
    mapping (address => Amount) public list;
    ICitadelToken public token;
    uint public token_deployed;
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
        token_deployed = token.deployed();
        test_date = _test_date;
    }

    function getTokenAddress () external view returns (address) {
        return address(token);
    }

    function calcUnlockOfTest (address _address, uint _testdate) external view returns (uint) {
        return _calcUnlockAmount(_address, int(_testdate) - int(token_deployed));
    }

    function calcUnlockOf (address _address) external view returns (uint) {
        return _calcUnlockAmount(_address, int(test_date > 0 ? test_date : block.timestamp) - int(token_deployed));
    }

    function claim () external returns (bool) {
        if (list[msg.sender].total == 0 || list[msg.sender].total == list[msg.sender].used) return false;
        uint amount = _calcUnlockAmount(msg.sender, int(test_date > 0 ? test_date : block.timestamp) - int(token_deployed));
        list[msg.sender].used += amount;
        total.used += amount;
        return token.transfer(msg.sender, amount);
    }

    function _calcUnlockAmount (address _address, int period) public view returns (uint) {
        if (period <= 0) return 0;
        Amount memory store = _address == address(0) ? total : list[_address];

        int yr = int(365 days);

        uint sum = 0;

        sum += _getPart(_getPercent(store.total, 25 * PCTDEC / 100), yr - period);

        if (period - yr > 0) {
            sum += _getPart(_getPercent(store.total, 25 * PCTDEC / 100), yr * 2 - period);
        }

        if (period - yr * 2 > 0) {
            sum += _getPart(_getPercent(store.total, 25 * PCTDEC / 100), yr * 3 - period);
        }

        if (period - yr * 3 > 0) {
            sum += _getPart(_getPercent(store.total, 25 * PCTDEC / 100), yr * 4 - period);
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
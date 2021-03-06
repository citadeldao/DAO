// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./MultisigSingle.sol";
import "./ICitadelToken.sol";

contract CitadelUnlockCommFund is MultisigSingle, Ownable {

    uint constant PCTDEC = 1e10;
    uint public total;
    uint public used;
    ICitadelToken public token;
    uint public token_deployed;
    uint public test_date;

    event TransferVote (uint indexed id, address from, address to, uint amount);

    constructor (
        uint budget,
        address _tokenAddress,
        address[] memory multisig,
        uint threshold,
        uint _test_date
    ) public {
        require(budget > 0, "Budget can't be zero");
        total = budget;
        token = ICitadelToken(_tokenAddress);
        token_deployed = token.deployed();
        _initMultisigWhitelist(multisig, threshold);
        test_date = _test_date;
    }

    function getBudget () external view 
    returns (uint totalAmount, uint usedAmount, uint pending) {
        totalAmount = total;
        usedAmount = used;
        pending = _calcUnlockAmount(int(test_date > 0 ? test_date : block.timestamp) - int(token_deployed));
    }

    function getTokenAddress () external view returns (address) {
        return address(token);
    }

    function calcUnlockTest (uint _testdate) external view returns (uint) {
        return _calcUnlockAmount(int(_testdate) - int(token_deployed));
    }

    function calcUnlock () external view returns (uint) {
        return _calcUnlockAmount(int(test_date > 0 ? test_date : block.timestamp) - int(token_deployed));
    }

    function transfer (address to, uint amount) external multisig() returns (bool) {
        (bool isReady, uint id) = _isMultisigReady();
        emit TransferVote(id, msg.sender, to, amount);
        if (!isReady) return false;
        require(total > used, "Budget is spent");
        require(amount > 0, "Amount must be rather than 0");
        uint available = _calcUnlockAmount(int(test_date > 0 ? test_date : block.timestamp) - int(token_deployed));
        require(amount <= available, "Don't have enough unlocked tokens");
        used += amount;
        return token.transfer(to, amount);
    }

    function _calcUnlockAmount (int period) public view returns (uint) {
        if (period <= 0) return 0;

        int yr = int(365 days);

        uint sum = 0;

        sum += _getPart(_getPercent(total, 25 * PCTDEC / 100), yr - period);

        if (period - yr > 0) {
            sum += _getPart(_getPercent(total, 25 * PCTDEC / 100), yr * 2 - period);
        }

        if (period - yr * 2 > 0) {
            sum += _getPart(_getPercent(total, 25 * PCTDEC / 100), yr * 3 - period);
        }

        if (period - yr * 3 > 0) {
            sum += _getPart(_getPercent(total, 25 * PCTDEC / 100), yr * 4 - period);
        }

        return sum - used;
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
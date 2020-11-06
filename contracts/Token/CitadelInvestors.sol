// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./CitadelExchange.sol";


contract CitadelInvestors is CitadelExchange {
    using SafeMath for uint256;

    struct Investor {
        uint256 limit;
        uint256 used;
        uint percent;
    }

    event InvestorAdded(address account, uint shares);

    bool private _isInitialized;
    uint public startContract;
    uint public unbondingPeriod;
    uint public unbondingPeriodFrequency;
    uint256 private _totalAmount;
    uint256 private _usedAmount;
    address[] private _addresses;
    mapping (address => Investor) public investors;

    function _initCitadelInvestors (
        uint initialUnbondingPeriod,
        uint initialUnbondingPeriodFrequency
    )
    internal {
        require(!_isInitialized);
        _isInitialized = true;
        startContract = block.timestamp;
        unbondingPeriod = initialUnbondingPeriod;
        unbondingPeriodFrequency = initialUnbondingPeriodFrequency;
    }

    function claimInvestor (uint256 amount) external {
        address account = msg.sender;
        require(investors[account].limit > 0, "CitadelInvestors: for investors only");

        (
            ,
            ,
            ,
            ,
            ,
            uint256 available
        ) = _getInvestorInfoOf(account);

        require(amount <= available, "CitadelInvestors: too big amount");

        uint256 used = investors[account].used.add(amount);
        require(used <= investors[account].limit);

        investors[account].used = used;
        _usedAmount = _usedAmount.add(amount);
        _transfer(_bankAddress, account, amount);
    }

    function getInvestorPercent () public view returns (uint256) {
        require(investors[msg.sender].limit > 0, "CitadelInvestors: for investors only");
        return investors[msg.sender].percent;
    }

    function getInvestorLimit () public view returns (uint256) {
        require(investors[msg.sender].limit > 0, "CitadelInvestors: for investors only");
        return investors[msg.sender].limit;
    }

    function getInvestorUsed () public view returns (uint256) {
        require(investors[msg.sender].limit > 0, "CitadelInvestors: for investors only");
        return investors[msg.sender].used;
    }

    function getInvestorInfo () public view
    returns (
        uint hasTime,
        uint steps,
        uint256 limit,
        uint256 stepPrice,
        uint currentSteps,
        uint256 available
    ) {
        (
            hasTime,
            steps,
            limit,
            stepPrice,
            currentSteps,
            available
        ) = _getInvestorInfoOf(msg.sender);
    }

    function getAvailableInvestorSumOf (address account) public view
    returns (uint256) {

        require(investors[msg.sender].limit > 0, "CitadelInvestors: for investors only");

        (
            ,
            ,
            ,
            ,
            ,
            uint256 available
        ) = _getInvestorInfoOf(account);

        return available;

    }

    function _getInvestorInfoOf (address account) internal view
    returns (
        uint hasTime,
        uint steps,
        uint256 limit,
        uint256 stepPrice,
        uint currentSteps,
        uint256 available
    ) {
        require(
            block.timestamp != startContract,
            "CitadelInvestors: block timestamp must be different from start time"
        );
        require(investors[account].limit > 0, "CitadelInvestors: for investors only");

        hasTime = block.timestamp - startContract;
        steps = unbondingPeriod / unbondingPeriodFrequency;
        limit = investors[account].limit;
        stepPrice = investors[account].limit.div(steps);
        currentSteps = hasTime / unbondingPeriodFrequency;
        if (currentSteps > steps) currentSteps = steps;
        available = stepPrice.mul(currentSteps).sub(investors[account].used);

        if (currentSteps == steps) {
            uint256 finalCheck = investors[account].used.add(available);
            if (finalCheck < investors[account].limit) {
                available = investors[account].limit.sub(investors[account].used);
            }
        }
    }

    function _addInvestors (
        uint256 totalAmount,
        address[] memory addresses,
        uint[] memory shares
    ) internal returns (bool) {

        require(totalAmount > 0, "CitadelInvestors: no totalAmount");
        require(addresses.length == shares.length, "CitadelInvestors: addresses and shares length mismatch");
        require(addresses.length > 0, "CitadelInvestors: no addresses");

        _totalAmount = totalAmount;

        uint totalShares = 0;
        uint256 bank = 0;

        for (uint i = 0; i < addresses.length; i++) {
            require(shares[i] > 0, "CitadelInvestors: investor share must be rather than 0");
            require(addresses[i] != address(0), "CitadelInvestors: investor address cannot be zero");

            _addresses.push(addresses[i]);
            uint256 investorAmount = totalAmount.mul(shares[i]).div(100);
            investors[addresses[i]] = Investor(investorAmount, 0, shares[i]);
            emit InvestorAdded(addresses[i], shares[i]);
            totalShares += shares[i];
            bank += investorAmount;
        }

        require(totalShares == 100, "CitadelInvestors: shares sum have to be equal 100 percentages");

        if (bank > totalAmount) {
            uint256 diff = bank.sub(totalAmount);
            investors[addresses[addresses.length - 1]].limit -= diff;
        } else if (bank < totalAmount) {
            uint256 diff = totalAmount.sub(bank);
            investors[addresses[addresses.length - 1]].limit += diff;
        }

        return true;

    }

}

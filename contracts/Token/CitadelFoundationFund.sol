// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./CitadelInvestors.sol";


contract CitadelFoundationFund is CitadelInvestors {

    bool private _isInitialized;
    address private _addressFF;
    uint256 private _budget;
    uint256 private _budgetClaimed;
    uint256 private _budgetUsed;
    uint private _stepsTotal;
    uint256 private _stepPrice;
    uint private _stepPeriod;

    function getFFInfo() external view multisig(bytes4("FF")) returns (
        address addr,
        uint startDate,
        uint256 budget,
        uint256 badgeUsed,
        uint256 badgeClaimed,
        uint steps,
        uint256 available
    ) {
        addr = _addressFF;
        startDate = deployDate;
        budget = _budget;
        badgeUsed = _budgetUsed;
        badgeClaimed = _budgetClaimed;
        steps = countSteps();
        if (steps == _stepsTotal) {
            available = _budget.sub(_budgetClaimed);
        } else {
            available = _stepPrice.mul(steps).sub(_budgetClaimed);
        }
    }

    function claimFF() external multisig(bytes4("FF")) {
        uint256 available;
        uint steps = countSteps();
        if (steps == _stepsTotal) {
            available = _budget.sub(_budgetClaimed);
        } else {
            available = _stepPrice.mul(steps).sub(_budgetClaimed);
        }
        if (available > 0) {
            _transfer(_bankAddress, _addressFF, available);
            _budgetClaimed = _budgetClaimed.add(available);
        }
    }

    function transferFF(address account, uint256 amount) external multisig(bytes4("FF")) {
        if (!_isMultisigReady(bytes4("FF"))) return;
        if (amount > 0) {
            _transfer(_addressFF, account, amount);
            _budgetUsed = _budgetUsed.add(amount);
        }
    }

    function _initFFBudget(address addr, uint256 budget) internal {

        require(!_isInitialized);
        require(addr != address(0), "CitadelFoundationFund: incorrect address");
        require(budget > 0, "CitadelFoundationFund: empty budget");

        _isInitialized = true;
        _addressFF = addr;
        _budget = budget;
        _stepsTotal = 4;
        _stepPrice = budget.div(_stepsTotal);
        _stepPeriod = 365 days;

    }

    function countSteps() private view returns (uint) {
        uint diff = block.timestamp - deployDate;
        uint steps = diff / _stepPeriod;
        if (steps >= _stepsTotal) {
            return _stepsTotal;
        } else {
            return steps + 1;
        }
    }

}

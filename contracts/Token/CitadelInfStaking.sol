// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./CitadelCommunityFund.sol";


contract CitadelInfStaking is CitadelCommunityFund {

    bool private _isInitialized;
    address private _addressStaking;
    uint256 private _budget;
    uint256 private _budgetUsed;

    function getStakingInfo() external view returns (
        address addr,
        uint256 budget,
        uint256 badgeUsed
    ) {
        addr = _addressStaking;
        budget = _budget;
        badgeUsed = _budgetUsed;
    }

    function _transferStakingRewards(address account, uint256 amount) internal {
        _transfer(_addressStaking, account, amount);
        _budgetUsed = _budgetUsed.add(amount);
    }

    function _initStakingBudget(address addr, uint256 budget) internal {

        require(!_isInitialized);
        require(addr != address(0), "CitadelInfStaking: incorrect address");
        require(budget > 0, "CitadelInfStaking: empty budget");

        _isInitialized = true;
        _addressStaking = addr;
        _budget = budget;
        _transfer(_bankAddress, _addressStaking, _budget);

    }

}

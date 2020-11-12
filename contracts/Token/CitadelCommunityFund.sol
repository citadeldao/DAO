// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./CitadelFoundationFund.sol";


contract CitadelCommunityFund is CitadelFoundationFund {

    bool private _isInitialized;
    address private _addressCF;
    uint256 private _budget;
    uint256 private _budgetUsed;

    function getCFInfo() external view returns (
        address addr,
        uint256 budget,
        uint256 badgeUsed
    ) {
        addr = _addressCF;
        budget = _budget;
        badgeUsed = _budgetUsed;
    }

    function transferCF(address account, uint256 amount) external multisig(bytes4("CF")) {
        if (!_isMultisigReady(bytes4("CF"))) return;
        if (amount > 0) {
            _transfer(_addressCF, account, amount);
            _budgetUsed = _budgetUsed.add(amount);
        }
    }

    function _initCFBudget(address addr, uint256 budget) internal {

        require(!_isInitialized);
        require(addr != address(0), "CitadelCommunityFund: incorrect address");
        require(budget > 0, "CitadelCommunityFund: empty budget");

        _isInitialized = true;
        _addressCF = addr;
        _budget = budget;
        _transfer(_bankAddress, _addressCF, _budget);

    }

}

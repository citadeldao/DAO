// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


import "./Token/CitadelDaoTransport.sol";


contract Citadel is CitadelDaoTransport {

    struct MultisigData {
        bytes4 id;
        address[] whitelist;
        uint threshold;
    }

    constructor (
        MultisigData[] memory multisigs,
        uint256 initialSupply,
        uint256 _rate,
        uint256 _buyerLimit,
        uint initialUnbondingPeriod,
        uint initialUnbondingPeriodFrequency,
        address[] memory _investors,
        uint[] memory _shares
    )
    public {
        for (uint i = 0; i < multisigs.length; i++) {
            MultisigData memory ms = multisigs[i];
            _initMultisigWhitelist(ms.id, ms.whitelist, ms.threshold);
        }

        initialSupply = initialSupply.mul(1e6);

        _initCitadelInvestors(initialUnbondingPeriod, initialUnbondingPeriodFrequency);
        _initCitadelExchange(_rate, _buyerLimit);

        _mint(_bankAddress, initialSupply);

        uint256 publicSaleLimit = initialSupply;
        uint256 value = 0;

        value = initialSupply.mul(25).div(100);
        publicSaleLimit = publicSaleLimit.sub(value);
        _addInvestors(value, _investors, _shares);

        value = initialSupply.mul(5).div(100);
        publicSaleLimit = publicSaleLimit.sub(value);
        _initFFBudget(address(1), value);

        value = initialSupply.mul(5).div(100);
        publicSaleLimit = publicSaleLimit.sub(value);
        _initCFBudget(address(2), value);

        uint256 vestingBudget = initialSupply.mul(60).div(100);
        publicSaleLimit = publicSaleLimit.sub(vestingBudget);
        _initInflation(vestingBudget, address(3), 60, address(4), 40);

        _initCitadelTokenLocker(address(5));

        _publicSaleLimit = publicSaleLimit;
    }

}

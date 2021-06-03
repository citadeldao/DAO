// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


import "./Token/CitadelDaoTransport.sol";


contract Citadel is CitadelDaoTransport {

    /*struct MultisigData {
        bytes4 id;
        address[] whitelist;
        uint threshold;
    }*/

    constructor (
        //MultisigData[] memory multisigs,
        uint initialSupply
    )
    public {
        /*for (uint i = 0; i < multisigs.length; i++) {
            MultisigData memory ms = multisigs[i];
            _initMultisigWhitelist(ms.id, ms.whitelist, ms.threshold);
        }*/

        // mint inflation
        uint inflation = uint(500000000).mul(1e6);
        _mint(address(1), inflation);

        initialSupply = initialSupply.mul(1e6);
        
        //_mint(_bankAddress, initialSupply.mul(10).div(100));

        //uint256 publicSaleLimit = initialSupply;
        //uint256 value = 0;

        //uint256 vestingBudget = initialSupply.mul(60).div(100);
        //publicSaleLimit = publicSaleLimit.sub(vestingBudget);
        _initInflation(inflation, inflation, 800, 40, 60);
        //_mint(address(3), vestingBudget.mul(60).div(100));
        //_mint(address(4), vestingBudget.mul(40).div(100));

        _initCitadelTokenLocker(address(2));

        //value = initialSupply.mul(15).div(100);
        //publicSaleLimit = publicSaleLimit.sub(value);
        //_initTeam(address(6), value, _teamUnlockPct);
        //_mint(address(6), value);

        //value = initialSupply.mul(10).div(100);
        //publicSaleLimit = publicSaleLimit.sub(value);
        //_initInvestors(address(7), value, _investorsUnlockPct);
        //_mint(address(7), value);

    /*
        // mint team
        _mint(address(this), uint(147250000).mul(1e6));

        // mint advisors
        _mint(address(this), uint(2750000).mul(1e6));

        // mint private sale 1
        _mint(address(this), uint(2500000).mul(1e6));

        // mint private sale 2
        _mint(address(this), uint(48333333).mul(1e6));

        // mint private eco fund
        _mint(address(this), uint(196666667).mul(1e6));

        // mint private found fund
        _mint(address(this), uint(40000000).mul(1e6));

        // mint private community fund
        _mint(address(this), uint(50000000).mul(1e6));

        // mint public & market sale
        _mint(address(this), uint(12500000).mul(1e6));
    */

        _mint(address(this), uint(500000000).mul(1e6));

        assert(totalSupply() == initialSupply);

    }

    function delegateTokens (address to, uint amount) external onlyOwner {
        _transfer(address(this), to, amount);
    }

}

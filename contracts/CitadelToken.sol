// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/utils/Pausable.sol";
import "./Multisig.sol";


contract CitadelToken is ERC20("Citadel", "XCT"), Ownable, Pausable, Multisig {

    address public _bankAddress;

    constructor () public {

        _bankAddress = address(this);

    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

}

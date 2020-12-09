// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "../../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/utils/Pausable.sol";
import "../Multisig.sol";


contract CitadelToken is ERC20("Citadel", "XCT"), Ownable, Pausable, Multisig {

    address public _bankAddress;
    uint public deployDate;
    uint public percentDecimal;

    constructor () public {

        _bankAddress = address(this);
        deployDate = block.timestamp;
        percentDecimal = 1e15;

        _setupDecimals(6);

    }

    function deployed() external view returns (uint) {
        return deployDate;
    }

    function _lifeYears(uint time) internal view returns (uint) {
        uint lastYears = time.sub(deployDate).mul(1e10).div(365 days);
        if (lastYears > 0 && lastYears % 1e10 == 0) lastYears = lastYears.sub(1e9);
        lastYears = lastYears.div(1e10);
        return lastYears;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(uint(msg.sender) > 0, "CitadelToken: fake sender");
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

}

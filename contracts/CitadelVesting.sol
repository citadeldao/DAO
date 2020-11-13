// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ICitadelVestingTransport.sol";


contract CitadelVesting is Ownable {

    ICitadelVestingTransport private _Token;

    struct Option {
        uint value;
        uint date;
    }

    Option[] private _inflations; // inflation per day
    Option[] private _vestingRatios;
    Option[] private _totalSupplyHistory;

    struct UserSnapshot {
        uint indexInflation;
        uint indexVestRatio;
        uint indexSupplyHistory;
        uint frozen;
        uint vested;
        uint claimed;
        uint dateUpdate;
    }

    mapping (address => UserSnapshot) private _userSnapshots;

    modifier onlyToken() {
        require(msg.sender == address(_Token));
        _;
    }

    constructor (
        address addressOfToken,
        uint inflation,
        uint vestingRatio
    ) public {
        _Token = ICitadelVestingTransport(addressOfToken);
        _inflations.push(Option(inflation, block.timestamp));
        _vestingRatios.push(Option(vestingRatio, block.timestamp));
        _totalSupplyHistory.push(Option(0, block.timestamp));
    }

    function updateInflation(uint value) external onlyToken {
        _inflations.push(Option(value, block.timestamp));
    }

    function updateVestingRatio(uint value) external onlyToken {
        _vestingRatios.push(Option(value, block.timestamp));
    }

    function userFrozeCoins(address user) external onlyToken {
        uint totalSupply = _Token.lockedSupply();
        _totalSupplyHistory.push(Option(totalSupply, block.timestamp));
        _makeUserSnapshot(user);
    }

    function _makeUserSnapshot(address userAddress) private {
        uint frozenCurrent = _Token.lockedBalanceOf(userAddress);
        // to do something

        // final update
        _userSnapshots[userAddress].frozen = frozenCurrent;
        _userSnapshots[userAddress].dateUpdate = block.timestamp;
    }

}

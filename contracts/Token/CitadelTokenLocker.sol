// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./CitadelInflation.sol";
import "../ICitadelVesting.sol";

contract CitadelTokenLocker is CitadelInflation {

    struct HistoryItem {
        uint value;
        uint date;
    }

    ICitadelVesting private _Vesting;
    mapping (address => uint256) public lockedCoins;
    bool private _isInitialized;
    address private _lockerAddress;

    HistoryItem[] private _totalLockedSupplyHistory;
    mapping (address => HistoryItem[]) private _lockedCoinsHistory;

    function totalSupplyHistoryCount() external view
    returns (uint) {
        return _totalLockedSupplyHistory.length;
    }

    function totalSupplyHistory(uint index) external view
    returns (
        uint value,
        uint date
    ) {
        require (index < _totalLockedSupplyHistory.length, "CitadelTokenLocker: unexpected index");
        value = _totalLockedSupplyHistory[index].value;
        date = _totalLockedSupplyHistory[index].date;
    }

    function lockHistoryCount(address addr) external view
    returns (uint) {
        return _lockedCoinsHistory[addr].length;
    }

    function lockHistory(address addr, uint index) external view
    returns (
        uint value,
        uint date
    ) {
        require (index < _lockedCoinsHistory[addr].length, "CitadelTokenLocker: unexpected index");
        value = _lockedCoinsHistory[addr][index].value;
        date = _lockedCoinsHistory[addr][index].date;
    }

    function stake(uint amount) external activeInflation {
        
        _makeInflationSnapshot();

        _transfer(msg.sender, _lockerAddress, amount);
        lockedCoins[msg.sender] = lockedCoins[msg.sender].add(amount);
        // put mark in history
        _totalLockedSupplyHistory.push(HistoryItem(_lockedTotalSupply(), _timestamp()));
        _lockedCoinsHistory[msg.sender].push(HistoryItem(lockedCoins[msg.sender], _timestamp()));
        // ...
        _Vesting.updateSnapshot(msg.sender);

    }

    function unstake(uint amount) external activeInflation {

        require(lockedCoins[msg.sender] >= amount);

        _makeInflationSnapshot();

        _transfer(_lockerAddress, msg.sender, amount); // remove
        lockedCoins[msg.sender] = lockedCoins[msg.sender].sub(amount);
        // put mark in history
        _totalLockedSupplyHistory.push(HistoryItem(_lockedTotalSupply(), _timestamp()));
        _lockedCoinsHistory[msg.sender].push(HistoryItem(lockedCoins[msg.sender], _timestamp()));
        // ...
        _Vesting.updateSnapshot(msg.sender);

    }

    function restake() external activeInflation {
        
        uint amount = _Vesting.claimFor(msg.sender);

        require(amount > 0);

        _makeInflationSnapshot();
        _transfer(address(1), _lockerAddress, amount);
        
        lockedCoins[msg.sender] = lockedCoins[msg.sender].add(amount);
        // put mark in history
        _totalLockedSupplyHistory.push(HistoryItem(_lockedTotalSupply(), _timestamp()));
        _lockedCoinsHistory[msg.sender].push(HistoryItem(lockedCoins[msg.sender], _timestamp()));
        // ...
        _Vesting.updateSnapshot(msg.sender);

    }

    function lockedBalanceOf(address account) external view returns (uint) {

        return lockedCoins[account];

    }

    function lockedSupply() external view returns (uint) {

        return _lockedTotalSupply();

    }

    function _lockedTotalSupply() private view returns (uint256) {

        return balanceOf(_lockerAddress);

    }

    function initVestingTransport(address vestAddress) external onlyOwner {
        _Vesting = ICitadelVesting(vestAddress);
    }

    function getVestingAddress() external view returns (address) {
        return address(_Vesting);
    }

    function _updatedInflationRatio(uint vestingPct) internal override {
        _Vesting.updateInflationPct(vestingPct);
    }

    function _initCitadelTokenLocker(address lockerAddress_) internal {

        require(!_isInitialized);

        _isInitialized = true;
        _lockerAddress = lockerAddress_;

    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./CitadelInflation.sol";
import "../ICitadelVesting.sol";

contract CitadelTokenLocker is CitadelInflation {

    ICitadelVesting private _Vesting;
    mapping (address => uint256) public lockedCoins;
    bool private _isInitialized;
    address private _lockerAddress;

    function lockCoins(uint256 amount) external {

        _transfer(msg.sender, _lockerAddress, amount);
        lockedCoins[msg.sender] = lockedCoins[msg.sender].add(amount);
        _Vesting.userFrozeCoins(msg.sender);

    }

    function unlockCoins(uint256 amount) external {

        _transfer(_lockerAddress, msg.sender, amount);
        lockedCoins[msg.sender] = lockedCoins[msg.sender].sub(amount);
        _Vesting.userUnfrozeCoins(msg.sender);

    }

    function lockedBalanceOf(address account) external view returns (uint256) {

        return lockedCoins[account];

    }

    function lockedSupply() external view returns (uint256) {

        return balanceOf(_lockerAddress);

    }

    function initVestingTransport(address vestAddress) external onlyOwner {
        _Vesting = ICitadelVesting(vestAddress);
    }

    function getVestingAddress() external view returns (address) {
        return address(_Vesting);
    }

    function _updatedInflationRatio(uint stakingAmount, uint vestingAmount) internal override {
        _Vesting.updateInflation(vestingAmount);
    }

    function _initCitadelTokenLocker(address lockerAddress_) internal {

        require(!_isInitialized);

        _isInitialized = true;
        _lockerAddress = lockerAddress_;

    }

}

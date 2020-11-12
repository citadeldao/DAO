// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./CitadelInfStaking.sol";

contract CitadelTokenLocker is CitadelInfStaking {

    mapping (address => uint256) public lockedCoins;
    bool private _isInitialized;
    address private _lockerAddress;

    function lockCoins(uint256 amount) external {

        _transfer(msg.sender, _lockerAddress, amount);
        lockedCoins[msg.sender] = lockedCoins[msg.sender].add(amount);

    }

    function unlockCoins(uint256 amount) external {

        _transfer(_lockerAddress, msg.sender, amount);
        lockedCoins[msg.sender] = lockedCoins[msg.sender].sub(amount);

    }

    function lockedBalanceOf(address account) external view returns (uint256) {

        return lockedCoins[account];

    }

    function lockedSupply() external view returns (uint256) {

        return balanceOf(_lockerAddress);

    }

    function _initCitadelTokenLocker(address lockerAddress_) internal {

        require(!_isInitialized);

        _isInitialized = true;
        _lockerAddress = lockerAddress_;

    }

}

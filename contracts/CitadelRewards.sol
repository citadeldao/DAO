// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ICitadelVestingTransport.sol";


contract CitadelRewards is Ownable {
    using SafeMath for uint;

    struct UserSnapshot {
        uint rewardPerToken;
        uint frozen;
        uint vested;
        uint claimed;
    }

    struct RewardUpdating {
        uint rewardPerToken;
        uint rewardPerTokenFixed;
        uint rate;
        uint lastUpdateDate;
        uint index;
        bool isUpdated;
    }

    ICitadelVestingTransport private _Token;
    uint private _maxInflationSupply;
    mapping (address => UserSnapshot) private _userSnapshots;
    uint private _totalSupply;
    uint private _savedInflationIndex;
    uint private _lastUpdateTime;
    uint private _rewardPerTokenStored;
    uint private _rewardRate;

    modifier onlyToken() {
        require(msg.sender == address(_Token));
        _;
    }

    modifier needUpdateInflation() {
        _Token.updateSnapshot();
        _;
    }

    modifier updateReward(address account) {
        RewardUpdating memory data = _getRewardsUpdate();
        if (data.isUpdated) {
            _rewardPerTokenStored = data.rewardPerToken;
            _lastUpdateTime = data.lastUpdateDate;
            _savedInflationIndex = data.index;
            _rewardRate = data.rate;
        }

        uint time = _timestamp();
        _rewardPerTokenStored = rewardPerToken(time);
        _lastUpdateTime = time;

        _userSnapshots[account].vested = _vested(account, true);
        _userSnapshots[account].rewardPerToken = _rewardPerTokenStored;
        _;
    }

    event Claim(address recipient, uint amount);

    constructor (
        address addressOfToken
    ) public {
        _Token = ICitadelVestingTransport(addressOfToken);
        _maxInflationSupply = _Token.getMaxSupply();
    }

    /** EXTERNAL READ */

    function version() external pure returns (uint) {
        return 1;
    }

    function getRewardRate() external view returns (uint) {
        return _rewardRate;
    }

    function getRewardsCoef() external view returns (uint) {
        return _rewardPerTokenStored;
    }

    function get_lastUpdateTime() external view returns (uint) {
        return _lastUpdateTime;
    }

    function getUserSnapshot(address account) external view returns (UserSnapshot memory) {
        return _userSnapshots[account];
    }

    function claimable(address account) external view returns (uint) {
        return _vested(account).sub(_userSnapshots[account].claimed);
    }

    function totalVestedOf(address account) external view returns (uint) {
        return _vested(account);
    }

    function totalClaimedOf(address account) external view returns (uint) {
        return _userSnapshots[account].claimed;
    }

    /** EXTERNAL WRITE */

    function claimFor(address account) external onlyToken updateReward(account) returns (uint amount) {
        amount = _userSnapshots[account].vested - _userSnapshots[account].claimed;
        require(amount > 0, "Zero amount to claim");
        _userSnapshots[account].claimed = _userSnapshots[account].vested;
        emit Claim(account, amount);
    }

    function claim() external needUpdateInflation updateReward(msg.sender) returns (uint amount) {
        address account = msg.sender;
        amount = _userSnapshots[account].vested.sub(_userSnapshots[account].claimed);
        require(amount > 0, "Zero amount to claim");
        _userSnapshots[account].claimed = _userSnapshots[account].vested;
        emit Claim(account, amount);
        _Token.withdraw(account, amount);
    }

    function updateSnapshot(address account) external onlyToken updateReward(account) {
        _totalSupply = _Token.lockedSupply();
        _userSnapshots[account].frozen = _Token.lockedBalanceOf(account);
    }

    /** PUBLIC */

    function rewardPerToken(uint time) public view returns (uint) {
        if (_totalSupply == 0) return _rewardPerTokenStored;
        return _rewardRate.mul(time.sub(_lastUpdateTime)).div(_totalSupply).add(_rewardPerTokenStored);
    }

    /** INTERNAL */

    function _vested(address account) internal view returns (uint) {
        return _vested(account, false);
    }

    function _vested(address account, bool easy) internal view returns (uint) {
        if (_userSnapshots[account].frozen == 0) return _userSnapshots[account].vested;

        uint time = _timestamp();

        if (!easy) {
            RewardUpdating memory data = _getRewardsUpdate();
            if (data.isUpdated) {
                uint tmpRewardPerToken = _totalSupply > 0 ? data.rate.mul(time.sub(data.lastUpdateDate)).div(_totalSupply).add(data.rewardPerToken) : data.rewardPerToken;
                return _userSnapshots[account].frozen.mul(tmpRewardPerToken.sub(_userSnapshots[account].rewardPerToken)).div(1e18).add(_userSnapshots[account].vested);
            }
        }

        return _userSnapshots[account].frozen.mul(rewardPerToken(time).sub(_userSnapshots[account].rewardPerToken)).div(1e18).add(_userSnapshots[account].vested);
    }

    function _getRewardsUpdate() internal view returns (
        RewardUpdating memory data
    ) {

        if (_savedInflationIndex > 0 && _rewardRate == 0) return data;

        data.index = _savedInflationIndex;

        uint countInflation = _Token.countInflationPoints();
        uint fixedTimestamp = _timestamp();
        uint inflationYear = _Token.getSavedInflationYear();
        uint yearlyVesting;

        if (countInflation > data.index) {

            ICitadelVestingTransport.InflationPointValues memory currPoint;

            data.rewardPerToken = _rewardPerTokenStored;
            data.lastUpdateDate = _lastUpdateTime;
            data.rate = _rewardRate;

            for (data.index; data.index < countInflation; data.index++) {

                currPoint = _Token.inflationPoint(data.index);
                if (currPoint.date > fixedTimestamp) return data;

                if (data.rate > 0 && data.lastUpdateDate > 0 && _totalSupply > 0) {
                    data.rewardPerToken = data.rate.mul(currPoint.date.sub(data.lastUpdateDate)).div(_totalSupply).add(data.rewardPerToken);
                }

                if (currPoint.inflationPct < 200) {
                    yearlyVesting = _maxInflationSupply.sub(currPoint.yearlySupply).mul(currPoint.stakingPct).div(100);
                } else {
                    yearlyVesting = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).div(1000000);
                }
                
                data.rate = yearlyVesting.mul(1e18).div(365 days);

                data.lastUpdateDate = currPoint.date;

            }

            data.isUpdated = true;

        }

        if (_totalSupply > 0) {
            uint endOfYear = inflationYear.add(365 days);
            if (endOfYear < fixedTimestamp) {

                if (!data.isUpdated) {
                    data.isUpdated = true;
                    data.rewardPerToken = _rewardPerTokenStored;
                    data.lastUpdateDate = _lastUpdateTime;
                    data.rate = _rewardRate;
                }

                ICitadelVestingTransport.InflationPointValues memory currPoint = _Token.inflationPoint(data.index - 1);

                currPoint.yearlySupply = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(endOfYear.sub(currPoint.date)).div(365 days).div(10000).add(currPoint.currentSupply);

                uint leftTime = endOfYear.sub(data.lastUpdateDate);

                while (endOfYear < fixedTimestamp) {
                    
                    data.rewardPerToken = data.rate.mul(leftTime).div(_totalSupply).add(data.rewardPerToken);
                    if (leftTime < 365 days) leftTime = 365 days;

                    if (currPoint.inflationPct > 200) {
                        currPoint.inflationPct = currPoint.inflationPct.sub(50); // -0.5% each year
                        if (currPoint.inflationPct < 200) currPoint.inflationPct = 200; // 2% is minimum
                    } else if (currPoint.inflationPct == 200) {
                        uint rest = _maxInflationSupply.sub(currPoint.yearlySupply).mul(10000).div(currPoint.yearlySupply);
                        if (rest < 200) currPoint.inflationPct = rest;
                    }

                    yearlyVesting = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).div(1000000);
                    
                    if (currPoint.yearlySupply.add(yearlyVesting) >= _maxInflationSupply) {
                        yearlyVesting = _maxInflationSupply.sub(currPoint.yearlySupply);
                    }

                    currPoint.yearlySupply = currPoint.yearlySupply.add(yearlyVesting);
                    
                    data.rate = yearlyVesting.mul(1e18).div(365 days);
                    

                    endOfYear = endOfYear.add(365 days);

                    if (currPoint.inflationPct < 200) break;

                }

                data.lastUpdateDate = endOfYear.sub(365 days);

            }
        }

    }

    function _timestamp() internal virtual view returns (uint) {
        return block.timestamp;
    }

}

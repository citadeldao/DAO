// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

//import "../node_modules/openzeppelin-solidity/contracts/math/Math.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/utils/Strings.sol";
import "./ICitadelVestingTransport.sol";


contract CitadelRewards2 is Ownable {
    using SafeMath for uint;
    using Strings for uint;

    ICitadelVestingTransport private _Token;
    uint private _maxInflationSupply;

    struct Option {
        uint value;
        uint date;
    }

    struct InflationValues {
        uint inflationPct;
        uint stakingPct;
        uint date;
    }

    struct InflationPointValues {
        uint inflationPct;
        uint stakingPct;
        uint currentSupply;
        uint yearlySupply;
        uint date;
    }

    struct UserSnapshot {
        uint indexInflation;
        uint indexSupplyHistory;
        uint rewardPerToken;
        uint frozen;
        uint vested;
        uint claimed;
        uint dateUpdate;
    }

    mapping (address => UserSnapshot) private _userSnapshots;
    mapping (address => mapping (uint => Option)) private _userStaked;

    byte private constant NEXT_NOTHING = 0x00;
    byte private constant NEXT_INFLATION = 0x10;
    byte private constant NEXT_SUPPLY = 0x20;




    
    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint public periodFinish;

    uint private _totalSupply;
    //Snapshot private _snapshot;

    //mapping(address => uint) public userRewardPerTokenPaid;
    //mapping(address => uint) public rewards;

    function lastTimeRewardApplicable() public view returns (uint) {
        uint currentTime = _timestamp();
        if (periodFinish == 0) return currentTime;
        return currentTime < periodFinish ? currentTime : periodFinish;
    }

    function rewardPerToken(uint time) public view returns (uint) {
        if (_totalSupply == 0) return rewardPerTokenStored;
        return _rewardRate.mul(time.sub(lastUpdateTime)).div(_totalSupply).add(rewardPerTokenStored);
            //rewardPerTokenStored.add(
            //    _yearlyVesting.mul(lastTimeRewardApplicable().sub(lastUpdateTime)).div(365 days).mul(1e18).div(_totalSupply)
            //);
    }

    /*function addRewardPerToken(uint time) public view returns (uint) {
        if (_totalSupply == 0) return 0;
        return _yearlyVesting.mul(time).div(365 days).mul(1e18).div(_totalSupply);
    }*/

    function vested(address account) public view returns (uint) {
        //return rewardPerToken().sub(_userSnapshots[account].rewardPerToken);
        if (_userSnapshots[account].frozen == 0) return _userSnapshots[account].vested;

        uint time = _timestamp();

        RewardUpdating memory data = _getRewardsUpdate();
        if (data.isUpdated) {
            //uint tmpRewardPerToken = data.rewardPerToken;
            //uint tmpLastUpdateTime = data.lastUpdateDate;
            //_savedInflationIndex = data.index;
            //_rewardRate = data.rate;
            //_yearlyVesting = data.yearlyVesting;
            //_savedInflationYear = data.inflationYear;

            uint tmpRewardPerToken = _totalSupply > 0 ? data.rate.mul(time.sub(data.lastUpdateDate)).div(_totalSupply).add(data.rewardPerToken) : data.rewardPerToken;

            return _userSnapshots[account].frozen.mul(tmpRewardPerToken.sub(_userSnapshots[account].rewardPerToken)).div(1e18).add(_userSnapshots[account].vested);
        }

        return _userSnapshots[account].frozen.mul(rewardPerToken(time).sub(_userSnapshots[account].rewardPerToken)).div(1e18).add(_userSnapshots[account].vested);
    }

    modifier updateReward(address account) {
        RewardUpdating memory data = _getRewardsUpdate();
        if (data.isUpdated) {
            rewardPerTokenStored = data.rewardPerToken;
            lastUpdateTime = data.lastUpdateDate;
            _savedInflationIndex = data.index;
            _rewardRate = data.rate;
            //_yearlyVesting = data.yearlyVesting;
            //_savedInflationYear = data.inflationYear;
        }

        uint time = _timestamp();
        rewardPerTokenStored = rewardPerToken(time);
        lastUpdateTime = time;
        
        if (account != address(0)) {
            _userSnapshots[account].vested = vested(account);
            _userSnapshots[account].rewardPerToken = rewardPerTokenStored;
        }
        _;
    }

    function updateSnapshot(address account) external onlyToken updateReward(account) {
        _totalSupply = _Token.lockedSupply();
        _userSnapshots[account].frozen = _Token.lockedBalanceOf(account);

        
        
        //if (_updateTokenRate()) {
            
        //}
    }

    struct RewardUpdating {
        uint rewardPerToken;
        uint rewardPerTokenFixed;
        uint yearlyVesting;
        uint rate;
        uint lastUpdateDate;
        uint inflationYear;
        uint index;
        bool isUpdated;
    }

    bool private _initInflation;
    uint private _inflationStartedDate;
    uint private _savedInflationYear;
    uint private _savedInflationIndex;
    uint private _yearlyVesting;
    uint private _rewardPerTokenFixed;
    uint private _rewardRate;

    function _getRewardsUpdate() private view returns (
        RewardUpdating memory data
    ) {

        // addRewardPerToken(uint time)

        data.index = _savedInflationIndex;
        uint countInflation = _Token.countInflationPoints();
        uint fixedTimestamp = _timestamp();
        uint inflationYear = _Token.getSavedInflationYear();

        if (countInflation > data.index) {

            //uint inflationStartDate = _Token.getInflationStartDate();
            ICitadelVestingTransport.InflationPointValues memory currPoint;

            data.rewardPerToken = rewardPerTokenStored;
            data.rewardPerTokenFixed = _rewardPerTokenFixed;
            data.lastUpdateDate = lastUpdateTime;
            data.rate = _rewardRate;
            //data.inflationYear = _savedInflationYear;

            for (data.index; data.index < countInflation; data.index++) {
                currPoint = _Token.inflationPoint(data.index);
                if (currPoint.date > fixedTimestamp) return data;

                if (data.rate > 0 && data.lastUpdateDate > 0 && _totalSupply > 0) {
                    data.rewardPerToken = data.rate.mul(currPoint.date.sub(data.lastUpdateDate)).div(_totalSupply).add(data.rewardPerToken);
                }

                data.yearlyVesting = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).div(1000000);
                data.rate = data.yearlyVesting.mul(1e18).div(365 days);

                //if (_totalSupply > 0 && inflationYear.add(365 days) <= fixedTimestamp) {
                //    data.rewardPerToken = data.rate.mul(currPoint.date.sub(data.lastUpdateDate)).div(_totalSupply).add(data.rewardPerToken);
                //}

                /*if (currPoint.date.sub(_savedInflationYear) < 365 days) {

                    uint leftTime = _savedInflationYear.add(365 days).sub(currPoint.date);
                    
                    data.yearlyVesting = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).mul(leftTime);
                    data.yearlyVesting = data.yearlyVesting.div(365 days).div(1000000);
                    data.yearlyVesting = data.yearlyVesting.add(currPoint.currentSupply.sub(currPoint.yearlySupply));

                    //if (_totalSupply > 0) {
                    //    rewardPerToken = _yearlyVesting.mul(time).div(365 days).mul(1e18).div(_totalSupply).add(rewardPerTokenStored);
                    //}
                
                } else {

                    //_savedInflationYear = currPoint.date;
                    //periodFinish = _savedInflationYear.add(365 days);
                    data.yearlyVesting = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).div(1000000);
                    data.rate = data.yearlyVesting.mul(1e18).div(365 days);

                    if (_totalSupply > 0 && data.lastUpdateDate > 0) {
                        data.rewardPerToken = data.rate.mul(currPoint.date.sub(data.lastUpdateDate)).div(_totalSupply).add(data.rewardPerToken);
                    }

                }*/

                //rewardRate = yearlyVesting.div(365 days);
                

                //if (_totalSupply > 0) {
                //    rewardPerToken = _yearlyVesting.mul(time).div(365 days).mul(1e18).div(_totalSupply).add(rewardPerTokenStored);
                //}
                // _yearlyVesting.mul(time).div(365 days).mul(1e18).div(_totalSupply);


                //rewardPerTokenStored = rewardPerToken();
                //lastUpdateTime = lastTimeRewardApplicable();
                data.lastUpdateDate = currPoint.date;

            }

            data.isUpdated = true;

        }

        
        if (_totalSupply > 0) {
            uint endOfYear = inflationYear.add(365 days);
            if (endOfYear < fixedTimestamp) {

                if (!data.isUpdated) {
                    data.isUpdated = true;
                    data.rewardPerToken = rewardPerTokenStored;
                    data.rewardPerTokenFixed = _rewardPerTokenFixed;
                    data.lastUpdateDate = lastUpdateTime;
                    data.rate = _rewardRate;
                }

                ICitadelVestingTransport.InflationPointValues memory currPoint = _Token.inflationPoint(data.index - 1);

                
                
                //revert(leftTime.toString());
                
                currPoint.yearlySupply = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(endOfYear.sub(currPoint.date)).div(365 days).div(10000).add(currPoint.currentSupply);

                //revert(currPoint.yearlySupply.toString());

                //data.lastUpdateDate = endOfYear;
                //endOfYear = endOfYear.add(365 days);

                uint leftTime = endOfYear.sub(data.lastUpdateDate);

                //revert(leftTime.toString());

                while (endOfYear < fixedTimestamp) {
                    
                    data.rewardPerToken = data.rate.mul(leftTime).div(_totalSupply).add(data.rewardPerToken);
                    if (leftTime < 365 days) leftTime = 365 days;

                    //data.lastUpdateDate = endOfYear;
                    //endOfYear = endOfYear.add(365 days);

                    /*if (currPoint.currentSupply > 0) {
                        currPoint.yearlySupply = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).mul(leftTime).div(365 days).div(1000000).add(currPoint.currentSupply);
                        currPoint.currentSupply = 0;
                    }*/

                    if (currPoint.inflationPct > 200) {
                        currPoint.inflationPct = currPoint.inflationPct.sub(50); // -0.5% each year
                        if (currPoint.inflationPct < 200) currPoint.inflationPct = 200; // 2% is minimum
                    } else if (currPoint.inflationPct == 200) {
                        uint rest = _maxInflationSupply.sub(currPoint.yearlySupply).mul(10000).div(currPoint.yearlySupply);
                        if (rest < 200) currPoint.inflationPct = rest;
                    }

                    data.yearlyVesting = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).div(1000000);
                    
                    if (currPoint.yearlySupply.add(data.yearlyVesting) >= _maxInflationSupply) {
                        data.yearlyVesting = _maxInflationSupply.sub(currPoint.yearlySupply);
                    }

                    currPoint.yearlySupply = currPoint.yearlySupply.add(data.yearlyVesting);
                    
                    data.rate = data.yearlyVesting.mul(1e18).div(365 days);
                    

                    endOfYear = endOfYear.add(365 days);

                    if (currPoint.inflationPct < 200) break;

                    /*
                    data.yearlyVesting = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).div(1000000);
                    data.rate = data.yearlyVesting.mul(1e18).div(365 days);
                    */
                    
                }

                

                data.lastUpdateDate = endOfYear.sub(365 days);

                //revert(data.rate.toString());
            }
        }

    }


    /*function _updateTokenRate() internal returns (bool) {
        //_Token.updateSnapshot();

        uint countInflation = _Token.countInflationPoints();

        if (countInflation > _savedInflationIndex) {

            uint fixedTimestamp = _timestamp();

            for (_savedInflationIndex; _savedInflationIndex < countInflation; _savedInflationIndex++) {
                ICitadelVestingTransport.InflationPointValues memory currPoint = _Token.inflationPoint(_savedInflationIndex);
                if (currPoint.date > fixedTimestamp) return false;

                uint yearlyVesting;
                if (currPoint.date.sub(_savedInflationYear) < 365 days) {

                    uint leftTime = _savedInflationYear.add(365 days).sub(currPoint.date);
                    
                    yearlyVesting = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).mul(leftTime);
                    yearlyVesting = yearlyVesting.div(365 days).div(1000000);
                    yearlyVesting = yearlyVesting.add(currPoint.currentSupply.sub(currPoint.yearlySupply));
                
                } else {

                    _savedInflationYear = currPoint.date;
                    periodFinish = _savedInflationYear.add(365 days);
                    yearlyVesting = currPoint.yearlySupply.mul(currPoint.inflationPct).mul(currPoint.stakingPct).div(1000000);

                }

                //rewardRate = yearlyVesting.div(365 days);
                rewardPerTokenStored = rewardPerToken();
                lastUpdateTime = lastTimeRewardApplicable();

            }

            return true;

        }

        return false;

    }*/






    event Claim(address recipient, uint amount);

    modifier onlyToken() {
        require(msg.sender == address(_Token));
        _;
    }

    constructor (
        address addressOfToken
    ) public {
        _Token = ICitadelVestingTransport(addressOfToken);
        _maxInflationSupply = _Token.getMaxSupply();
    }

    function claimable(address account) external view returns (uint) {
        //if (_userSnapshots[account].rewardPerToken == 0) return 0;
        //UserSnapshot memory snapshot = _makeUserSnapshot(account);
        return vested(account).sub(_userSnapshots[account].claimed);//snapshot.vested - snapshot.claimed;
    }

    function totalVestedOf(address account) external view returns (uint) {
        //if (_userSnapshots[account].rewardPerToken == 0) return 0;
        //_updateTokenRate();
        //UserSnapshot memory snapshot = _makeUserSnapshot(account);
        return vested(account);//snapshot.vested;
    }

    function totalClaimedOf(address account) external view returns (uint) {
        return _userSnapshots[account].claimed;
    }

    /*function updateSnapshot(address account) external onlyToken {
        uint fixedTimestamp = _timestamp();
        uint frozenCurrent = _Token.lockedBalanceOf(account);
        uint lastIndexSupplyHistory = _Token.totalSupplyHistoryCount() - 1;
        _userStaked[account][lastIndexSupplyHistory] = Option({
            value: frozenCurrent,
            date: fixedTimestamp
        });
        // first staking, just fixing indexes
        if (_userSnapshots[account].frozen == 0) {
            UserSnapshot storage snapshot = _userSnapshots[account];
            snapshot.indexInflation = _Token.countInflationPoints() - 1;
            snapshot.indexSupplyHistory = lastIndexSupplyHistory;
            snapshot.dateUpdate = fixedTimestamp;
            snapshot.frozen = frozenCurrent;
        }
    }*/

    function claimFor(address account) external onlyToken updateReward(account) returns (uint amount) {
        //_updateTokenRate();
        //_writeUserSnapshot(account);
        amount = _userSnapshots[account].vested - _userSnapshots[account].claimed;
        require(amount > 0, "Zero amount to claim");
        _userSnapshots[account].claimed = _userSnapshots[account].vested;
        emit Claim(account, amount);
    }

    function claim() external updateReward(msg.sender) returns (uint amount) {
        address account = msg.sender;
        //_updateTokenRate();
        //_writeUserSnapshot(account);
        amount = _userSnapshots[account].vested - _userSnapshots[account].claimed;
        require(amount > 0, "Zero amount to claim");
        _userSnapshots[account].claimed = _userSnapshots[account].vested;
        emit Claim(account, amount);
        _Token.withdraw(account, amount);
    }

    function _timestamp() internal virtual view returns (uint) {
        return block.timestamp;
    }

    /*
    function _writeUserSnapshot(address account) private {
        _userSnapshots[account] = _makeUserSnapshot(account);
    }

    function _makeUserSnapshot(address account) private view returns (UserSnapshot memory snapshot) {
        snapshot = _userSnapshots[account];

        if (snapshot.frozen == 0) return snapshot;

        // last yearly checkoint
        uint savedInflationYear = _Token.getSavedInflationYear();

        uint lastIndexInflation = _Token.countInflationPoints() - 1;
        uint lastIndexSupplyHistory = _Token.totalSupplyHistoryCount() - 1;

        ICitadelVestingTransport.InflationPointValues memory inflPoint = _Token.inflationPoint(snapshot.indexInflation);

        (uint totalStakedSupply,) = _Token.totalSupplyHistory(snapshot.indexSupplyHistory);

        if (snapshot.indexInflation == lastIndexInflation && inflPoint.currentSupply == _maxInflationSupply) return snapshot;

        uint fixedTimestamp = _timestamp();

        do {
            // check gas limit
            if (gasleft() < 50000) break;

            // check next options
            ICitadelVestingTransport.InflationPointValues memory nextInflation;
            Option memory nextSupply;
            if (snapshot.indexInflation < lastIndexInflation) {
                nextInflation = _Token.inflationPoint(snapshot.indexInflation + 1);
            }
            if (snapshot.indexSupplyHistory < lastIndexSupplyHistory) {
                (nextSupply.value, nextSupply.date) = _Token.totalSupplyHistory(snapshot.indexSupplyHistory + 1);
            }
            (byte nextStep, uint time) = _findNextStep(nextInflation, nextSupply);
            if (nextStep == NEXT_NOTHING) time = fixedTimestamp;
            
            // calculate

            if (nextStep != NEXT_INFLATION && time > savedInflationYear && time - savedInflationYear >= 365 days) {
                nextStep = NEXT_INFLATION;
                savedInflationYear += 365 days;
                time = savedInflationYear;
                uint updateUnlock = inflPoint.yearlySupply * inflPoint.inflationPct * (savedInflationYear - inflPoint.date) / 365 days / 10000;
                inflPoint.date = savedInflationYear;
                if (inflPoint.currentSupply + updateUnlock >= _maxInflationSupply) {

                    inflPoint.currentSupply = _maxInflationSupply;

                } else {

                    nextInflation.currentSupply = inflPoint.currentSupply + updateUnlock;
                    nextInflation.stakingPct = inflPoint.stakingPct;
                    nextInflation.yearlySupply = inflPoint.yearlySupply + inflPoint.yearlySupply * inflPoint.inflationPct / 10000;
                    if (inflPoint.inflationPct > 200) {
                        nextInflation.inflationPct = inflPoint.inflationPct - 50; // -0.5% each year
                        if (nextInflation.inflationPct < 200) nextInflation.inflationPct = 200; // 2% is minimum
                    } else if (inflPoint.inflationPct == 200) {
                        uint rest = (_maxInflationSupply - nextInflation.currentSupply) * 10000 / nextInflation.currentSupply;
                        if (rest < 200) nextInflation.inflationPct = rest;
                    } else {
                        nextInflation.inflationPct = inflPoint.inflationPct;
                    }

                }
            }
            
            // Multiplying
            // 1) yearlySupply * inflationPct // vested
            // 2) stakingPct
            // 3) snapshot.frozen
            // 4) time - snapshot.dateUpdate

            // Dividing
            // 1) 10000
            // 2) 100
            // 3) totalStakedSupply
            // 4) 365 days

            uint upd;

            if (totalStakedSupply > 0) {
                if (inflPoint.currentSupply == _maxInflationSupply) {
                    
                    upd = (inflPoint.currentSupply - inflPoint.yearlySupply) * inflPoint.stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                    upd = upd / totalStakedSupply / 365 days / 100;
                    snapshot.vested += upd;
                    snapshot.dateUpdate = time;
                    break;

                } else if (inflPoint.inflationPct < 200) {

                    upd = (_maxInflationSupply - inflPoint.yearlySupply) * inflPoint.stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                    upd = upd / totalStakedSupply / 365 days / 100;

                } else {

                    upd = inflPoint.yearlySupply * inflPoint.inflationPct * inflPoint.stakingPct * snapshot.frozen * (time - snapshot.dateUpdate);
                    upd = upd / totalStakedSupply / 365 days / 10000 / 100;

                }
            }
            
            snapshot.vested += upd;
            snapshot.dateUpdate = time;

            if (nextStep == NEXT_INFLATION) {

                inflPoint.inflationPct = nextInflation.inflationPct;
                inflPoint.stakingPct = nextInflation.stakingPct;
                inflPoint.currentSupply = nextInflation.currentSupply;
                inflPoint.yearlySupply = nextInflation.yearlySupply;
                inflPoint.date = time;
                snapshot.indexInflation++;

            } else if (nextStep == NEXT_SUPPLY) {

                totalStakedSupply = nextSupply.value;
                snapshot.indexSupplyHistory++;

                Option memory updateStake = _userStaked[account][snapshot.indexSupplyHistory];
                if (updateStake.date > 0) {
                    snapshot.frozen = updateStake.value;
                }

            }
        } while (
            snapshot.indexInflation < lastIndexInflation ||
            snapshot.indexSupplyHistory < lastIndexSupplyHistory ||
            snapshot.dateUpdate < fixedTimestamp
        );
    }
    */

    function _findNextStep(
        ICitadelVestingTransport.InflationPointValues memory nextInflation,
        Option memory nextSupply
    ) private pure returns (byte lastByte, uint minDate) {

        uint dateInf = nextInflation.date;
        uint dateSup = nextSupply.date;

        lastByte = NEXT_NOTHING;

        if (dateInf > 0) {
            minDate = dateInf;
            lastByte = NEXT_INFLATION;
        }
        if (dateSup > 0 && (dateSup < minDate || minDate == 0)) {
            minDate = dateSup;
            lastByte = NEXT_SUPPLY;
        }

    }

    function version() external pure returns (string memory) {
        return '1.0.0';
    }

}

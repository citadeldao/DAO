// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;

import "./CitadelExchange.sol";


contract CitadelInvestors is CitadelExchange {

    struct Person {
        uint limit;
        uint used;
        uint percent;
    }

    address private _addressTeam;
    uint private _totalTeam;
    uint[] private _stagesTeam;
    bool private _setTeam;
    mapping (address => Person) private _team;

    address private _addressInvestors;
    uint private _totalInvestors;
    uint[] private _stagesInvestors;
    bool private _setInvestors;
    mapping (address => Person) private _investors;

    function setTeam(address[] calldata persons, uint[] calldata amounts) external onlyOwner {
        require(!_setTeam);
        _setTeam = true;
        require(persons.length == amounts.length);
        uint countTotal;
        for (uint i = 0; i < persons.length; i++) {
            uint amount = amounts[i];
            require(amount > 0);
            require(_team[persons[i]].limit == 0);
            countTotal = countTotal.add(amount);
            _team[persons[i]] = Person(amount, 0, amount.mul(percentDecimal).div(_totalTeam));
        }
        require(countTotal == _totalTeam, "CitadelInvestors: total amount must be equal team part");
    }

    function setInvestors(address[] calldata persons, uint[] calldata amounts) external onlyOwner {
        require(!_setInvestors);
        _setInvestors = true;
        require(persons.length == amounts.length);
        uint countTotal;
        for (uint i = 0; i < persons.length; i++) {
            uint amount = amounts[i];
            require(amount > 0);
            require(_investors[persons[i]].limit == 0);
            countTotal = countTotal.add(amount);
            _investors[persons[i]] = Person(amount, 0, amount.mul(percentDecimal).div(_totalInvestors));
        }
        require(countTotal == _totalInvestors, "CitadelInvestors: total amount must be equal team part");
    }

    function claimTeam (uint256 amount) external {
        address account = msg.sender;
        require(_team[account].limit > 0, "CitadelInvestors: team only");

        uint available = _getAvailableSum(_team[account], _totalTeam, _stagesTeam);

        require(amount <= available, "CitadelInvestors: too big amount");

        _team[account].used = _team[account].used.add(amount);
        require(_team[account].used <= _team[account].limit);

        _transfer(_addressTeam, account, amount);
    }

    function claimInvestor (uint256 amount) external {
        address account = msg.sender;
        require(_investors[account].limit > 0, "CitadelInvestors: investor only");

        uint available = _getAvailableSum(_investors[account], _totalInvestors, _stagesInvestors);

        require(amount <= available, "CitadelInvestors: too big amount");

        _investors[account].used = _investors[account].used.add(amount);
        require(_investors[account].used <= _investors[account].limit);

        _transfer(_addressInvestors, account, amount);
    }

    function getTeamInfoOf (address addr) external view
    returns (
        uint limit,
        uint used,
        uint available,
        uint percent,
        uint time
    ) {
        time = block.timestamp - deployDate;
        limit = _team[addr].limit;
        used = _team[addr].used;
        percent = _team[addr].percent;
        available = _getAvailableSum(_team[addr], _totalTeam, _stagesTeam);
    }

    function getInvestorInfoOf (address addr) external view
    returns (
        uint limit,
        uint used,
        uint available,
        uint percent,
        uint time
    ) {
        time = block.timestamp - deployDate;
        limit = _investors[addr].limit;
        used = _investors[addr].used;
        percent = _investors[addr].percent;
        available = _getAvailableSum(_investors[addr], _totalInvestors, _stagesInvestors);
    }

    function _getAvailableSum (Person memory person, uint totalBudget, uint[] memory stages) private view
    returns (uint) {
        uint lastYears = _lifeYears(block.timestamp);
        uint total = totalBudget;
        if (stages.length > lastYears) {
            uint index = lastYears > 0 ? lastYears - 1 : 0;
            total = totalBudget.mul(stages[index]).div(100);
            if (lastYears > 0) {
                uint more = totalBudget.mul(stages[lastYears]).div(100).sub(total);
                more = more.mul((block.timestamp - deployDate) % 365 days).div(365 days);
                total = total.add(more);
            } else {
                total = total.mul((block.timestamp - deployDate) % 365 days).div(365 days);
            }
        }
        total = total.mul(person.percent).div(percentDecimal);
        if (total > person.limit) total = person.limit;
        return total.sub(person.used);
    }

    function _initTeam(address addr, uint amount, uint[] memory stages) internal {
        require(_totalTeam == 0);
        _addressTeam = addr;
        _totalTeam = amount;
        _stagesTeam = stages;
    }

    function _initInvestors(address addr, uint amount, uint[] memory stages) internal {
        require(_totalInvestors == 0);
        _addressInvestors = addr;
        _totalInvestors = amount;
        _stagesInvestors = stages;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./Managing.sol";


contract Voting is Managing {

    enum ProposalType {
        Native,
        Multi
    }

    enum ProposalUpdater {
        Nothing,
        Inflation,
        Vesting,
        CreateProposal,
        UpdateConfig,
        ExecutionTime
    }

    struct ProposalConfig {
        uint quorumPct;
        uint supportPct;
    }

    struct Proposal {
        address creator;
        string title;
        string description;
        ProposalType votingType;
        ProposalUpdater votingUpdater;
        string updateData;
        uint quorumPct;
        bool hasQuorum;
        uint supportPct;
        ProposalOption[] options;
        uint expiryTime;
        uint totalVotingPower;
        uint voters;
        bool executed;
    }

    struct ProposalInfo {
        string title;
        ProposalType votingType;
        ProposalUpdater votingUpdater;
        uint nay;
        uint yea;
        bool hasQuorum;
        bool accepted;
        uint maxIndex;
        bool tie;
        uint expiryTime;
    }

    struct ProposalInfoConfig {
        address creator;
        uint quorumPct;
        uint supportPct;
        uint voters;
        string updateData;
        bool executed;
    }

    struct ProposalOption {
        string name;
        uint256 count;
        uint256 weight;
    }

    struct GotVote {
        uint option;
        uint amount;
    }

    bool private _everyoneCreateProposal;
    uint private _minAmountToCreate = 10000e6;
    uint private _executionTime = 30 days;
    mapping (uint8 => ProposalConfig) private _proposalConfigs;

    mapping (uint => Proposal) private _proposals;
    mapping (uint8 => uint) private _executedProposal;
    mapping (address => mapping (uint => uint)) private _deposited;
    mapping (address => mapping(uint => GotVote)) private _voted;
    mapping (address => uint[]) private _holderActiveVotes;
    uint private _countProposals;

    event SetProposalAvailability(bool isAvailable, uint minStaked);
    event NewProposal(
        uint indexed issueId,
        address indexed creator,
        ProposalType indexed votingType,
        ProposalUpdater votingUpdater
    );
    event ExecProposal(uint indexed issueId, ProposalUpdater indexed category, address indexed initialized);
    event OnVote(uint indexed issueId, address indexed from, uint indexed option, uint weight);
    event UpdatedProposalConfig(ProposalUpdater indexed updater, uint quorumPct, uint supportPct);

    modifier canCreateProposals() {
        if (hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender)) {
            _;
            return;
        }
        if (_everyoneCreateProposal) {
            uint balance = _Token.balanceOf(msg.sender);
            if (balance >= _minAmountToCreate) {
                _;
                return;
            }
        }
        revert("Voting: you do not have permission");
    }

    modifier hasProposal(uint id) {
        require(id > 0 && id <= _countProposals, "Voting: proposal does not exist");
        _;
    }

    constructor () public {
        uint quorumPct = 20 * 1000;
        uint supportPct = 50 * 1000 + 1;
        _proposalConfigs[uint8(ProposalUpdater.Nothing)] = ProposalConfig(quorumPct, supportPct);
        emit UpdatedProposalConfig(ProposalUpdater.Nothing, quorumPct, supportPct);
        _proposalConfigs[uint8(ProposalUpdater.Inflation)] = ProposalConfig(quorumPct, supportPct);
        emit UpdatedProposalConfig(ProposalUpdater.Inflation, quorumPct, supportPct);
        _proposalConfigs[uint8(ProposalUpdater.Vesting)] = ProposalConfig(quorumPct, supportPct);
        emit UpdatedProposalConfig(ProposalUpdater.Vesting, quorumPct, supportPct);
        _proposalConfigs[uint8(ProposalUpdater.CreateProposal)] = ProposalConfig(quorumPct, supportPct);
        emit UpdatedProposalConfig(ProposalUpdater.CreateProposal, quorumPct, supportPct);
        _proposalConfigs[uint8(ProposalUpdater.UpdateConfig)] = ProposalConfig(quorumPct, supportPct);
        emit UpdatedProposalConfig(ProposalUpdater.UpdateConfig, quorumPct, supportPct);
        _proposalConfigs[uint8(ProposalUpdater.ExecutionTime)] = ProposalConfig(quorumPct, supportPct);
        emit UpdatedProposalConfig(ProposalUpdater.ExecutionTime, quorumPct, supportPct);
    }

    // VIEW

    function isOpenProposals() external view returns (bool) {
        return _everyoneCreateProposal;
    }

    function minAmountToCreate() external view returns (uint) {
        return _minAmountToCreate;
    }

    function executionTime() external view returns (uint) {
        return _executionTime;
    }

    function proposalConfigRates(ProposalUpdater conf) external view
    returns (uint quorumPct, uint supportPct) {
        quorumPct = _proposalConfigs[uint8(conf)].quorumPct;
        supportPct = _proposalConfigs[uint8(conf)].supportPct;
    }

    function availableToCreateProposals(address account) external view returns (bool) {
        if (hasRole(VOTING_ROLE, account) || hasRole(ADMIN_ROLE, account)) {
            return true;
        }
        if (_everyoneCreateProposal) {
            uint balance = _Token.balanceOf(account);
            return balance >= _minAmountToCreate;
        }
        return false;
    }

    function depositedForProposal(address creator, uint issueId) external view
    returns (uint)
    {
        return _deposited[creator][issueId];
    }

    function getNewestProposal() external view
    returns (
        uint issueId,
        string memory title,
        ProposalType votingType,
        ProposalUpdater votingUpdater
    ) {
        issueId = _countProposals;
        title = _proposals[issueId].title;
        votingType = _proposals[issueId].votingType;
        votingUpdater = _proposals[issueId].votingUpdater;
    }

    function countProposals() external view returns (uint) {
        return _countProposals;
    }

    function issueDescription(uint256 issueId) external view
    hasProposal(issueId)// override
    returns (string memory) {
        return _proposals[issueId].description;
    }

    function countOptions(uint issueId) external view
    hasProposal(issueId)// override
    returns (uint) {
        return _proposals[issueId].options.length;
    }

    function optionName(uint issueId, uint option) external view
    hasProposal(issueId)// override
    returns (string memory) {
        require(_proposals[issueId].options.length > option, "Voting: out of indexes");
        return _proposals[issueId].options[option].name;
    }

    function optionInfo(uint issueId, uint option) external view
    hasProposal(issueId)// override
    returns (string memory name, uint256 count, uint256 weight) {
        require(_proposals[issueId].options.length > option, "Voting: out of indexes");
        ProposalOption storage opt = _proposals[issueId].options[option];
        name = opt.name;
        count = opt.count;
        weight = opt.weight;
    }

    function ballotOf(uint issueId, address addr) external view
    hasProposal(issueId)// override
    returns (uint) {
        return _voted[addr][issueId].option;
    }

    function weightOf(uint issueId, address addr) external view
    hasProposal(issueId)// override
    returns (uint) {
        return _voted[addr][issueId].amount;
    }

    function weightedVoteCountsOf(uint issueId, uint option) external view
    hasProposal(issueId)// override
    returns (uint) {
        return _proposals[issueId].options[option].count;
    }

    function proposalInfo(uint issueId) external view
    returns (
        string memory title,
        ProposalType votingType,
        ProposalUpdater votingUpdater,
        uint nay,
        uint yea,
        uint totalVotingPower,
        bool hasQuorum,
        bool accepted,
        uint expiryTime
    ) {
        ProposalInfo memory info = _proposalInfo(issueId);
        title = info.title;
        votingType = info.votingType;
        votingUpdater = info.votingUpdater;
        nay = info.nay;
        yea = info.yea;
        hasQuorum = info.hasQuorum;
        accepted = info.accepted;
        expiryTime = info.expiryTime;

        Proposal memory proposal = _proposals[issueId];
        totalVotingPower = proposal.totalVotingPower;
    }

    function proposalConfig(uint issueId) external view
    returns (
        address creator,
        uint quorumPct,
        uint supportPct,
        uint voters,
        string memory updateData,
        bool executed
    ) {
        ProposalInfoConfig memory info = _proposalConfig(issueId);
        creator = info.creator;
        quorumPct = info.quorumPct;
        supportPct = info.supportPct;
        voters = info.voters;
        updateData = info.updateData;
        executed = info.executed;
    }

    // EXTERNAL

    function createProposalAvailability(bool isAvailable, uint minStaked) external {
        require(hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Voting: you do not have permission");
        _everyoneCreateProposal = isAvailable;
        _minAmountToCreate = minStaked;
        emit SetProposalAvailability(isAvailable, minStaked);
    }

    function newProposal(
        string calldata title,
        string calldata description,
        uint expiryTime,
        string calldata updateData,
        ProposalUpdater votingUpdater
    ) external canCreateProposals {
        require(bytes(title).length > 0, "Voting: empty title");
        require(expiryTime > _timestamp(), "Voting: time must be bigger than current");

        _countProposals++;

        _delegateTokens(_countProposals);

        Proposal storage proposal = _proposals[_countProposals];
        ProposalConfig memory conf = _proposalConfigs[uint8(votingUpdater)];

        proposal.creator = msg.sender;
        proposal.title = title;
        proposal.description = description;
        proposal.quorumPct = conf.quorumPct;
        proposal.supportPct = conf.supportPct;
        proposal.expiryTime = expiryTime;
        proposal.votingType = ProposalType.Native;
        proposal.votingUpdater = votingUpdater;

        if (votingUpdater != ProposalUpdater.Nothing) {
            require(updaterValidateData(votingUpdater, updateData), "Voting: incorrect updating data");
            proposal.updateData = updateData;
        }

        proposal.options.push(ProposalOption('nay', 0, 0));
        proposal.options.push(ProposalOption('yea', 0, 0));

        emit NewProposal(_countProposals, msg.sender, ProposalType.Native, votingUpdater);
    }

    function newMultiProposal(
        string calldata title,
        string calldata description,
        uint expiryTime,
        string[] calldata options,
        ProposalUpdater votingUpdater
    ) external canCreateProposals {
        require(bytes(title).length > 0, "Voting: empty title");
        require(expiryTime > _timestamp(), "Voting: time must be bigger than current");
        require(options.length > 1, "Voting: must be at least two options");

        _countProposals++;

        _delegateTokens(_countProposals);

        Proposal storage proposal = _proposals[_countProposals];
        ProposalConfig memory conf = _proposalConfigs[uint8(votingUpdater)];

        proposal.creator = msg.sender;
        proposal.title = title;
        proposal.description = description;
        proposal.quorumPct = conf.quorumPct;
        proposal.supportPct = conf.supportPct;
        proposal.expiryTime = expiryTime;
        proposal.votingType = ProposalType.Multi;
        proposal.votingUpdater = votingUpdater;

        proposal.options.push(ProposalOption("Skip", 0, 0));
        for (uint i = 0; i < options.length; i++) {
            if (votingUpdater != ProposalUpdater.Nothing) {
                require(updaterValidateData(votingUpdater, options[i]), "Voting: incorrect updating data");
            }
            proposal.options.push(ProposalOption(options[i], 0, 0));
        }

        emit NewProposal(_countProposals, msg.sender, ProposalType.Multi, votingUpdater);
    }

    function vote(uint issueId, bytes4 option) external
    hasProposal(issueId)// override
    returns (bool) {
        bytes4 yea = bytes4("yea");
        bytes4 nay = bytes4("nay");
        require(option == yea || option == nay, "Voting: you should say yea or nay");
        require(_proposals[issueId].votingType == ProposalType.Native, "Voting: please choose an option by index");
        uint optionId = 0;
        if (option == yea) optionId = 1;
        return _vote(issueId, optionId);
    }

    function vote(uint issueId, uint option) external
    hasProposal(issueId)// override
    returns (bool) {
        Proposal memory proposal = _proposals[issueId];
        require(proposal.options.length > option, "Voting: out of indexes");
        return _vote(issueId, option);
    }

    function execProposal(uint issueId) external {
        ProposalInfoConfig memory infoConfig = _proposalConfig(issueId);
        require(infoConfig.creator == msg.sender || hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Voting: you do not have permission");
        require(!infoConfig.executed, "Voting: already executed");

        ProposalInfo memory info = _proposalInfo(issueId);
        require(info.votingUpdater != ProposalUpdater.Nothing, "Voting: this proposal is not executable");
        require(info.expiryTime < _timestamp(), "Voting: voting period is not finished yet");
        require(info.expiryTime + _executionTime > _timestamp(), "Voting: execution time is expired");
        require(info.accepted, "Voting: this proposal it not accepted");
        require(_executedProposal[uint8(info.votingUpdater)] <= issueId, "Voting: denied to execute the replaced proposal");

        string memory updateData;
        if (info.votingType == ProposalType.Multi) {
            updateData = _proposals[issueId].options[info.maxIndex].name;
        } else {
            updateData = infoConfig.updateData;
        }

        if (info.votingUpdater == ProposalUpdater.Inflation) {
            _Token.updateInflation(issueId, parseInt(updateData));
        } else if (info.votingUpdater == ProposalUpdater.Vesting) {
            _Token.updateVesting(issueId, parseInt(updateData));
        } else if (info.votingUpdater == ProposalUpdater.CreateProposal) {
            _minAmountToCreate = parseInt(updateData);
        } else if (info.votingUpdater == ProposalUpdater.UpdateConfig) {
            bytes memory _bytes = bytes(updateData);
            bytes memory confId = new bytes(1);
            bytes memory quorumPctBts = new bytes(6);
            bytes memory supportPctBts = new bytes(6);
            require(_bytes.length == 13);
            for(uint i = 0; i < _bytes.length; i++){
                if (i < 1) {
                    confId[0] = _bytes[0];
                } else if (i < 7) {
                    quorumPctBts[i - 1] = _bytes[i];
                } else {
                    supportPctBts[i - 7] = _bytes[i];
                }
            }
            uint256 quorumPct = parseInt(string(quorumPctBts));
            uint256 supportPct = parseInt(string(supportPctBts));
            _proposalConfigs[uint8(parseInt(string(confId)))] = ProposalConfig(quorumPct, supportPct);
        } else if (info.votingUpdater == ProposalUpdater.ExecutionTime) {
            _executionTime = parseInt(updateData);
        }

        _proposals[issueId].executed = true;
        _executedProposal[uint8(info.votingUpdater)] = issueId;

        emit ExecProposal(issueId, info.votingUpdater, msg.sender);
    }

    function redeemDepositFromProposal(uint issueId) external
    hasProposal(issueId)
    {
        require(_proposals[issueId].creator == msg.sender, "Voting: you do not have permission");
        require(_deposited[msg.sender][issueId] > 0, "Voting: empty deposit");

        ProposalInfo memory info = _proposalInfo(issueId);
        require(info.expiryTime < _timestamp(), "Voting: voting period is not finished yet");
        require(info.accepted, "Voting: this proposal it not accepted");

        _redeemTokens(issueId);
    }

    function burnLostTokens() external onlyOwner
    {
        uint total;
        for (uint issueId = 1; issueId <= _countProposals; issueId++) {
            address creator = _proposals[issueId].creator;
            uint amount = _deposited[creator][issueId];
            if (amount > 0) {
                ProposalInfo memory info = _proposalInfo(issueId);
                if (!info.accepted && info.expiryTime < _timestamp()) {
                    total += amount;
                    _deposited[creator][issueId] = 0;
                }
            }
        }
        if (total > 0) {
            _Token.redeemFromDAO(address(this), total);
            _Token.burn(total);
        }
    }

    // TOKEN ONLY

    function updatedStake(address holder) external {
        require(msg.sender == address(_Token));
        if (_holderActiveVotes[holder].length == 0) return;
        
        uint[] memory list = _holderActiveVotes[holder];
        uint supply = _Token.lockedSupply();
        uint tokens = _Token.lockedBalanceOf(holder);
        uint skipNum;
        for (uint i; i < list.length; i++) {
            uint issueId = list[i];
            Proposal storage proposal = _proposals[issueId];
            if (proposal.expiryTime < _timestamp()) {
                skipNum++;
                list[i] = 0;
                continue;
            }
            GotVote storage aVote = _voted[holder][issueId];
            if (tokens == 0) {
                proposal.voters--;
                proposal.totalVotingPower -= aVote.amount;
                proposal.options[aVote.option].weight -= aVote.amount;
                proposal.options[aVote.option].count--;
                aVote.amount = 0;
                proposal.hasQuorum = proposal.totalVotingPower * 100000 / supply >= proposal.quorumPct;
                
                skipNum++;
                list[i] = 0;
                continue;
            }
            if (aVote.amount > tokens) {
                proposal.options[aVote.option].weight -= aVote.amount - tokens;
            } else {
                proposal.options[aVote.option].weight += tokens - aVote.amount;
            }
            aVote.amount = tokens;
            proposal.hasQuorum = proposal.totalVotingPower * 100000 / supply >= proposal.quorumPct;
        }

        if (skipNum > 0) {
            if (skipNum == _holderActiveVotes[holder].length) {
                _holderActiveVotes[holder] = new uint[](0);
            } else {
                uint[] memory resetList = new uint[](_holderActiveVotes[holder].length - skipNum);
                uint newIndex;
                for (uint i; i < list.length; i++) {
                    uint issueId = list[i];
                    if (issueId > 0) {
                        resetList[newIndex] = issueId;
                        newIndex++;
                    }
                }
                _holderActiveVotes[holder] = resetList;
            }
        }
    }

    // PUBLIC UTILS

    function parseInt(
        string memory _value
    ) public pure returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48)*j;
            j*=10;
        }
    }

    function updaterValidateData(
        ProposalUpdater votingUpdater,
        string memory updateData
    ) public pure returns (bool) {
        if (votingUpdater == ProposalUpdater.Nothing) return true;
        if (votingUpdater == ProposalUpdater.Inflation) {
            uint value = parseInt(updateData);
            return value >= 200 && value < 3000;
        } else if (votingUpdater == ProposalUpdater.Vesting) {
            uint value = parseInt(updateData);
            return value >= 10 && value <= 90;
        } else if (votingUpdater == ProposalUpdater.CreateProposal) {
            uint value = parseInt(updateData);
            return value > 0;
        } else if (votingUpdater == ProposalUpdater.UpdateConfig) {
            bytes memory _bytes = bytes(updateData);
            require(_bytes.length == 13);
            bytes memory confId = new bytes(1);
            bytes memory quorumPctBts = new bytes(6);
            bytes memory supportPctBts = new bytes(6);
            for(uint i = 0; i < _bytes.length; i++){
                if (i < 1) {
                    confId[0] = _bytes[0];
                } else if (i < 7) {
                    quorumPctBts[i - 1] = _bytes[i];
                } else {
                    supportPctBts[i - 7] = _bytes[i];
                }
            }
            uint quorumPct = parseInt(string(quorumPctBts));
            uint supportPct = parseInt(string(supportPctBts));
            bool res = quorumPct > 0 && quorumPct <= 100*1000;
            res = res && supportPct > 0 && supportPct <= 100*1000;
            res = res && uint8(parseInt(string(confId))) <= uint8(ProposalUpdater.UpdateConfig);
            return res;
        } else if (votingUpdater == ProposalUpdater.ExecutionTime) {
            return parseInt(updateData) >= 1 days;
        }
        return false;
    }

    // INTERNAL

    function _proposalInfo(uint issueId) internal view
    hasProposal(issueId)
    returns (
        ProposalInfo memory info
    ) {
        Proposal memory proposal = _proposals[issueId];

        info.title = proposal.title;
        info.votingType = proposal.votingType;
        info.votingUpdater = proposal.votingUpdater;
        info.expiryTime = proposal.expiryTime;
        info.hasQuorum = proposal.hasQuorum;

        if(info.votingType == ProposalType.Native){
            info.nay = proposal.options[0].weight;
            info.yea = proposal.options[1].weight;
            if (info.expiryTime < _timestamp() && info.hasQuorum) {
                info.accepted = proposal.supportPct <= (info.yea * 100000 / proposal.totalVotingPower);
            } else {
                info.accepted = false;
            }
        } else {
            if (info.expiryTime < _timestamp() && info.hasQuorum) {
                uint maxWeight;
                for (uint i = 0; i < proposal.options.length; i++) {
                    ProposalOption memory option = proposal.options[i];
                    if (option.weight > maxWeight) {
                        info.maxIndex = i;
                        maxWeight = option.weight;
                        if (info.tie) info.tie = false;
                    } else if (option.weight == maxWeight) {
                        info.tie = true;
                    }
                }
                info.accepted = !info.tie && info.maxIndex > 0;
            } else {
                info.accepted = false;
            }
        }
    }

    function _proposalConfig(uint issueId) internal view
    hasProposal(issueId)
    returns (
        ProposalInfoConfig memory info
    ) {
        Proposal memory proposal = _proposals[issueId];

        info.creator = proposal.creator;
        info.quorumPct = proposal.quorumPct;
        info.supportPct = proposal.supportPct;
        info.voters = proposal.voters;
        info.updateData = proposal.updateData;
        info.executed = proposal.executed;
    }

    // PRIVATE

    function _vote(uint issueId, uint option) private
    hasProposal(issueId)
    returns (bool)
    {
        Proposal storage proposal = _proposals[issueId];
        if (proposal.expiryTime < _timestamp()) return false;
        address sender = msg.sender;
        uint256 tokens = _Token.lockedBalanceOf(sender);
        require(tokens > 0, "Voting: you have to lock your tokens before");
        require(_voted[sender][issueId].amount == 0, "Voting: you have already voted");

        _voted[sender][issueId] = GotVote(option, tokens);

        proposal.voters++;
        proposal.totalVotingPower += tokens;
        proposal.options[option].count++;
        proposal.options[option].weight += tokens;

        if (!proposal.hasQuorum) {
            uint quorumRctNow = proposal.totalVotingPower * 100000 / _Token.lockedSupply();

            if (quorumRctNow >= proposal.quorumPct) {
                proposal.hasQuorum = true;
            }
        }

        _holderActiveVotes[msg.sender].push(issueId);

        emit OnVote(issueId, sender, option, tokens);

        return true;
    }

    function _delegateTokens(uint issueId) private {
        if (hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender)) return;
        _deposited[msg.sender][issueId] = _minAmountToCreate;
        _Token.delegateToDAO(msg.sender, _minAmountToCreate);
    }

    function _redeemTokens(uint issueId) private {
        if (hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender)) return;
        _Token.redeemFromDAO(msg.sender, _deposited[msg.sender][issueId]);
        _deposited[msg.sender][issueId] = 0;
    }

}

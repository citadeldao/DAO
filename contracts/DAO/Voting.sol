// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./Managing.sol";


contract Voting is Managing {

    mapping (uint256 => Proposal) private _proposals;
    uint256 private _countProposals;

    bool private _everyoneCreateProposal;
    uint256 private _minAmountToCreate;

    enum ProposalType {
        Native,
        Multi
    }

    enum ProposalUpdater {
        Nothing,
        Inflation,
        CreateProposal,
        UpdateConfig
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
    }

    struct ProposalInfo {
        string title;
        ProposalType votingType;
        ProposalUpdater votingUpdater;
        uint nay;
        uint yea;
        bool hasQuorum;
        bool accepted;
        uint expiryTime;
    }

    struct ProposalInfoConfig {
        address creator;
        uint quorumPct;
        uint supportPct;
        uint voters;
        string updateData;
    }

    struct ProposalOption {
        string name;
        uint256 count;
        uint256 weight;
    }

    struct GotVote {
        uint option;
        uint256 amount;
    }

    mapping (address => mapping(uint => GotVote)) private _voted;
    mapping (uint8 => ProposalConfig) private _proposalConfigs;

    modifier canCreateProposals() {
        if (hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender)) {
            _;
            return;
        }
        if (_everyoneCreateProposal) {
            uint256 staked = _Token.lockedBalanceOf(msg.sender);
            if (staked >= _minAmountToCreate) {
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

    event NewProposal(
        uint indexed issueId,
        address indexed creator,
        string title,
        ProposalType indexed votingType,
        ProposalUpdater votingUpdater,
        uint quorumPct,
        uint supportPct,
        uint expiryTime
    );
    event ExecProposal(uint indexed issueId, address indexed initialized);
    event OnVote(uint indexed issueId, address indexed from, uint indexed option, uint256 weight);
    event UpdatedProposalConfig(ProposalUpdater indexed updater, uint quorumPct, uint supportPct);

    constructor () public {
        uint quorumPct = 50 * 1000;
        uint supportPct = 20 * 1000;
        _proposalConfigs[uint8(ProposalUpdater.Nothing)] = ProposalConfig(quorumPct, supportPct);
        emit UpdatedProposalConfig(ProposalUpdater.Nothing, quorumPct, supportPct);
        _proposalConfigs[uint8(ProposalUpdater.Inflation)] = ProposalConfig(quorumPct, supportPct);
    }

    function minAmountToCreate() external view returns (uint256) {
        return _minAmountToCreate;
    }

    function proposalConfigRates(ProposalUpdater conf) external view
    returns (uint quorumPct, uint supportPct) {
        quorumPct = _proposalConfigs[uint8(conf)].quorumPct;
        supportPct = _proposalConfigs[uint8(conf)].supportPct;
    }

    function createProposalAvailability(bool isAvailable, uint256 minStaked) external {
        require(hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Voting: you do not have permission");
        _everyoneCreateProposal = isAvailable;
        _minAmountToCreate = minStaked;
    }

    function availableToCreateProposals() external view returns (bool) {
        if (hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender)) {
            return true;
        }
        if (_everyoneCreateProposal) {
            uint256 staked = _Token.lockedBalanceOf(msg.sender);
            if (staked >= _minAmountToCreate) {
                return true;
            }
        }
        return false;
    }

    function newProposal(
        string calldata title,
        string calldata description,
        uint expiryTime,
        ProposalUpdater votingUpdater,
        string calldata updateData
    ) external canCreateProposals {
        //require(hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Voting: you do not have permission");
        require(bytes(title).length > 0, "Voting: empty title");
        //require(quorumPct > 0 && quorumPct<=100000, "Voting: quorum must be between 1 and 100000");
        //require(supportPct >= 20000 && supportPct<=100000, "Voting: support must be between 20000 and 100000");
        require(expiryTime > block.timestamp, "Voting: time must be bigger than current");

        _countProposals++;

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
            require(_updaterValidateData(votingUpdater, updateData), "Voting: incorrect updating data");
            proposal.updateData = updateData;
        }

        proposal.options.push(ProposalOption('nay', 0, 0));
        proposal.options.push(ProposalOption('yea', 0, 0));

        emit NewProposal(_countProposals, msg.sender, title, ProposalType.Native, votingUpdater, conf.quorumPct, conf.supportPct, expiryTime);
    }

    function newMultiProposal(
        string calldata title,
        string calldata description,
        uint expiryTime,
        string[] calldata options,
        ProposalUpdater votingUpdater
    ) external canCreateProposals {
        //require(hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Voting: you do not have permission");
        require(bytes(title).length > 0, "Voting: empty title");
        //require(quorumPct > 0 && quorumPct<=100000, "Voting: quorum must be between 1 and 100000");
        //require(supportPct >= 20000 && supportPct<=100000, "Voting: support must be between 20000 and 100000");
        require(expiryTime > block.timestamp, "Voting: time must be bigger than current");
        require(options.length > 1, "Voting: must be at least two options");

        _countProposals++;

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

        for (uint i = 0; i < options.length; i++) {
            if (votingUpdater != ProposalUpdater.Nothing) {
                require(_updaterValidateData(votingUpdater, options[i]), "Voting: incorrect updating data");
            }
            proposal.options.push(ProposalOption(options[i], 0, 0));
        }

        emit NewProposal(_countProposals, msg.sender, title, ProposalType.Multi, votingUpdater, conf.quorumPct, conf.supportPct, expiryTime);
    }

    function execProposal(uint issueId) external {

        ProposalInfo memory info = _proposalInfo(issueId);

        ProposalInfoConfig memory infoConfig = _proposalConfig(issueId);

        require(infoConfig.creator == msg.sender || hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Voting: you do not have permission");
        require(info.votingUpdater != ProposalUpdater.Nothing, "Voting: this proposal is not executable");
        require(info.expiryTime < block.timestamp, "Voting: voting period is not finished yet");
        if (info.votingType == ProposalType.Native){
            require(info.accepted, "Voting: this proposal it not accepted");
        }

        string memory updateData;
        if (info.votingType == ProposalType.Multi) {
            uint maxIndex;
            uint maxWeight;
            bool tie;
            for (uint i = 0; i < _proposals[issueId].options.length; i++) {
                ProposalOption memory option = _proposals[issueId].options[i];
                if (option.weight > maxWeight) {
                    maxIndex = i;
                    maxWeight = option.weight;
                    tie = false;
                } else if (option.weight == maxWeight) {
                    tie = true;
                }
            }
            require(!tie, "Voting: no leading option");
            updateData = _proposals[issueId].options[maxIndex].name;
        } else {
            updateData = infoConfig.updateData;
        }

        if (info.votingUpdater == ProposalUpdater.Inflation) {
            uint256 value = parseInt(updateData);
            uint stakingPct = value / 1000;
            uint vestingPct = value - stakingPct * 1000;
            _Token.changeInflationRatio(stakingPct, vestingPct);
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
        }

        emit ExecProposal(issueId, msg.sender);
    }

    function _updaterValidateData(
        ProposalUpdater votingUpdater,
        string memory updateData
    ) private pure returns (bool) {
        if (votingUpdater == ProposalUpdater.Nothing) return true;
        if (votingUpdater == ProposalUpdater.Inflation) {
            uint256 value = parseInt(updateData);
            uint stakingPct = value / 1000;
            uint vestingPct = value - stakingPct * 1000;
            return (stakingPct + vestingPct == 100);
        } else if (votingUpdater == ProposalUpdater.CreateProposal) {
            uint256 value = parseInt(updateData);
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
            uint256 quorumPct = parseInt(string(quorumPctBts));
            uint256 supportPct = parseInt(string(supportPctBts));
            bool res = quorumPct > 0 && quorumPct <= 100*1000;
            res = res && supportPct > 0 && supportPct <= 100*1000;
            res = res && uint8(parseInt(string(confId))) <= uint8(ProposalUpdater.UpdateConfig);
            return res;
        }
        return false;
    }

    function parseInt(string memory _value)
        public
        pure
        returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48)*j;
            j*=10;
        }
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
    }

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
            if (info.expiryTime < block.timestamp && info.hasQuorum) {
                info.accepted = proposal.supportPct <= (info.yea * 100000 / proposal.totalVotingPower);
            } else {
                info.accepted = false;
            }
        }
    }

    function proposalConfig(uint issueId) external view
    returns (
        address creator,
        uint quorumPct,
        uint supportPct,
        uint voters,
        string memory updateData
    ) {
        ProposalInfoConfig memory info = _proposalConfig(issueId);
        creator = info.creator;
        quorumPct = info.quorumPct;
        supportPct = info.supportPct;
        voters = info.voters;
        updateData = info.updateData;
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
    }

    function _vote(uint issueId, uint option) private
    hasProposal(issueId)
    returns (bool)
    {
        Proposal storage proposal = _proposals[issueId];
        if (proposal.expiryTime < block.timestamp) return false;
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
            uint supply = _Token.lockedSupply();
            uint hasQuorum = proposal.totalVotingPower * 100000;
            uint quorumRctNow = hasQuorum / supply;

            if (quorumRctNow >= proposal.quorumPct) {
                proposal.hasQuorum = true;
            }
        }

        emit OnVote(issueId, sender, option, tokens);

        return true;
    }

}

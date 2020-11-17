// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./Managing.sol";
import "../IERC1202.sol";


contract Voting is IERC1202, Managing {

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
        Vesting,
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
        bool isOpen;
        uint totalVotingPower;
        uint voters;
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
    event OnVote(uint indexed issueId, address indexed from, uint indexed option, uint256 weight);
    event OnProposalStatusChange(uint indexed issueId, bool newIsOpen);
    event UpdatedProposalConfig(ProposalUpdater indexed updater, uint quorumPct, uint supportPct);

    constructor () public {
        uint quorumPct = 50 * 1000;
        uint supportPct = 20 * 1000;
        _proposalConfigs[uint8(ProposalUpdater.Nothing)] = ProposalConfig(quorumPct, supportPct);
        emit UpdatedProposalConfig(ProposalUpdater.Nothing, quorumPct, supportPct);
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
        proposal.isOpen = true;

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

        proposal.title = title;
        proposal.description = description;
        proposal.quorumPct = conf.quorumPct;
        proposal.supportPct = conf.supportPct;
        proposal.expiryTime = expiryTime;
        proposal.votingType = ProposalType.Multi;
        proposal.votingUpdater = votingUpdater;
        proposal.isOpen = true;

        for (uint i = 0; i < options.length; i++) {
            if (votingUpdater != ProposalUpdater.Nothing) {
                require(_updaterValidateData(votingUpdater, options[i]), "Voting: incorrect updating data");
            }
            proposal.options.push(ProposalOption(options[i], 0, 0));
        }

        emit NewProposal(_countProposals, msg.sender, title, ProposalType.Multi, votingUpdater, conf.quorumPct, conf.supportPct, expiryTime);
    }

    function _updaterValidateData(
        ProposalUpdater votingUpdater,
        string memory updateData
    ) private pure returns (bool) {
        return true;
    }

    function setProposalStatus(uint issueId, bool isOpen) external
    hasProposal(issueId)// override
    returns (bool) {
        require(_proposals[issueId].creator == msg.sender || hasRole(VOTING_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Voting: you do not have permission");
        require(_proposals[issueId].expiryTime < block.timestamp, "Voting: time is out");
        _proposals[issueId].isOpen = isOpen;
        emit OnProposalStatusChange(issueId, isOpen);
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
    hasProposal(issueId)
    returns (
        string memory title,
        ProposalType votingType,
        ProposalUpdater votingUpdater,
        uint nay,
        uint yea,
        bool hasQuorum,
        bool accepted,
        uint expiryTime,
        bool isOpen
    ) {
        Proposal memory proposal = _proposals[issueId];

        title = proposal.title;
        votingType = proposal.votingType;
        votingUpdater = proposal.votingUpdater;
        expiryTime = proposal.expiryTime;
        hasQuorum = proposal.hasQuorum;
        isOpen = proposal.isOpen;

        if(votingType == ProposalType.Native){
            nay = proposal.options[0].weight;
            yea = proposal.options[1].weight;
            accepted = hasQuorum && proposal.supportPct <= (yea * 100000 / proposal.totalVotingPower);
        }
    }

    function proposalConfig(uint issueId) external view
    hasProposal(issueId)
    returns (
        uint quorumPct,
        uint supportPct,
        uint voters,
        string memory updateData
    ) {
        Proposal memory proposal = _proposals[issueId];

        quorumPct = proposal.quorumPct;
        supportPct = proposal.supportPct;
        voters = proposal.voters;
        updateData = proposal.updateData;
    }

    function _vote(uint issueId, uint option) private
    hasProposal(issueId)
    returns (bool)
    {
        Proposal storage proposal = _proposals[issueId];
        if (!proposal.isOpen) return false;
        if (proposal.expiryTime < block.timestamp) {
            proposal.isOpen = false;
            emit OnProposalStatusChange(issueId, false);
            return false;
        }
        address sender = msg.sender;
        uint256 tokens = _Token.lockedBalanceOf(sender);
        require(tokens > 0, "Voting: you have to lock your tokens before");
        require(_voted[sender][issueId].amount == 0, "Voting: you have already voted");

        _voted[sender][issueId] = GotVote(option, tokens);

        proposal.voters++;
        proposal.totalVotingPower += tokens;
        proposal.options[option].count++;
        proposal.options[option].weight += tokens;

        uint supply = _Token.lockedSupply();
        uint hasQuorum = proposal.totalVotingPower * 100000;
        uint quorumRctNow = hasQuorum / supply;

        if (quorumRctNow >= proposal.quorumPct) {
            proposal.hasQuorum = true;
            proposal.isOpen = false;
            emit OnProposalStatusChange(issueId, false);
        }

        emit OnVote(issueId, sender, option, tokens);

        return true;
    }

}

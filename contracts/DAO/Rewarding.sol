// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./Voting.sol";
import "../../node_modules/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";


contract Rewarding is Voting {

    address private _verifyRewardAddress;

    mapping (address => uint) private _logs;

    event ClaimStakingReward(address indexed recipient, uint256 amount);

    function setRewardAddress(address rewardAddress) external onlyOwner {
        _verifyRewardAddress = rewardAddress;
    }

    function claimReward(
        uint256 reward,
        uint256 timestamp,
        bytes32 hash,
        bytes calldata signature
    ) external returns (bool) {
        uint to = 90;
        require(timestamp < block.timestamp, "Rewarding: incorrect timestamp");
        require(block.timestamp - timestamp < to, "Rewarding: expiried");
        require(block.timestamp - _logs[msg.sender] > to, "Rewarding: freeze period");
        require(verifyReward(reward, timestamp, hash, signature), "Rewarding: incorrect signature");
        _logs[msg.sender] = block.timestamp;
        _Token.transferStakingRewards(msg.sender, reward);
        emit ClaimStakingReward(msg.sender, reward);
        return true;
    }

    function verifyReward(
        uint256 reward,
        uint256 timestamp,
        bytes32 hash,
        bytes memory signature
    )
    internal view
    returns (bool) {
        bytes32 verifyHash = keccak256(abi.encodePacked(msg.sender, reward, timestamp));
        require(hash == verifyHash, "Rewarding: incorrect hash");
        return ECDSA.recover(hash, signature) == _verifyRewardAddress;
    }

}

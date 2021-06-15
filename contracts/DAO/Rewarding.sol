// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./Voting.sol";
import "../../node_modules/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";


contract Rewarding is Voting {

    address private _verifyRewardAddress;

    mapping (address => uint) private _nonces;

    event ClaimStakingReward(address indexed recipient, uint amount);

    function setRewardAddress(address rewardAddress) external onlyOwner {
        _verifyRewardAddress = rewardAddress;
    }

    function claimReward(
        uint reward,
        uint nonceId,
        bytes32 hash,
        bytes calldata signature
    ) external returns (bool) {
        require(nonceId == _nonces[msg.sender], "Rewarding: incorrect nonceId");
        require(verifyReward(reward, nonceId, hash, signature), "Rewarding: incorrect signature");
        _nonces[msg.sender]++;
        _Token.withdraw(msg.sender, reward);
        emit ClaimStakingReward(msg.sender, reward);
        return true;
    }

    function verifyReward(
        uint reward,
        uint nonceId,
        bytes32 hash,
        bytes memory signature
    )
    internal view
    returns (bool) {
        bytes32 verifyHash = keccak256(abi.encodePacked(msg.sender, reward, nonceId));
        require(hash == verifyHash, "Rewarding: incorrect hash");
        return ECDSA.recover(hash, signature) == _verifyRewardAddress;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./Voting.sol";
import "../../node_modules/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "../../node_modules/openzeppelin-solidity/contracts/utils/Strings.sol";


contract Rewarding is Voting {

    address private _verifyRewardAddress;

    function setRewardAddress(address rewardAddress) external onlyOwner {
        _verifyRewardAddress = rewardAddress;
    }

    function claimReward(
        uint256 reward,
        bytes32 hash,
        bytes calldata signature
    ) external returns (bool) {
        require(verifyReward(reward, hash, signature), "Rewarding: incorrect signature");
        _Token.transferStakingRewards(msg.sender, reward);
        return true;
    }

    function verifyReward(
        uint256 reward,
        bytes32 hash,
        bytes memory signature
    )
    internal view
    returns (bool) {
        bytes32 verifyHash = keccak256(abi.encodePacked(msg.sender, reward));
        require(hash == verifyHash, "Rewarding: incorrect hash");
        return ECDSA.recover(hash, signature) == _verifyRewardAddress;
    }

}

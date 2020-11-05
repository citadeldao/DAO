// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;


contract Multisig {

    struct SigProcess {
        bytes32 data;
        uint created;
        address[] sigs;
    }

    struct SigGroup {
        uint threshold;
        mapping (address => bool) whitelist;
        address[] whitelistArr;
        mapping (bytes4 => SigProcess) processing;
    }

    mapping (bytes4 => SigGroup) private _groups;

    modifier multisig(bytes4 groupId) {
        require(_groups[groupId].whitelist[msg.sender], "Multisig: You cannot execute this method");
        _;
    }

    function multisigWhitelist(bytes4 groupId) external view multisig(groupId) returns (address[] memory){
        return _groups[groupId].whitelistArr;
    }

    function multisigWhitelistAdd(bytes4 groupId, address account) external multisig(groupId) {
        if (!_isMultisigReady(groupId)) return;
        SigGroup storage group = _groups[groupId];
        group.whitelist[account] = true;
        group.whitelistArr.push(account);
    }

    function multisigWhitelistRemove(bytes4 groupId, address account) external multisig(groupId) {
        SigGroup storage group = _groups[groupId];
        require(group.whitelistArr.length > 2, "Multisig: already minimum addresses");
        if (!_isReadyToRemove(groupId)) return;

        if (group.threshold == group.whitelistArr.length) group.threshold--;

        address[] memory replaceWhitelistArr = new address[](group.whitelistArr.length-1);

        uint n = 0;
        for (uint i = 0; i < group.whitelistArr.length; i++) {
            if (group.whitelistArr[i] == account) continue;
            replaceWhitelistArr[n] = group.whitelistArr[i];
            n++;
        }

        delete group.whitelist[account];
        group.whitelistArr = replaceWhitelistArr;
    }

    function _isMultisigReady(bytes4 groupId) internal returns (bool) {
        SigGroup storage group = _groups[groupId];
        bytes4 fn = msg.sig;
        bytes32 data = keccak256(msg.data);

        if (group.processing[fn].created > 0) {
            if (group.processing[fn].data == data) {
                // check repeating
                for (uint i = 0; i < group.processing[fn].sigs.length; i++) {
                    if (group.processing[fn].sigs[i] == msg.sender) {
                        return false;
                    }
                }
                // put your sig
                group.processing[fn].sigs.push(msg.sender);
            } else {
                group.processing[fn].data = data;
                group.processing[fn].created = block.timestamp;
                delete group.processing[fn].sigs;
                group.processing[fn].sigs.push(msg.sender);
            }
        } else {
            group.processing[fn].data = data;
            group.processing[fn].created = block.timestamp;
            group.processing[fn].sigs.push(msg.sender);
        }

        if (group.processing[fn].sigs.length >= group.threshold) {
            delete group.processing[fn];
            return true;
        } else {
            return false;
        }
    }

    function _initMultisigWhitelist(bytes4 groupId, address[] memory wallets, uint threshold_) internal {
        SigGroup storage group = _groups[groupId];
        require(group.threshold == 0, "Multisig: whitelist already initialized");
        require(threshold_ <= wallets.length && threshold_ > 1, "Multisig: invalid init threshold");
        group.threshold = threshold_;
        for (uint i = 0; i < wallets.length; i++) {
            group.whitelist[wallets[i]] = true;
            group.whitelistArr.push(wallets[i]);
        }
    }

    function _isReadyToRemove(bytes4 groupId) private returns (bool) {
        SigGroup storage group = _groups[groupId];
        uint threshold = group.threshold;
        if (threshold == group.whitelistArr.length) threshold--;
        bytes4 fn = msg.sig;
        bytes32 data = keccak256(msg.data);

        if (group.processing[fn].created > 0) {
            if (group.processing[fn].data == data) {
                // check repeating
                for (uint i = 0; i < group.processing[fn].sigs.length; i++) {
                    if (group.processing[fn].sigs[i] == msg.sender) {
                        return false;
                    }
                }
                // put your sig
                group.processing[fn].sigs.push(msg.sender);
            } else {
                group.processing[fn].data = data;
                group.processing[fn].created = block.timestamp;
                delete group.processing[fn].sigs;
                group.processing[fn].sigs.push(msg.sender);
            }
        } else {
            group.processing[fn].data = data;
            group.processing[fn].created = block.timestamp;
            group.processing[fn].sigs.push(msg.sender);
        }

        if (group.processing[fn].sigs.length >= threshold) {
            delete group.processing[fn];
            return true;
        } else {
            return false;
        }
    }

}

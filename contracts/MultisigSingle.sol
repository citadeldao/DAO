// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;


contract MultisigSingle {

    struct SigProcess {
        uint id;
        bytes32 data;
        uint created;
        address[] sigs;
    }

    mapping (address => bool) public _whitelist;
    uint private _id;
    uint private _threshold;
    address[] private _whitelistArr;
    mapping (bytes4 => SigProcess) private _processing;

    event AddMultisigAddress(address who);
    event RemoveMultisigAddress(address who);
    event SetThreshold(uint num);

    modifier multisig() {
        require(_whitelist[msg.sender], "Multisig: You cannot execute this method");
        _;
    }

    function multisigWhitelist() external view returns (address[] memory) {
        return _whitelistArr;
    }

    function getThreshold() external view returns (uint) {
        return _threshold;
    }

    function setThreshold(uint num) external multisig() {
        require(num > 1 && num <= _whitelistArr.length, "Incorrect threshold");

        (bool isReady, ) = _isMultisigReady();
        if (!isReady) return;

        _threshold = num;
        emit SetThreshold(num);
    }

    function multisigWhitelistAdd(address account) external multisig() {
        (bool isReady, ) = _isMultisigReady();
        if (!isReady) return;

        if (_threshold == _whitelistArr.length) {
            _threshold++;
            emit SetThreshold(_threshold);
        }

        _whitelist[account] = true;
        _whitelistArr.push(account);
        emit AddMultisigAddress(account);
    }

    function multisigWhitelistRemove(address account) external multisig() {
        require(_whitelistArr.length > 2, "Multisig: already minimum addresses");
        (bool isReady, ) = _isReadyToRemove();
        if (!isReady) return;

        if (_threshold == _whitelistArr.length) {
            _threshold--;
            emit SetThreshold(_threshold);
        }

        address[] memory replaceWhitelistArr = new address[](_whitelistArr.length-1);

        uint n = 0;
        for (uint i = 0; i < _whitelistArr.length; i++) {
            if (_whitelistArr[i] == account) continue;
            replaceWhitelistArr[n] = _whitelistArr[i];
            n++;
        }

        delete _whitelist[account];
        _whitelistArr = replaceWhitelistArr;
        emit RemoveMultisigAddress(account);
    }

    function _isMultisigReady() internal returns (bool, uint) {
        bytes4 fn = msg.sig;
        bytes32 data = keccak256(msg.data);

        if (_processing[fn].created > 0) {
            if (_processing[fn].data == data) {
                // check repeating
                for (uint i = 0; i < _processing[fn].sigs.length; i++) {
                    if (_processing[fn].sigs[i] == msg.sender) {
                        uint id = _processing[fn].id;
                        return (false, id);
                    }
                }
                // put your sig
                _processing[fn].sigs.push(msg.sender);
            } else {
                _id++;
                _processing[fn].id = _id;
                _processing[fn].data = data;
                _processing[fn].created = block.timestamp;
                delete _processing[fn].sigs;
                _processing[fn].sigs.push(msg.sender);
            }
        } else {
            _id++;
            _processing[fn].id = _id;
            _processing[fn].data = data;
            _processing[fn].created = block.timestamp;
            _processing[fn].sigs.push(msg.sender);
        }

        uint id = _processing[fn].id;

        if (_processing[fn].sigs.length >= _threshold) {    
            delete _processing[fn];
            return (true, id);
        } else {
            return (false, id);
        }
    }

    function _initMultisigWhitelist(address[] memory wallets, uint threshold_) internal {
        require(_threshold == 0, "Multisig: whitelist already initialized");
        require(threshold_ <= wallets.length && threshold_ > 1, "Multisig: invalid init threshold");
        _threshold = threshold_;
        emit SetThreshold(_threshold);
        for (uint i = 0; i < wallets.length; i++) {
            _whitelist[wallets[i]] = true;
            _whitelistArr.push(wallets[i]);
            emit AddMultisigAddress(wallets[i]);
        }
    }

    function _isReadyToRemove() private returns (bool, uint) {
        uint threshold = _threshold;
        if (threshold == _whitelistArr.length) threshold--;
        bytes4 fn = msg.sig;
        bytes32 data = keccak256(msg.data);

        if (_processing[fn].created > 0) {
            if (_processing[fn].data == data) {
                // check repeating
                for (uint i = 0; i < _processing[fn].sigs.length; i++) {
                    if (_processing[fn].sigs[i] == msg.sender) {
                        uint id = _processing[fn].id;
                        return (false, id);
                    }
                }
                // put your sig
                _processing[fn].sigs.push(msg.sender);
            } else {
                _id++;
                _processing[fn].id = _id;
                _processing[fn].data = data;
                _processing[fn].created = block.timestamp;
                delete _processing[fn].sigs;
                _processing[fn].sigs.push(msg.sender);
            }
        } else {
            _id++;
            _processing[fn].id = _id;
            _processing[fn].data = data;
            _processing[fn].created = block.timestamp;
            _processing[fn].sigs.push(msg.sender);
        }

        uint id = _processing[fn].id;

        if (_processing[fn].sigs.length >= threshold) {
            delete _processing[fn];
            return (true, id);
        } else {
            return (false, id);
        }
    }

}

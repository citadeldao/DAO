// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "../../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/utils/Pausable.sol";
import "../ICitadelVesting.sol";
import "../ICitadelDao.sol";


contract CitadelToken is ERC20("Citadel.one", "XCT"), Ownable, Pausable {

    address public _bankAddress;
    uint public deployDate;
    uint public percentDecimal;

    ICitadelVesting internal _Vesting;
    ICitadelDao internal _dao;
    address constant internal addressForDelegations = address(10);
    mapping (address => uint) private _delegated;

    modifier onlyVestingContract() {
        require(msg.sender == address(_Vesting));
        _;
    }

    modifier onlyDaoContract() {
        require(msg.sender == address(_dao));
        _;
    }

    modifier onlyVestingOrDaoContracts() {
        require(msg.sender == address(_Vesting) || msg.sender == address(_dao));
        _;
    }

    constructor () public {

        _bankAddress = address(this);
        deployDate = block.timestamp;
        percentDecimal = 1e15;

        _setupDecimals(6);

    }

    function deployed() external view returns (uint) {
        return deployDate;
    }

    function burn(uint amount) external {
        require(uint(msg.sender) > 1000, "CitadelToken: fake sender");
        require(balanceOf(msg.sender) >= amount, "CitadelToken: insufficient balance");
        _burn(msg.sender, amount);
    }

    function initVestingTransport(address vestAddress) external onlyOwner {
        _Vesting = ICitadelVesting(vestAddress);
    }

    function getVestingAddress() external view returns (address) {
        return address(_Vesting);
    }

    function initDaoTransport(address daoAddress) external onlyOwner {
        _dao = ICitadelDao(daoAddress);
    }

    function getDaoAddress() external view returns (address) {
        return address(_dao);
    }

    function delegateToDAO(address from, uint amount) external onlyDaoContract {
        _transfer(from, addressForDelegations, amount);
        _delegated[from] = _delegated[from].add(amount);
    }

    function redeemFromDAO(address to, uint amount) external onlyDaoContract {
        _transfer(addressForDelegations, to, amount);
        _delegated[to] = _delegated[to].sub(amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(uint(msg.sender) > 1000, "CitadelToken: fake sender");
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function _timestamp() internal virtual view returns (uint) {
        return block.timestamp;
    }

}

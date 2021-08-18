const fs = require('fs');

const Citadel = artifacts.require("Citadel");
const CitadelUnlockTeam = artifacts.require("CitadelUnlockTeam");
const CitadelUnlockAdvisors = artifacts.require("CitadelUnlockAdvisors");
const CitadelUnlockPrivate1 = artifacts.require("CitadelUnlockPrivate1");
const CitadelUnlockPrivate2 = artifacts.require("CitadelUnlockPrivate2");
const CitadelUnlockEcoFund = artifacts.require("CitadelUnlockEcoFund");
const CitadelUnlockFoundFund = artifacts.require("CitadelUnlockFoundFund");
const CitadelUnlockCommFund = artifacts.require("CitadelUnlockCommFund");
const CitadelDao = artifacts.require("CitadelDao");
const CitadelRewards = artifacts.require("CitadelRewards");

function loadPrivateList (file) {
    let list = fs.readFileSync(file).toString().trim();
    let wallets = [];
    let amount = [];
    list.split('\n').forEach(row => {
        row = row.replace(/[\t]+/g, '\t').split('\t');
        wallets.push(row[0].replace(/[\s]+/g, ''));
        if (row[1]) amount.push(parseInt(row[1].replace(/[\s]+/g, '')) * 1e6);
    });
    list = null;
    return { wallets, amount };
}

const multisigAddress = '0xc318c3124dFf3523b5A88B3c9223418a33F80634';

module.exports = async function(deployer) {

    var TokenInstance,
        tokenDeployed,
        CitadelUnlockTeamInstance,
        CitadelUnlockAdvisorsInstance,
        CitadelUnlockPrivate1Instance,
        CitadelUnlockPrivate2Instance,
        CitadelUnlockEcoFundInstance,
        CitadelUnlockFoundFundInstance,
        CitadelUnlockCommFundInstance,
        DaoInstance,
        VestingInstance;

    deployer.deploy(
        Citadel
    ).then(async function(instance){

        TokenInstance = instance;

        tokenDeployed = (await TokenInstance.deployed.call()).toNumber();

        const { wallets, amount } = loadPrivateList('.team.list');

        return deployer.deploy(
            CitadelUnlockTeam,
            TokenInstance.address,
            wallets,
            amount,
            0
        );

    }).then(async function(instance){

        CitadelUnlockTeamInstance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockTeamInstance.address,
            147_250_000 * 1e6
        );

        const { wallets, amount } = loadPrivateList('.advisors.list');

        return deployer.deploy(
            CitadelUnlockAdvisors,
            TokenInstance.address,
            wallets,
            amount,
            0
        );

    }).then(async function(instance){

        CitadelUnlockAdvisorsInstance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockAdvisorsInstance.address,
            2_750_000 * 1e6
        );

        const { wallets, amount } = loadPrivateList('.private1.list');

        return deployer.deploy(
            CitadelUnlockPrivate1,
            TokenInstance.address,
            wallets,
            amount,
            0
        );

    }).then(async function(instance){

        CitadelUnlockPrivate1Instance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockPrivate1Instance.address,
            2_500_000 * 1e6
        );

        const { wallets, amount } = loadPrivateList('.private2.list');

        return deployer.deploy(
            CitadelUnlockPrivate2,
            TokenInstance.address,
            wallets,
            amount,
            0
        );

    }).then(async function(instance){

        CitadelUnlockPrivate2Instance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockPrivate2Instance.address,
            48_333_335 * 1e6
        );

        const { wallets } = loadPrivateList('.ecofund.list');

        return deployer.deploy(
            CitadelUnlockEcoFund,
            196_666_667 * 1e6,
            TokenInstance.address,
            wallets,
            3, // threshold
            0
        );

    }).then(async function(instance){

        CitadelUnlockEcoFundInstance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockEcoFundInstance.address,
            196_666_667 * 1e6
        );

        const { wallets } = loadPrivateList('.foundfund.list');

        return deployer.deploy(
            CitadelUnlockFoundFund,
            40_000_000 * 1e6,
            TokenInstance.address,
            wallets,
            3, // threshold
            0
        );

    }).then(async function(instance){

        CitadelUnlockFoundFundInstance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockFoundFundInstance.address,
            40_000_000 * 1e6
        );

        const { wallets } = loadPrivateList('.commfund.list');

        return deployer.deploy(
            CitadelUnlockCommFund,
            50_000_000 * 1e6,
            TokenInstance.address,
            wallets,
            3, // threshold
            0
        );

    }).then(async function(instance){

        CitadelUnlockCommFundInstance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockCommFundInstance.address,
            50_000_000 * 1e6
        );

        return deployer.deploy(
            CitadelDao,
            TokenInstance.address
        );
    }).then(async function(instance){
        DaoInstance = instance;

        await TokenInstance.initDaoTransport.sendTransaction(DaoInstance.address);

        return deployer.deploy(
            CitadelRewards,
            TokenInstance.address
        );
    }).then(async function(instance){
        VestingInstance = instance;

        await TokenInstance.initVestingTransport.sendTransaction(VestingInstance.address);

        await TokenInstance.transferOwnership.sendTransaction(multisigAddress);
        await DaoInstance.transferOwnership.sendTransaction(multisigAddress);
        
    });

};

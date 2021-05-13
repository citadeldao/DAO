const Citadel = artifacts.require("Citadel");
const CitadelUnlockTeam = artifacts.require("CitadelUnlockTeam");
const CitadelUnlockAdvisors = artifacts.require("CitadelUnlockAdvisors");
const CitadelUnlockPrivate1 = artifacts.require("CitadelUnlockPrivate1");
const CitadelUnlockPrivate2 = artifacts.require("CitadelUnlockPrivate2");
const CitadelUnlockEcoFund = artifacts.require("CitadelUnlockEcoFund");
const CitadelDao = artifacts.require("CitadelDao");
const CitadelVesting = artifacts.require("CitadelVesting");

// https://feeds.chain.link/usdt-eth
// oracul: https://etherscan.io/address/0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46

module.exports = async function(deployer) {

    var TokenInstance,
        tokenDeployed,
        CitadelUnlockTeamInstance,
        CitadelUnlockAdvisorsInstance,
        CitadelUnlockPrivate1Instance,
        CitadelUnlockPrivate2Instance,
        CitadelUnlockEcoFundInstance,
        DaoInstance,
        VestingInstance;

    deployer.deploy(
        Citadel,
        [ // multisigs
            {
                id: web3.utils.toHex('FF'),
                whitelist: [
                    '0x5386d64023dde8e391f8bce92b5cd5bff31413ef',
                    '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61'
                ],
                threshold: 2
            },
            {
                id: web3.utils.toHex('CF'),
                whitelist: [
                    '0x5386d64023dde8e391f8bce92b5cd5bff31413ef',
                    '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61'
                ],
                threshold: 2
            }
        ],
        1000000000, // initialSupply
    ).then(async function(instance){

        TokenInstance = instance;

        tokenDeployed = (await TokenInstance.deployed.call()).toNumber();

        return deployer.deploy(
            CitadelUnlockTeam,
            TokenInstance.address,
            [
                '0x5386d64023dde8e391f8bce92b5cd5bff31413ef',
                '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61',
            ],
            [
                100_000_000 * 1e6,
                 47_250_000 * 1e6,
            ],
            tokenDeployed + 10000 // all actions like after 10.000 sec
        );

    }).then(async function(instance){

        CitadelUnlockTeamInstance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockTeamInstance.address,
            147_250_000 * 1e6
        );

        return deployer.deploy(
            CitadelUnlockAdvisors,
            TokenInstance.address,
            [
                '0x5386d64023dde8e391f8bce92b5cd5bff31413ef',
                '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61',
            ],
            [
                2_000_000 * 1e6,
                  750_000 * 1e6,
            ],
            tokenDeployed + 10000 // all actions like after 10.000 sec
        );

    }).then(async function(instance){

        CitadelUnlockAdvisorsInstance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockAdvisorsInstance.address,
            2_750_000 * 1e6
        );

        return deployer.deploy(
            CitadelUnlockPrivate1,
            TokenInstance.address,
            [
                '0x5386d64023dde8e391f8bce92b5cd5bff31413ef',
                '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61',
            ],
            [
                2_000_000 * 1e6,
                  500_000 * 1e6,
            ],
            tokenDeployed + 10000 // all actions like after 10.000 sec
        );

    }).then(async function(instance){

        CitadelUnlockPrivate1Instance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockPrivate1Instance.address,
            2_500_000 * 1e6
        );

        return deployer.deploy(
            CitadelUnlockPrivate2,
            TokenInstance.address,
            [
                '0x5386d64023dde8e391f8bce92b5cd5bff31413ef',
                '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61',
            ],
            [
                48_000_000 * 1e6,
                   333_333 * 1e6,
            ],
            tokenDeployed + 10000 // all actions like after 10.000 sec
        );

    }).then(async function(instance){

        CitadelUnlockPrivate2Instance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockPrivate2Instance.address,
            48_333_333 * 1e6
        );

        return deployer.deploy(
            CitadelUnlockEcoFund,
            196_666_667 * 1e6,
            TokenInstance.address,
            [ // Multisig addresses
                '0x5386d64023dde8e391f8bce92b5cd5bff31413ef',
                '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61',
                '0xb3dab625941bb8be74a00540ec8f94aa064ea42c'
            ],
            2, // threshold
            tokenDeployed + 3600 * 24 * 90 + 10000 // all actions like after 10.000 sec
        );

    }).then(async function(instance){

        CitadelUnlockEcoFundInstance = instance;

        await TokenInstance.delegateTokens.sendTransaction(
            CitadelUnlockEcoFundInstance.address,
            196_666_667 * 1e6
        );


    //}).then(async function(instance){

        /*await TokenInstance.setTeam.sendTransaction([
            '0x5386d64023dde8e391f8bce92b5cd5bff31413ef',
            '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61',
        ], [
            90000000 * 1e6,
            60000000 * 1e6,
        ]);

        await TokenInstance.setInvestors.sendTransaction([
            '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61',
        ], [
            100000000 * 1e6
        ]);*/

        return deployer.deploy(
            CitadelDao,
            TokenInstance.address
        );
    }).then(async function(instance){
        DaoInstance = instance;

        await TokenInstance.initDaoTransport.sendTransaction(DaoInstance.address);

        return deployer.deploy(
            CitadelVesting,
            TokenInstance.address,
            true
        );
    }).then(async function(instance){
        VestingInstance = instance;

        await TokenInstance.initVestingTransport.sendTransaction(VestingInstance.address);

        await VestingInstance.renounceOwnership.sendTransaction();

    });

};

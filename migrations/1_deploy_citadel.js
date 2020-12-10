const Citadel = artifacts.require("Citadel");
const CitadelDao = artifacts.require("CitadelDao");
const CitadelVesting = artifacts.require("CitadelVesting");

// https://feeds.chain.link/usdt-eth
// oracul: https://etherscan.io/address/0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46

module.exports = async function(deployer) {

    var TokenInstance, DaoInstance, VestingInstance;

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
        10000000, // rate eth2token
        45000, // buyer limit
        [ // team unlock
            10,
            35,
            65,
            100
        ],
        [ // private unlock
            15,
            35,
            65,
            100
        ]
    ).then(async function(instance){
        TokenInstance = instance;

        await TokenInstance.setTeam.sendTransaction([
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
        ]);

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

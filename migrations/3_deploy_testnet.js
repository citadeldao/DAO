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
                    '0x40DC494150fE934641B68ce20E46f1dA760647BA',
                    '0xeF9E16532fEE341B8eB097D649F09989Df147f80',
                    '0xA686aDDf84C135E078C7C917ba20b2d0A7373751',
                    '0x2914c84072bc0c7b89aacf00cd55728f94076d45',
                    '0xA400E04Ba69E9Aa15834DD876855bC52Ca502ef2', // me
                ],
                threshold: 2
            },
            {
                id: web3.utils.toHex('CF'),
                whitelist: [
                    '0x40DC494150fE934641B68ce20E46f1dA760647BA',
                    '0xeF9E16532fEE341B8eB097D649F09989Df147f80',
                    '0xA686aDDf84C135E078C7C917ba20b2d0A7373751',
                    '0x2914c84072bc0c7b89aacf00cd55728f94076d45',
                    '0xA400E04Ba69E9Aa15834DD876855bC52Ca502ef2', // me
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
            '0x40DC494150fE934641B68ce20E46f1dA760647BA',
            '0xeF9E16532fEE341B8eB097D649F09989Df147f80',
            '0xA686aDDf84C135E078C7C917ba20b2d0A7373751',
            '0x2914c84072bc0c7b89aacf00cd55728f94076d45',
            '0xA400E04Ba69E9Aa15834DD876855bC52Ca502ef2', // me
        ], [
            60000000 * 1e6,
            30000000 * 1e6,
            30000000 * 1e6,
            15000000 * 1e6,
            15000000 * 1e6,
        ]);

        await TokenInstance.setInvestors.sendTransaction([
            '0x692d690091bfa17d7c3d688413b8f34c474a757c',
            '0xf8fea3b5fcb8ebf7f33032d9aa1f953cde52aeb9'
        ], [
            50000000 * 1e6,
            50000000 * 1e6,
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
            false
        );
    }).then(async function(instance){
        VestingInstance = instance;

        await TokenInstance.initVestingTransport.sendTransaction(VestingInstance.address);
        await VestingInstance.renounceOwnership.sendTransaction();
    });

};
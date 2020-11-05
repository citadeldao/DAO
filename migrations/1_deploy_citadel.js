const Citadel = artifacts.require("Citadel");

// https://feeds.chain.link/usdt-eth
// oracul: https://etherscan.io/address/0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46

module.exports = async function(deployer) {
    await deployer.deploy(
        Citadel, // contract
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
        150000000, // initialSupply
        10, // rate eth2token
        45000, // buyer limit
        3600,//60 * 60 * 24 * 365 * 4, // initialUnbondingPeriod
        1,//60 * 60 * 24, // initialUnbondingPeriod
        [ // _payees
            '0x5386d64023dde8e391f8bce92b5cd5bff31413ef',
            '0x10372ec71a29a5fe011ca0eb154f36ee27bbbc61'
        ],
        [ // _shares
            50,
            50
        ]);
};

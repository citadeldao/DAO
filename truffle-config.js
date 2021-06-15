const HDWalletProvider = require('@truffle/hdwallet-provider');
const fs = require('fs');
const mnemonic = fs.readFileSync('.secret').toString().trim();

module.exports = {
  plugins: [
    'truffle-plugin-verify'
  ],
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      gas: 12721975
    },
    rinkeby: {
      host: 'localhost',
      port: 8888,
      network_id: '4', // Rinkeby ID 4
      from: '0xF83B25aeC2360265Fb77C76ED0982AD6cE924FEB', // account from which to deploy
      gas: 6712390
    },
    testnet: {
      provider: () => new HDWalletProvider({
        mnemonic,
        addressIndex: 0,
        providerOrUrl: 'https://data-seed-prebsc-1-s1.binance.org:8545',
        chainId: 97,
      }),
      //provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      //from: "0x80928d7cfddf14bf2fb54ffde20fd52ddcde76f9",
      network_id: 97,
      confirmations: 3,
      timeoutBlocks: 1000,
      skipDryRun: true
    },
    bsc: {
      provider: () => new HDWalletProvider(mnemonic, 'https://bsc-dataseed1.binance.org'),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: false
    },
  },
  compilers: {
    solc: {
      version: '0.6.2',
      settings: {
        optimizer: {
          enabled: true, // Default: false
          runs: 200      // Default: 200
        },
      }
    }
  }
};

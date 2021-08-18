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
      gas: 12721975,
      gasPrice: 10000000000
    },
    testnet: {
      provider: () => new HDWalletProvider({
        mnemonic,
        addressIndex: 0,
        numberOfAddresses: 1,
        providerOrUrl: 'https://data-seed-prebsc-1-s1.binance.org:8545',
        chainId: 97,
      }),
      network_id: 97,
      confirmations: 3,
      timeoutBlocks: 1000,
      skipDryRun: true,
      gasPrice: 10000000000
    },
    bsc: {
      provider: () => new HDWalletProvider({
        mnemonic,
        addressIndex: 56,
        numberOfAddresses: 1,
        providerOrUrl: 'https://bsc-dataseed1.binance.org',
        chainId: 56,
      }),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: false,
      gasPrice: 10000000000
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

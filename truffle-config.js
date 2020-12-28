module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 6721975
    },
    rinkeby: {
      host: "localhost",
      port: 8888,
      network_id: "4", // Rinkeby ID 4
      from: "0xF83B25aeC2360265Fb77C76ED0982AD6cE924FEB", // account from which to deploy
      gas: 6712390
    }
  },
  compilers: {
    solc: {
      version: "0.6.2",
      settings: {
        optimizer: {
          enabled: true, // Default: false
          runs: 200      // Default: 200
        },
      }
    }
  }
};

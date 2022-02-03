var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "dance vivid girl fiscal mobile bright raise sheriff tunnel reform famous winter";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '5777'
    }
  },
  compilers: {
    solc: {
      version: "^0.8.0"
    }
  }
};
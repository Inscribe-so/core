const HDWalletProvider = require("@truffle/hdwallet-provider");
require('dotenv').config()

module.exports = {
  plugins: [
    'truffle-plugin-verify'
  ],

  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  },

  mocha: {
    reporter: 'eth-gas-reporter',
    reporterOptions : { 
      currency: 'USD',
      coinmarketcap: `${process.env.CMC_API_KEY}`,
      excludeContracts: ['Migrations']
     }
  },

  networks: {
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(
          `${process.env.INSCRIBE_RINKEBY_PRIVATE_KEY}`, 
          `https://rinkeby.infura.io/v3/${process.env.INFURA_ID}`)
      },
      network_id: 4
    },
    matic: {
      provider: function() {
        return new HDWalletProvider(
          `${process.env.INSCRIBE_RINKEBY_PRIVATE_KEY}`, 
          `https://rpc-mumbai.matic.today`)
      },
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },

  compilers: {
    solc: {
      version: "0.8.0"
    }
  }
};

const PrivateKeyProvider = require('truffle-privatekey-provider');
const path = require("path");

require('dotenv').config()

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    develop: {
      port: 8545
    },
    ganache: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
    },
    rinkeby: {
        provider: () => new PrivateKeyProvider(process.env.PKEY, process.env.RPC_URL),
        network_id: 4,
        networkCheckTimeout: 1000000000,
        timeoutBlocks: 9000,
        skipDryRun: true
    },
    mainnet: {
        provider: () => new PrivateKeyProvider(process.env.MAINNET_PKEY, process.env.MAINNET_URL),
        network_id: 1,
        networkCheckTimeout: 1000000000,
      timeoutBlocks: 9000,
    }
  },
  compilers: {
    solc: {
      version: '0.8.0',
    },
  },
    plugins: [
        'truffle-contract-size'
    ]
};

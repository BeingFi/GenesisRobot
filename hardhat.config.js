/** @type import('hardhat/config').HardhatUserConfig */

require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');

// 2. Import your private key from your pre-funded Moonbase Alpha testing account
const { privateKey } = require('./secrets.json');

module.exports = {
  solidity: "0.8.18",
  
  networks: {
    
    arbitrum_goerli: {
      url: 'https://goerli-rollup.arbitrum.io/rpc',
      chainId: 421613, // ,
      accounts: [privateKey]
    },
    
    polygon: {
      url: 'https://polygon-rpc.com/',
      chainId: 137, // 0x89 in hex,
      accounts: [privateKey]
    }
  }
  
};

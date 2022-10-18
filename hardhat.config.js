require("@nomiclabs/hardhat-waffle");
require('dotenv').config({ path: '.env' });
require('hardhat-deploy');

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

// Prints the Celo accounts associated with the mnemonic in .env
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    defaultNetwork: "alfajores",
    networks: {
        alfajores: {
            url: "https://alfajores-forno.celo-testnet.org",
            accounts: {
                mnemonic: process.env.MNEMONIC,
                path: "m/44'/52752'/0'/0"
            },
            chainId: 44787
        },
    },
    solidity: "0.8.4",
};


/* 
TO DEPLOY
---------

npx hardhat run scripts/sample-script.js --network alfajores
*/
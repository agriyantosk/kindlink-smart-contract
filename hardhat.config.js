require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

const { PRIVATE_KEY, ALCHEMY_SEPOLIA_URL, ETHERSCAN_API_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.24",
    networks: {
        sepolia: {
            url: ALCHEMY_SEPOLIA_URL,
            accounts: [PRIVATE_KEY],
        },
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
    sourcify: {
        enabled: true,
    },
};

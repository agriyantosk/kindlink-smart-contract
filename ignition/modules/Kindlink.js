const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const KindlinkModule = buildModule("KindlinkModule", (m) => {
    const kindlink = m.contract("Kindlink");

    return { kindlink };
});

module.exports = KindlinkModule;

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const kindlinkArgument = require("../../kindlink-argument");

const KindlinkModule = buildModule("KindlinkModule", (m) => {
    const kindlink = m.contract("Kindlink", kindlinkArgument);

    return { kindlink };
});

module.exports = KindlinkModule;

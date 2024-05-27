const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const foundationArgument = require("../../foundation-argument");

const FoundationModule = buildModule("FoundationModule", (m) => {
    const foundation = m.contract("Foundation", foundationArgument);

    return { foundation };
});

module.exports = FoundationModule;

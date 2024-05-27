const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const kindlinkArgument = require("../kindlink-argument");
const { ethers } = require("hardhat");

describe("Kindlink", function () {
    async function contractDeployment() {
        const [owner, otherAccount] = await ethers.getSigners();

        const Kindlink = await ethers.getContractFactory("Kindlink");
        const kindlink = await Kindlink.deploy();
        await kindlink.deployed();

        return { kindlink, owner, otherAccount };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { kindlink, owner } = await contractDeployment();

            expect(await kindlink.owner()).to.equal(owner.address);
        });
    });
});

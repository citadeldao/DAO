const BN = require('bignumber.js');
const Citadel = artifacts.require("Citadel");
const CitadelUnlockAdvisors = artifacts.require("CitadelUnlockAdvisors");

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const tokenMultiplier = 1e6;
const totalSupply = 2_750_000 * tokenMultiplier;

let deployedDate = 0;

return;

contract('CitadelUnlockAdvisors', function(accounts){

    it("Balance of CitadelUnlockAdvisors", async function() {
        const instance = await Citadel.deployed();
        deployedDate = (await instance.deployed.call()).toNumber();
        assert.equal(
            (await instance.balanceOf.call(CitadelUnlockAdvisors.address)).toNumber(),
            totalSupply
        )
    })

    it("Unlocked amount (immediately)", async function() {
        const date = deployedDate;
        const instance = await CitadelUnlockAdvisors.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            0
        )
    })

    it("Unlocked amount (60 days)", async function() {
        const date = deployedDate + 3600 * 24 * 60;
        const instance = await CitadelUnlockAdvisors.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            113_013.3125 * tokenMultiplier
        )
    })

    it("Unlocked amount (1 year)", async function() {
        const date = deployedDate + 3600 * 24 * 365;
        const instance = await CitadelUnlockAdvisors.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            687_500 * tokenMultiplier
        )
    })

    it("Unlocked amount (2 years)", async function() {
        const date = deployedDate + 3600 * 24 * 365 * 2;
        const instance = await CitadelUnlockAdvisors.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            1_375_000 * tokenMultiplier
        )
    })

    it("Unlocked amount (3 years)", async function() {
        const date = deployedDate + 3600 * 24 * 365 * 3;
        const instance = await CitadelUnlockAdvisors.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            2_062_500 * tokenMultiplier
        )
    })

    it("Unlocked amount (4 years)", async function() {
        const date = deployedDate + 3600 * 24 * 365 * 4;
        const instance = await CitadelUnlockAdvisors.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            totalSupply
        )
    })

    it("Unlocked amount (5 years)", async function() {
        const date = deployedDate + 3600 * 24 * 365 * 5;
        const instance = await CitadelUnlockAdvisors.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            totalSupply
        )
    })

    it("Unlocked amount (10k sec preset time for zero address)", async function() {
        const instance = await CitadelUnlockAdvisors.deployed();
        assert.equal(
            (await instance.calcUnlockOf.call(accounts[0])).toNumber(),
            158.5 * tokenMultiplier
        )
    })

    it("Claim unlocked amount", async function() {
        const tokenInstance = await Citadel.deployed();
        const instance = await CitadelUnlockAdvisors.deployed();
        let balance = (await tokenInstance.balanceOf.call(accounts[0])).toNumber();
        await instance.claim.sendTransaction();
        balance = (await tokenInstance.balanceOf.call(accounts[0])).toNumber() - balance;
        assert.equal(
            balance,
            158.5 * tokenMultiplier
        )
    })

    it("Post-claim unlocked amount", async function() {
        const instance = await CitadelUnlockAdvisors.deployed();
        assert.equal(
            (await instance.calcUnlockOf.call(accounts[0])).toNumber(),
            0
        )
    })

    it("Decreased balance of CitadelUnlockAdvisors", async function() {
        const instance = await Citadel.deployed();
        deployedDate = (await instance.deployed.call()).toNumber();
        assert.equal(
            (await instance.balanceOf.call(CitadelUnlockAdvisors.address)).toNumber(),
            totalSupply - 158.5 * tokenMultiplier
        )
    })

})
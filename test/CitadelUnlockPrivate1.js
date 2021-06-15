const Citadel = artifacts.require('CitadelTest');
const CitadelUnlockPrivate1 = artifacts.require('CitadelUnlockPrivate1');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const tokenMultiplier = 1e6;
const totalSupply = 2_500_000 * tokenMultiplier;

let deployedDate = 0;

contract('CitadelUnlockPrivate1', function(accounts){

    it('Balance of CitadelUnlockPrivate1', async function() {
        const instance = await Citadel.deployed();
        deployedDate = (await instance.deployed.call()).toNumber();
        assert.equal(
            (await instance.balanceOf.call(CitadelUnlockPrivate1.address)).toNumber(),
            totalSupply
        )
    })

    it('Unlocked amount (immediately)', async function() {
        const date = deployedDate;
        const instance = await CitadelUnlockPrivate1.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            0
        )
    })

    it('Unlocked amount (60 days)', async function() {
        const date = deployedDate + 3600 * 24 * 60;
        const instance = await CitadelUnlockPrivate1.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            136_986.301369 * tokenMultiplier
        )
    })

    it('Unlocked amount (1 year)', async function() {
        const date = deployedDate + 3600 * 24 * 365;
        const instance = await CitadelUnlockPrivate1.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            833_333.333333 * tokenMultiplier
        )
    })

    it('Unlocked amount (2 years)', async function() {
        const date = deployedDate + 3600 * 24 * 365 * 2;
        const instance = await CitadelUnlockPrivate1.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            1_666_666.666666 * tokenMultiplier
        )
    })

    it('Unlocked amount (3 years)', async function() {
        const date = deployedDate + 3600 * 24 * 365 * 4;
        const instance = await CitadelUnlockPrivate1.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            totalSupply
        )
    })

    it('Unlocked amount (4 years)', async function() {
        const date = deployedDate + 3600 * 24 * 365 * 5;
        const instance = await CitadelUnlockPrivate1.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            totalSupply
        )
    })

    it('Unlocked amount (10k sec preset time for zero address)', async function() {
        const instance = await CitadelUnlockPrivate1.deployed();
        assert.equal(
            (await instance.calcUnlockOf.call(accounts[0])).toNumber(),
            211.398613 * tokenMultiplier
        )
    })

    it('Claim unlocked amount', async function() {
        const tokenInstance = await Citadel.deployed();
        const instance = await CitadelUnlockPrivate1.deployed();
        let balance = (await tokenInstance.balanceOf.call(accounts[0])).toNumber();
        await instance.claim.sendTransaction();
        balance = (await tokenInstance.balanceOf.call(accounts[0])).toNumber() - balance;
        assert.equal(
            balance,
            211.398613 * tokenMultiplier
        )
    })

    it('Post-claim unlocked amount', async function() {
        const instance = await CitadelUnlockPrivate1.deployed();
        assert.equal(
            (await instance.calcUnlockOf.call(accounts[0])).toNumber(),
            0
        )
    })

    it('Decreased balance of CitadelUnlockPrivate1', async function() {
        const instance = await Citadel.deployed();
        deployedDate = (await instance.deployed.call()).toNumber();
        assert.equal(
            (await instance.balanceOf.call(CitadelUnlockPrivate1.address)).toNumber(),
            totalSupply - 211.398613 * tokenMultiplier
        )
    })

})
const Citadel = artifacts.require('CitadelTest');
const CitadelUnlockPrivate2 = artifacts.require('CitadelUnlockPrivate2');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const tokenMultiplier = 1e6;
const totalSupply = 48_333_333 * tokenMultiplier;

let deployedDate = 0;

contract('CitadelUnlockPrivate2', function(accounts){

    it('Balance of CitadelUnlockPrivate2', async function() {
        const instance = await Citadel.deployed();
        deployedDate = (await instance.deployed.call()).toNumber();
        assert.equal(
            (await instance.balanceOf.call(CitadelUnlockPrivate2.address)).toNumber(),
            totalSupply
        )
    })

    it('Unlocked amount (immediately)', async function() {
        const date = deployedDate;
        const instance = await CitadelUnlockPrivate2.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            0
        )
    })

    it('Unlocked amount (60 days)', async function() {
        const date = deployedDate + 3600 * 24 * 60;
        const instance = await CitadelUnlockPrivate2.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            5_301_645.301645 * tokenMultiplier
        )
    })

    it('Unlocked amount (1 year)', async function() {
        const date = deployedDate + 3600 * 24 * 365;
        const instance = await CitadelUnlockPrivate2.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            32_251_675.585009 * tokenMultiplier
        )
    })

    it('Unlocked amount (1.5 years)', async function() {
        const date = deployedDate + 3600 * 24 * 547;
        const instance = await CitadelUnlockPrivate2.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            totalSupply
        )
    })

    it('Unlocked amount (2 years)', async function() {
        const date = deployedDate + 3600 * 24 * 365 * 2;
        const instance = await CitadelUnlockPrivate2.deployed();
        assert.equal(
            (await instance.calcUnlockOfTest.call(ZERO_ADDRESS, date)).toNumber(),
            totalSupply
        )
    })

    it('Unlocked amount (10k sec preset time for zero address)', async function() {
        const instance = await CitadelUnlockPrivate2.deployed();
        assert.equal(
            (await instance.calcUnlockOf.call(accounts[0])).toNumber(),
            10_156.408693 * tokenMultiplier
        )
    })

    it('Claim unlocked amount', async function() {
        const tokenInstance = await Citadel.deployed();
        const instance = await CitadelUnlockPrivate2.deployed();
        let balance = (await tokenInstance.balanceOf.call(accounts[0])).toNumber();
        await instance.claim.sendTransaction();
        balance = (await tokenInstance.balanceOf.call(accounts[0])).toNumber() - balance;
        assert.equal(
            balance,
            10_156.408693 * tokenMultiplier
        )
    })

    it('Post-claim unlocked amount', async function() {
        const instance = await CitadelUnlockPrivate2.deployed();
        assert.equal(
            (await instance.calcUnlockOf.call(accounts[0])).toNumber(),
            0
        )
    })

    it('Decreased balance of CitadelUnlockPrivate2', async function() {
        const instance = await Citadel.deployed();
        deployedDate = (await instance.deployed.call()).toNumber();
        assert.equal(
            (await instance.balanceOf.call(CitadelUnlockPrivate2.address)).toNumber(),
            totalSupply - 10_156.408693 * tokenMultiplier
        )
    })

})
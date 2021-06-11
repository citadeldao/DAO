const Citadel = artifacts.require('CitadelTest');
const CitadelUnlockCommFund = artifacts.require('CitadelUnlockCommFund');

const tokenMultiplier = 1e6;
const totalSupply = 50_000_000 * tokenMultiplier;

let deployedDate = 0;

contract('CitadelUnlockCommFund', function(accounts){

    it('Balance of CitadelUnlockCommFund', async function() {
        const instance = await Citadel.deployed();
        deployedDate = (await instance.deployed.call()).toNumber();
        assert.equal(
            (await instance.balanceOf.call(CitadelUnlockCommFund.address)).toNumber(),
            totalSupply
        )
    })

    it('Set budget of CitadelUnlockCommFund', async function() {
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.getBudget.call()).totalAmount.toNumber(),
            totalSupply
        )
    })

    it('Unlocked amount (immediately)', async function() {
        const date = deployedDate;
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.calcUnlockTest.call(date)).toNumber(),
            0
        )
    })

    it('Unlocked amount (60 days)', async function() {
        const date = deployedDate + 3600 * 24 * 60;
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.calcUnlockTest.call(date)).toNumber(),
            2_054_794.52 * tokenMultiplier
        )
    })

    it('Unlocked amount (1 year)', async function() {
        const date = deployedDate + 3600 * 24 * 365;
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.calcUnlockTest.call(date)).toNumber(),
            12_500_000 * tokenMultiplier
        )
    })

    it('Unlocked amount (2 years)', async function() {
        const date = deployedDate + 3600 * 24 * 365 * 2;
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.calcUnlockTest.call(date)).toNumber(),
            25_000_000 * tokenMultiplier
        )
    })

    it('Unlocked amount (3 years)', async function() {
        const date = deployedDate + 3600 * 24 * 365 * 3;
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.calcUnlockTest.call(date)).toNumber(),
            37_500_000 * tokenMultiplier
        )
    })

    it('Unlocked amount (4 years)', async function() {
        const date = deployedDate + 3600 * 24 * 365 * 4;
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.calcUnlockTest.call(date)).toNumber(),
            totalSupply
        )
    })

    it('Unlocked amount (5 years)', async function() {
        const date = deployedDate + 3600 * 24 * 365 * 5;
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.calcUnlockTest.call(date)).toNumber(),
            totalSupply
        )
    })

    const testAmount = 3_963.72375 * tokenMultiplier;

    it('Unlocked amount (10k sec preset time for zero address)', async function() {
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.calcUnlock.call()).toNumber(),
            testAmount
        )
    })

    it('Transfer unlocked amount', async function() {
        const tokenInstance = await Citadel.deployed();
        const instance = await CitadelUnlockCommFund.deployed();
        let balance = (await tokenInstance.balanceOf.call(accounts[0])).toNumber();
        await instance.transfer.sendTransaction(accounts[0], testAmount, {
            from: accounts[0]
        });
        await instance.transfer.sendTransaction(accounts[0], testAmount, {
            from: accounts[1]
        });
        balance = (await tokenInstance.balanceOf.call(accounts[0])).toNumber() - balance;
        assert.equal(
            balance,
            testAmount
        )
    })

    it('Post-claim unlocked amount', async function() {
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.calcUnlock.call()).toNumber(),
            0
        )
    })

    it('Decreased balance of CitadelUnlockCommFund', async function() {
        const instance = await Citadel.deployed();
        deployedDate = (await instance.deployed.call()).toNumber();
        assert.equal(
            (await instance.balanceOf.call(CitadelUnlockCommFund.address)).toNumber(),
            totalSupply - testAmount
        )
    })

})

contract('Multisig in CitadelUnlockCommFund', function(accounts){

    it('No access for outsiders', async function(){
        const instance = await CitadelUnlockCommFund.deployed();
        try {
            await instance.multisigWhitelistAdd.sendTransaction(accounts[3], {from: accounts[3]});
        } catch(e) {
            assert.equal(e.reason, 'Multisig: You cannot execute this method');
            return;
        }
        assert(false);
    })

    it('Length of whitelist', async function(){
        const instance = await CitadelUnlockCommFund.deployed();
        assert.equal(
            (await instance.multisigWhitelist.call()).length,
            3
        )
    })

    it('Add one more to the whitelist', async function(){
        const instance = await CitadelUnlockCommFund.deployed();

        await instance.multisigWhitelistAdd.sendTransaction(accounts[3]);
        await instance.multisigWhitelistAdd.sendTransaction(accounts[3]); // self-repeated

        if ((await instance.multisigWhitelist.call()).length == 3) {

            await instance.multisigWhitelistAdd.sendTransaction(accounts[3], {from: accounts[1]});

            assert.equal(
                (await instance.multisigWhitelist.call()).length,
                4
            )
            return;

        }
        assert(false, 'Only one signature was used');
    })

    it('Remove one from the whitelist', async function(){
        const instance = await CitadelUnlockCommFund.deployed();

        await instance.multisigWhitelistRemove.sendTransaction(accounts[3]);

        if ((await instance.multisigWhitelist.call()).length == 4) {

            await instance.multisigWhitelistRemove.sendTransaction(accounts[3], {from: accounts[1]});

            assert.equal(
                (await instance.multisigWhitelist.call()).length,
                3,
                "Account hadn't been removed"
            )

        } else {
            assert(false, 'Only one signature was used');
        }
    })

})
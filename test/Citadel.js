const Citadel = artifacts.require('CitadelTest');

const tokenMultiplier = 1e6;
const totalSupply = 1000000000 * tokenMultiplier;

contract('Citadel', function(accounts){

    it('Name', async function() {
        const instance = await Citadel.deployed();
        assert.equal(
            await instance.name.call(),
            'Citadel.one'
        )
    })

    it('Symbol', async function() {
        const instance = await Citadel.deployed();
        assert.equal(
            await instance.symbol.call(),
            'XCT'
        )
    })

    it('Total supply', async function() {
        const instance = await Citadel.deployed();
        assert.equal(
            (await instance.totalSupply.call()).toNumber(),
            totalSupply
        )
    })

})

contract('ERC20 methods', function(accounts){

    it('Transfer', async function() {

        const instance = await Citadel.deployed();

        await new Promise(_ => setTimeout(_, 3000));
        await instance.delegateTokens.sendTransaction(accounts[0], 100);

        const value = 10;

        let reciever_balance_before = (await instance.balanceOf.call(accounts[2])).toNumber();

        await instance.transfer.sendTransaction(accounts[2], value);

        let reciever_balance_after = (await instance.balanceOf.call(accounts[2])).toNumber();

        assert.equal(
            reciever_balance_after,
            reciever_balance_before + value
        );

    });

    it('Burn', async function() {

        const instance = await Citadel.deployed();

        const value = 10;

        let balance_before = (await instance.balanceOf.call(accounts[0])).toNumber();

        await instance.burn.sendTransaction(value);

        let balance_after = (await instance.balanceOf.call(accounts[0])).toNumber();

        assert.equal(
            balance_after,
            balance_before - value
        );

    });

    it('Approve', async function() {

        const instance = await Citadel.deployed();

        const value = 100000000;

        await web3.eth.sendTransaction({
            ...(await instance.approve.request(accounts[2], value)),
            from: accounts[1],
            to: Citadel.address
        })

        assert.equal(
            (await instance.allowance.call(accounts[1], accounts[2])).toNumber(),
            value
        );

    });

})

contract('CitadelInflation', function(accounts){

    it('Number points of history', async function(){
        const instance = await Citadel.deployed();
        assert.equal(
            (await instance.countInflationPoints.call()).length,
            1
        )
    })

    it('Check point in history', async function(){
        const instance = await Citadel.deployed();
        const point = await instance.inflationPoint.call(0);

        assert.equal(
            point.inflationPct,
            '800',
            'inflationPct'
        )

        assert.equal(
            point.stakingPct,
            '40',
            'stakingPct'
        )
    })

})

contract('CitadelTokenLocker', function(accounts){

    it('Activating inflation', async function(){
        const instance = await Citadel.deployed();

        const deployed = (await instance.deployed.call()).toNumber();
        await instance.setTimestamp.sendTransaction(deployed + 1000);

        await instance.startInflation.sendTransaction();
        const checkTime = await instance.getInflationStartDate.call();

        assert.equal(
            checkTime,
            deployed + 1000
        )
    })

    it('Stake', async function() {
        const instance = await Citadel.deployed();
        await instance.delegateTokens.sendTransaction(accounts[0], 1000);

        await instance.stake.sendTransaction(10);

        assert.equal(
            (await instance.lockedBalanceOf.call(accounts[0])).toNumber(),
            10,
            'Incorrect staked amount'
        )

        assert.equal(
            (await instance.lockedSupply.call()).toNumber(),
            10,
            'Incorrect total staked sum'
        )
    })

    it('Unstake', async function() {
        const instance = await Citadel.deployed();

        await instance.unstake.sendTransaction(10);

        assert.equal(
            (await instance.lockedBalanceOf.call(accounts[0])).toNumber(),
            0,
            'Incorrect staked amount'
        )

        assert.equal(
            (await instance.lockedSupply.call()).toNumber(),
            0,
            'Incorrect total staked sum'
        )
    })

})

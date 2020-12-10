const BN = require('bignumber.js');
const Citadel = artifacts.require("Citadel");

const tokenMultiplier = 1e6;
const totalSupply = 1000000000 * tokenMultiplier;
const unbondingPeriod = 3600;//60 * 60 * 24 * 365 * 4;
const unbondingPeriodFrequency = 1;//60 * 60 * 24;
const buyerLimit = 45000 * tokenMultiplier;
const rate = 10000000;

contract('Citadel', function(accounts){

    it("Name", async function() {
        const instance = await Citadel.deployed();
        assert.equal(
            await instance.name.call(),
            "Citadel"
        )
    })

    it("Symbol", async function() {
        const instance = await Citadel.deployed();
        assert.equal(
            await instance.symbol.call(),
            "XCT"
        )
    })

    it("Total supply", async function() {
        const instance = await Citadel.deployed();
        assert.equal(
            (await instance.totalSupply.call()).toNumber(),
            totalSupply
        )
    })

})

contract('ERC20 methods', function(accounts){

    it("Transfer", async function() {

        const instance = await Citadel.deployed();

        await new Promise(_ => setTimeout(_, 3000));
        await instance.claimTeam.sendTransaction(100);

        const value = 10;

        let reciever_balance_before = (await instance.balanceOf.call(accounts[2])).toNumber();

        await instance.transfer.sendTransaction(accounts[2], value);

        let reciever_balance_after = (await instance.balanceOf.call(accounts[2])).toNumber();

        assert.equal(
            reciever_balance_after,
            reciever_balance_before + value
        );

    });

    it("Approve", async function() {

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

contract('Multisig', function(accounts){

    const idFF = web3.utils.toHex('FF');

    it("No access for outsiders", async function(){
        const instance = await Citadel.deployed();
        try {
            await instance.multisigWhitelist.call(idFF, {from: accounts[2]});
        } catch(e) {
            assert(true);
            return;
        }
        assert(false);
    })

    it("Length of whitelist", async function(){
        const instance = await Citadel.deployed();
        assert.equal(
            (await instance.multisigWhitelist.call(idFF)).length,
            2
        )
    })

    it("Add one more to the whitelist", async function(){
        const instance = await Citadel.deployed();

        await instance.multisigWhitelistAdd.sendTransaction(idFF, accounts[2]);
        await instance.multisigWhitelistAdd.sendTransaction(idFF, accounts[2]); // self-repeated

        try {
            await instance.multisigWhitelist.call(idFF, {from: accounts[2]});
        } catch(e) {

            await instance.multisigWhitelistAdd.sendTransaction(idFF, accounts[2], {from: accounts[1]});

            assert.equal(
                (await instance.multisigWhitelist.call(idFF, {from: accounts[2]})).length,
                3
            )
            return;

        }
        assert(false, "Only one signature was used");
    })

    it("Remove one from the whitelist", async function(){
        const instance = await Citadel.deployed();

        await instance.multisigWhitelistRemove.sendTransaction(idFF, accounts[2]);

        try {
            await instance.multisigWhitelist.call(idFF, {from: accounts[2]});

            await instance.multisigWhitelistRemove.sendTransaction(idFF, accounts[2], {from: accounts[1]});

            try {
                await instance.multisigWhitelist.call(idFF, {from: accounts[2]});
            } catch(e) {
                assert.equal(
                    (await instance.multisigWhitelist.call(idFF)).length,
                    2
                )
                return;
            }
            assert(false, "Account hadn't been removed");
        } catch(e) {
            assert(false, "Only one signature was used");
        }
    })

})

contract('CitadelInflation', function(accounts){

    it("Number points of history", async function(){
        const instance = await Citadel.deployed();
        assert.equal(
            (await instance.countInflationPoints.call()).length,
            1
        )
    })

    it("Check point in history", async function(){
        const instance = await Citadel.deployed();
        const point = await instance.inflationPoint.call(0);
        assert.equal(
            point.stakingPct.toNumber(),
            60,
            "stakingPct"
        )
        assert.equal(
            point.vestingPct.toNumber(),
            40,
            "vestingPct"
        )
        assert.equal(
            point.date.toNumber() > 0,
            true,
            "date"
        )
    })

})

contract('CitadelFoundationFund', function(accounts){

    const sysAddress = '0x0000000000000000000000000000000000000001';
    const localSupply = new BN(totalSupply).multipliedBy(5).dividedBy(100);
    const stepPrice = localSupply.dividedBy(4);

    it("Check info", async function(){
        const instance = await Citadel.deployed();
        const info = await instance.getFFInfo.call();
        assert.equal(
            info.budget.toNumber(),
            localSupply.toNumber(),
            "budget"
        );
        assert.equal(
            info.badgeUsed.toNumber(),
            0,
            "badgeUsed"
        );
        assert.equal(
            info.steps.toNumber(),
            1,
            "steps"
        );
        assert.equal(
            info.available.toNumber(),
            stepPrice.toNumber(),
            "available"
        );
    })

    it("Claim available FF sum", async function(){
        const instance = await Citadel.deployed();
        let balance = await instance.balanceOf.call(sysAddress);
        await instance.claimFF.sendTransaction();
        balance = (await instance.balanceOf.call(sysAddress)).sub(balance);
        assert.equal(
            balance.toNumber(),
            stepPrice.toNumber(),
        );
    })

    it("Claim zero FF sum", async function(){
        const instance = await Citadel.deployed();
        let balance = await instance.balanceOf.call(sysAddress);
        await instance.claimFF.sendTransaction();
        balance = (await instance.balanceOf.call(sysAddress)).sub(balance);
        assert.equal(
            balance.toNumber(),
            0,
            "balance"
        );

        const info = await instance.getFFInfo.call();
        assert.equal(
            info.badgeClaimed.toNumber(),
            stepPrice.toNumber(),
            "badgeUsed"
        );
        assert.equal(
            info.available.toNumber(),
            0,
            "available"
        );
    })

    it("transferFF", async function(){
        const instance = await Citadel.deployed();

        const targetAddress = '0x0000000000000000000000000000000000001000';
        const amount = 100;

        let balance = await instance.balanceOf.call(targetAddress);

        await instance.transferFF.sendTransaction(targetAddress, amount);

        let zerobalance = (await instance.balanceOf.call(targetAddress)).sub(balance);
        assert.equal(
            zerobalance.toNumber(),
            0,
            "Incorrect multisig!"
        );

        await instance.transferFF.sendTransaction(targetAddress, amount, {from: accounts[1]});

        balance = (await instance.balanceOf.call(targetAddress)).sub(balance);
        assert.equal(
            balance.toNumber(),
            amount
        );
    })

})

contract('CitadelCommunityFund', function(accounts){

    const sysAddress = '0x0000000000000000000000000000000000000002';
    const localSupply = new BN(totalSupply).multipliedBy(5).dividedBy(100);

    it("Check info", async function(){
        const instance = await Citadel.deployed();

        const balance = await instance.balanceOf.call(sysAddress);
        assert.equal(
            balance.toNumber(),
            localSupply.toNumber(),
            "balance"
        );

        const info = await instance.getCFInfo.call();
        assert.equal(
            info.budget.toNumber(),
            localSupply.toNumber(),
            "budget"
        );
        assert.equal(
            info.badgeUsed.toNumber(),
            0,
            "badgeUsed"
        );
    })

    it("transferCF", async function(){
        const instance = await Citadel.deployed();

        const targetAddress = '0x0000000000000000000000000000000000002000';
        const amount = 100;

        let balance = await instance.balanceOf.call(targetAddress);

        await instance.transferCF.sendTransaction(targetAddress, amount);

        let zerobalance = (await instance.balanceOf.call(targetAddress)).sub(balance);
        assert.equal(
            zerobalance.toNumber(),
            0,
            "Incorrect multisig!"
        );

        await instance.transferCF.sendTransaction(targetAddress, amount, {from: accounts[1]});

        balance = (await instance.balanceOf.call(targetAddress)).sub(balance);
        assert.equal(
            balance.toNumber(),
            amount
        );
    })

})

contract('CitadelInvestors', function(accounts){

    const teamLocalSupply = new BN(totalSupply).multipliedBy(15).dividedBy(100);
    const localLimit = 90000000 * 1e6;

    it("getTeamInfoOf", async function() {
        const instance = await Citadel.deployed();
        await new Promise(_ => setTimeout(_, 3000));
        const info = await instance.getTeamInfoOf.call(accounts[0]);
        const time = info.time.toNumber();
        let checkAvailable = teamLocalSupply.multipliedBy(10).dividedBy(100); // first year
        checkAvailable = checkAvailable.multipliedBy(time).dividedBy(31536000/*1 year in seconds*/); // part of first year
        checkAvailable = checkAvailable.multipliedBy(localLimit).dividedBy(teamLocalSupply); // user's part
        assert.equal(
            parseInt(checkAvailable.minus(info.used).toNumber()),
            info.available.toString()
        );
    })

    it("claimInvestor", async function() {
        const instance = await Citadel.deployed();
        const amount = 100;
        await instance.claimTeam.sendTransaction(amount);
        assert.equal(
            (await instance.balanceOf.call(accounts[0])).toNumber(),
            amount
        );
    })

    it("getTeamInfoOf (after claim)", async function() {
        const instance = await Citadel.deployed();
        await new Promise(_ => setTimeout(_, 3000));
        const info = await instance.getTeamInfoOf.call(accounts[0]);
        const time = info.time.toNumber();
        let checkAvailable = teamLocalSupply.multipliedBy(10).dividedBy(100); // first year
        checkAvailable = checkAvailable.multipliedBy(time).dividedBy(31536000/*1 year in seconds*/); // part of first year
        checkAvailable = checkAvailable.multipliedBy(localLimit).dividedBy(teamLocalSupply); // user's part
        assert.equal(
            parseInt(checkAvailable.minus(info.used).toNumber()),
            info.available.toString()
        );
    })

})

contract('CitadelExchange', function(accounts){

    it("Buy coins via Ether", async function() {

        const value = buyerLimit * rate;
        const overpay = 10 * rate;

        const instance = await Citadel.deployed();

        assert.equal(
            (await instance.balanceOf.call(accounts[3])).toNumber(),
            0,
            "Default balance has to be empty"
        );

        await web3.eth.sendTransaction({
            from: accounts[3],
            to: Citadel.address,
            value: value + overpay,
            gas: 200000
        });

        assert.equal(
            (await instance.balanceOf.call(accounts[3])).toNumber(),
            buyerLimit,
            "Unexpected amount of tokens"
        );

        assert.equal(
            await web3.eth.getBalance(Citadel.address),
            value,
            "Unexpected balance of contract"
        );

    })

    it("Buy coins via Ether by an Investor", async function() {

        const value = buyerLimit * rate;
        const overpay = 10 * rate;

        const instance = await Citadel.deployed();

        let contractBalance = parseInt(await web3.eth.getBalance(Citadel.address));
        let accountBalance = (await instance.balanceOf.call(accounts[0])).toNumber();

        await web3.eth.sendTransaction({
            from: accounts[0],
            to: Citadel.address,
            value: value + overpay,
            gas: 200000
        });

        assert.equal(
            (await instance.balanceOf.call(accounts[0])).toNumber(),
            accountBalance + buyerLimit,
            "Unexpected amount of tokens"
        );

        assert.equal(
            await web3.eth.getBalance(Citadel.address),
            contractBalance + value,
            "Unexpected balance of contract"
        );

    })

    it("Transfer Ether with multisig", async function() {

        const targetAddress = accounts[5];
        const amount = 30;

        const instance = await Citadel.deployed();

        let balanceContract = await web3.eth.getBalance(Citadel.address);
        let balanceTarget = await web3.eth.getBalance(targetAddress);

        await instance.transferEth.sendTransaction(targetAddress, amount);

        let balanceContract2 = await web3.eth.getBalance(Citadel.address);
        let balanceTarget2 = await web3.eth.getBalance(targetAddress);

        assert.equal(
            balanceContract2,
            balanceContract,
            "balanceContract2"
        );
        assert.equal(
            balanceTarget2,
            balanceTarget,
            "balanceTarget2"
        );

        await instance.transferEth.sendTransaction(targetAddress, amount, {from: accounts[1]});

        let balanceContract3 = await web3.eth.getBalance(Citadel.address);
        let balanceTarget3 = await web3.eth.getBalance(targetAddress);

        assert.equal(
            balanceContract3,
            parseInt(balanceContract) - amount,
            "balanceContract3"
        );
        assert.equal(
            balanceTarget3,
            parseInt(balanceTarget) + amount,
            "balanceTarget3"
        );

    })

    it("Can't buy coins over limit", async function() {

        const instance = await Citadel.deployed();

        try {
            await web3.eth.sendTransaction({
                from: accounts[3],
                to: Citadel.address,
                value: 1 * rate
            });
        } catch (e) {
            assert(true);
            return;
        }

        assert(false);

    })

    it("Change rate", async function() {

        const instance = await Citadel.deployed();

        await instance.changeRate.sendTransaction(1);

        assert.equal(
            (await instance.getRate.call()).toNumber(),
            1
        );

        await instance.changeRate.sendTransaction(rate);

    })

    it("Close market", async function() {

        const instance = await Citadel.deployed();

        await instance.closeMarket.sendTransaction();

        assert.isOk(
            await instance.isClosedMarket.call()
        );

    })

    it("Free coins had been burned after closed market", async function() {

        const instance = await Citadel.deployed();
        assert.notEqual(
            await instance.totalSupply.call(),
            totalSupply
        );

    })

    it("Can't buy coins when market is closed", async function() {

        const instance = await Citadel.deployed();

        try {
            await web3.eth.sendTransaction({
                from: accounts[1],
                to: Citadel.address,
                value: 1 * rate
            });
        } catch (e) {
            assert(true);
            return;
        }

        assert(false);

    })

})

contract('CitadelTokenLocker', function(accounts){

    it("lockCoins", async function() {
        const instance = await Citadel.deployed();
        await new Promise(_ => setTimeout(_, 2000));
        await instance.claimTeam.sendTransaction(100);

        await instance.lockCoins.sendTransaction(10);
        assert.equal(
            (await instance.lockedBalanceOf.call(accounts[0])).toNumber(),
            10
        )
    })

    it("lockedSupply", async function() {
        const instance = await Citadel.deployed();
        assert.equal(
            (await instance.lockedSupply.call()).toNumber(),
            10
        )
    })

    it("unlockCoins", async function() {
        const instance = await Citadel.deployed();
        await instance.unlockCoins.sendTransaction(10);
        assert.equal(
            (await instance.lockedBalanceOf.call(accounts[0])).toNumber(),
            0
        )
        assert.equal(
            (await instance.lockedSupply.call()).toNumber(),
            0
        )
    })

})

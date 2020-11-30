const BN = require('bignumber.js');

const Citadel = artifacts.require("Citadel");
const CitadelDao = artifacts.require("CitadelDao");
const CitadelVesting = artifacts.require("CitadelVesting");

let tokenMultiplier = 1;

contract("CitadelVesting", function(accounts){

    let start = parseInt(new Date().getTime() / 1000);

    it("lock coins to get some vote power", async function(){
        // set start timestamp
        const VestingInstance = await CitadelVesting.deployed();
        // stake token
        const TokenInstance = await Citadel.deployed();

        const deployedTime = (await TokenInstance.deployed.call()).toNumber();
        start = deployedTime;
        await VestingInstance.setTestTimestamp.sendTransaction(start);

        tokenMultiplier = 10 ** (await TokenInstance.decimals.call()).toNumber();
        const sendEth = new BN(1e18);
        const boughtTokens = await TokenInstance.calculateTokensEther.call(sendEth);
        console.log(new BN(boughtTokens).dividedBy(tokenMultiplier).toNumber());
        // 10000 Eth = 1000 XCT
        // buy some coins
        await web3.eth.sendTransaction({
            from: accounts[0],
            to: Citadel.address,
            value: sendEth,
            gas: 200000
        });
        await web3.eth.sendTransaction({
            from: accounts[1],
            to: Citadel.address,
            value: sendEth.multipliedBy(4),
            gas: 200000
        });
        // do freezing coins to have some power
        await TokenInstance.lockCoins.sendTransaction(100 * tokenMultiplier);
        await TokenInstance.lockCoins.sendTransaction(400 * tokenMultiplier, {from: accounts[1]});
    })

    it("check vesting info", async function(){
        const TokenInstance = await Citadel.deployed();
        let info = await TokenInstance.getVestingInfo.call();
        assert.equal(
            info.pct.toNumber(),
            40,
            'wrong percent'
        )
    })

    it("check vesting percent", async function(){
        const VestingInstance = await CitadelVesting.deployed();
        assert.equal(
            (await VestingInstance.getVestingPct.call()).toNumber(),
            40
        )
    })

    it("check year inflation of vesting", async function(){
        const VestingInstance = await CitadelVesting.deployed();
        await VestingInstance.setTestTimestamp.sendTransaction(start + 3600 * 24); // 1 day
        assert.equal(
            (await VestingInstance.getYearVesting.call()).toNumber() / tokenMultiplier,
            24000000
        )
    })

    it("availableVestOf - period 1", async function(){
        const VestingInstance = await CitadelVesting.deployed();
        await VestingInstance.setTestTimestamp.sendTransaction(start + 7467);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '1136.53'
        )
    })

    it("availableVestOf - period 2", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(100 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 11967);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '1707.31'
        )
    })

    it("availableVestOf - period 3", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(100 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 16287);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '2176.97'
        )
    })

    it("availableVestOf - period 4", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(100 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 19817);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '2512.78'
        )
    })

    it("availableVestOf - period 5", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(100 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 27417);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '3155.43'
        )
    })

    it("availableVestOf - period 6", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(100 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 32417);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '3535.95'
        )
    })

    it("availableVestOf - period 7", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.unlockCoins.sendTransaction(50 * tokenMultiplier, {from: accounts[1]});
        await TokenInstance.lockCoins.sendTransaction(50 * tokenMultiplier);
        await VestingInstance.setTestTimestamp.sendTransaction(start + 41651);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '4590.06'
        )
    })

    it("availableVestOf - period 8", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(100 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 43997);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '4833.52'
        )
    })

    it("availableVestOf - period 9", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(100 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 46354);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '5057.74'
        )
    })

    it("availableVestOf - period 10", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.unlockCoins.sendTransaction(50 * tokenMultiplier, {from: accounts[1]});
        await TokenInstance.lockCoins.sendTransaction(50 * tokenMultiplier);
        await VestingInstance.setTestTimestamp.sendTransaction(start + 60919);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '6905.15'
        )
    })

    it("availableVestOf - period 11", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.unlockCoins.sendTransaction(200 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 69765);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '8251.58'
        )
    })

    it("availableVestOf - period 12", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(100 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 73311);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '8742.24'
        )
    })

    it("availableVestOf - period 13", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.unlockCoins.sendTransaction(100 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 78045);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '9462.78'
        )
    })

    it("availableVestOf - period 14", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(200 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 81045);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '9843.30'
        )
    })

    it("availableVestOf - period 15 (1 day)", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await TokenInstance.lockCoins.sendTransaction(200 * tokenMultiplier, {from: accounts[1]});
        await VestingInstance.setTestTimestamp.sendTransaction(start + 86400);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '10425.49'
        )
    })

    it("availableVestOf - period 16 (2 days)", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await VestingInstance.setTestTimestamp.sendTransaction(start + 172800);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount).toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '19818.84'
        )
    })

    it("availableVestOf - period 17 (182 days)", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await VestingInstance.setTestTimestamp.sendTransaction(start + 15_724_800);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount)/*.dividedBy(tokenMultiplier)*/.toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '1710621.19'
        )
    })

    it("availableVestOf - period 18 (365 days)", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await VestingInstance.setTestTimestamp.sendTransaction(start + 31_536_000);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount)/*.dividedBy(tokenMultiplier)*/.toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '3429603.58'
        )
    })

    it("availableVestOf - period 19X (second year)", async function(){
        const TokenInstance = await Citadel.deployed();
        const VestingInstance = await CitadelVesting.deployed();
        await VestingInstance.setTestTimestamp.sendTransaction(start + 31_622_400);
        let amount = await VestingInstance.availableVestOf.call(accounts[0]);
        //console.log(new BN(amount)/*.dividedBy(tokenMultiplier)*/.toNumber());
        assert.equal(
            new BN(amount).dividedBy(tokenMultiplier).toFixed(2),
            '3438057.59'
        )
    })

})

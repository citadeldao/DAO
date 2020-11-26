const BN = require('bignumber.js');

const Citadel = artifacts.require("Citadel");
const CitadelDao = artifacts.require("CitadelDao");
const CitadelVesting = artifacts.require("CitadelVesting");

let tokenMultiplier = 1;

contract("CitadelVesting", function(accounts){

    let start = new Date().getTime();

    it("lock coins to get some vote power", async function(){
        // set start timestamp
        const VestingInstance = await CitadelVesting.deployed();
        await VestingInstance.setTestTimestamp.sendTransaction(start);
        // stake token
        const TokenInstance = await Citadel.deployed();
        tokenMultiplier = 10 ** (await TokenInstance.decimals.call()).toNumber();
        const sendEth = 10000;
        const boughtTokens = await TokenInstance.calculateTokensEther.call(sendEth);
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
            value: sendEth,
            gas: 200000
        });
        // do freezing coins to have some power
        await TokenInstance.lockCoins.sendTransaction(boughtTokens);
        await TokenInstance.lockCoins.sendTransaction(boughtTokens, {from: accounts[1]});
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
        assert.equal(
            (await VestingInstance.getYearVesting.call()).toNumber() / tokenMultiplier,
            24000000
        )
    })

    it("availableVestOf", async function(){
        const VestingInstance = await CitadelVesting.deployed();
        console.log(await VestingInstance.availableVestOf.call(accounts[0]));
    })

    /*
    it("updateInflation", async function(){

    })
    */

})

const BN = require('bignumber.js');

const Citadel = artifacts.require("Citadel");
const CitadelDao = artifacts.require("CitadelDao");
const CitadelVesting = artifacts.require("CitadelVesting");

contract("CitadelVesting", function(accounts){

    it("lock coins to get some vote power", async function(){
        const TokenInstance = await Citadel.deployed();
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

    it("availableVestOf", async function(){
        const VestingInstance = await CitadelVesting.deployed();
        console.log(await VestingInstance.availableVestOf.call(accounts[0]));
    })

    /*
    it("updateInflation", async function(){

    })
    */

})

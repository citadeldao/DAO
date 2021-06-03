const BN = require('bignumber.js');

const Citadel = artifacts.require("CitadelTest");
const CitadelDao = artifacts.require("CitadelDao");
const CitadelRewards = artifacts.require("CitadelRewardsTest");

let tokenMultiplier = 10 ** 6;

function days(n){
    return n * 86400;
}

contract("CitadelVesting", function(accounts){

    let TokenInstance, RewardsInstance, deployed, time;

    async function updateTimestamp(timestamp){
        await TokenInstance.setTimestamp.sendTransaction(timestamp);
        await RewardsInstance.setTimestamp.sendTransaction(timestamp);
        return true;
    }

    it('Deposit some tokens', async function(){
        TokenInstance = await Citadel.deployed();
        deployed = time = (await TokenInstance.deployed.call()).toNumber();
        
        RewardsInstance = await CitadelRewards.deployed();
        await RewardsInstance.setTimestamp.sendTransaction(time); // sync with token

        const amount = 3_000_000 * tokenMultiplier;

        await TokenInstance.delegateTokens.sendTransaction(accounts[0], amount);

        assert.equal(
            (await TokenInstance.balanceOf.call(accounts[0])).toNumber(),
            amount,
            'Account 0'
        )

        await TokenInstance.delegateTokens.sendTransaction(accounts[1], amount);

        assert.equal(
            (await TokenInstance.balanceOf.call(accounts[1])).toNumber(),
            amount,
            'Account 1'
        )
    })

    it('Stake without activating is prohibited', async function(){
        try {
            console.log(await TokenInstance.stake.sendTransaction(500_000 * tokenMultiplier));
        } catch ({ reason }) {
            return assert.equal(reason, 'CitadelInflation: coming soon');
        }
        assert(false);
    })

    it('Activating inflation', async function(){
        time += days(30);
        await updateTimestamp(time);
        await TokenInstance.startInflation.sendTransaction();
        const checkTime = await TokenInstance.getInflationStartDate.call();
        assert.equal(
            checkTime,
            time
        )
    })

    let totalStaked0 = 0, totalStaked1 = 0;

    it('Period 1: 2021, 120 days', async function(){

        const staked0 = 500 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        const staked1 = 2_000 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        time += days(120);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        const account1 = (await RewardsInstance.claimable.call(accounts[1])).toNumber() / tokenMultiplier;
        
        assert.equal(
            account0.toFixed(2),
            (1_052_054.79).toFixed(2),
            'Account 0'
        )

        assert.equal(
            account1.toFixed(2),
            (4_208_219.18).toFixed(2),
            'Account 1'
        )

    })

    it('Period 2: 2021, 90 days', async function(){

        const staked0 = 750 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        //const staked1 = 2000 * tokenMultiplier;
        //await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        //totalStaked1 = staked1;

        time += days(90);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (2_128_019.93).toFixed(2)
        )

    })

    it('Period 3: 2021, 40 days', async function(){

        const staked0 = 1_125 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        //const staked1 = 2000 * tokenMultiplier;
        //await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        //totalStaked1 = staked1;

        time += days(40);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (2_759_252.8).toFixed(2)
        )

    })

    it('Claim 1', async function(){

        const balance0 = (await TokenInstance.balanceOf.call(accounts[0])).toNumber();
        let claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber();

        await RewardsInstance.claim.sendTransaction();

        const updatedBalance0 = (await TokenInstance.balanceOf.call(accounts[0])).toNumber();
        
        assert.equal(
            updatedBalance0 - balance0,
            claimable0,
            "Balance wasn't increased"
        )

        claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber();

        assert.equal(
            claimable0,
            0,
            "Claimable sum wasn't decreased to zero"
        )

    })

    it('Period 4: 2021, 115 days', async function(){

        const staked0 = 1_687 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        const staked1 = 3_000 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        time += days(115);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (1_814_450.35).toFixed(2)
        )

    })

    it('Period 5: 2022, 60 days', async function(){

        const staked0 = 2_530 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        const staked1 = 4_500 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        time += days(60);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (2_772_832.23).toFixed(2)
        )

    })

    it('Period 6: 2022, 30 days', async function(){

        const staked0 = 3_795 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        const staked1 = 6_750 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        time += days(30);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (3_252_023.17).toFixed(2)
        )

    })

    it('Period 7: 2022, 90 days', async function(){

        const staked0 = 1_000 * tokenMultiplier;
        await TokenInstance.unstake.sendTransaction(totalStaked0 - staked0);
        totalStaked0 = staked0;

        const staked1 = 10_125 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        time += days(90);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (3_611_081.20).toFixed(2)
        )

    })

    it('Period 8: 2022, 185 days', async function(){

        const staked1 = 15_187 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        time += days(185);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (4_118_337.57).toFixed(2)
        )

    })

    it('Period 9: 2023, 80 days', async function(){

        time += days(80);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (4_338_422.86).toFixed(2)
        )

    })

    it('Period 10: 2023, 30 days', async function(){

        const staked0 = 1_500 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        const staked1 = 22_780 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        time += days(30);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (4_420_956.54).toFixed(2)
        )

    })

    it('Change inflation up to 9%', async function(){

        await TokenInstance.setInflation.sendTransaction(900);

        const count = (await TokenInstance.countInflationPoints.call()).toNumber();
        const inflation = await TokenInstance.inflationPoint.call(count - 1);

        assert.equal(
            inflation.inflationPct,
            '900',
            'Inflation'
        )

        assert.equal(
            inflation.date,
            time.toString(),
            'Date update'
        )

    })

    it('Period 11: 2023, 120 days', async function(){

        time += days(120);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (4_845_415.48).toFixed(2)
        )

    })

    it('Claim 2', async function(){

        const balance1 = (await TokenInstance.balanceOf.call(accounts[1])).toNumber();
        let claimable1 = (await RewardsInstance.claimable.call(accounts[1])).toNumber();

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        const updatedBalance1 = (await TokenInstance.balanceOf.call(accounts[1])).toNumber();
        
        assert.equal(
            updatedBalance1 - balance1,
            claimable1,
            "Balance wasn't increased"
        )

        claimable1 = (await RewardsInstance.claimable.call(accounts[1])).toNumber();

        assert.equal(
            claimable1,
            0,
            "Claimable sum wasn't decreased to zero"
        )

    })

    it('Period 12: 2023, 135 days', async function(){

        const staked0 = 2_250 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        const staked1 = 34_170 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        time += days(135);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (5_322_931.79).toFixed(2)
        )

    })

    it('Period 13: 2024, 91 days (one holder)', async function(){

        await TokenInstance.unstake.sendTransaction(totalStaked1, { from: accounts[1] });
        totalStaked1 = 0;

        time += days(91);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (10_656_869.93).toFixed(2)
        )

    })

    it('Period 14: 2024, 152 days (no holders)', async function(){

        await TokenInstance.unstake.sendTransaction(totalStaked0);
        totalStaked0 = 0;

        time += days(152);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (10_656_869.93).toFixed(2)
        )

    })

    it('Claim 3', async function(){

        const balance0 = (await TokenInstance.balanceOf.call(accounts[0])).toNumber();
        let claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber();

        await RewardsInstance.claim.sendTransaction();

        const updatedBalance0 = (await TokenInstance.balanceOf.call(accounts[0])).toNumber();
        
        assert.equal(
            updatedBalance0 - balance0,
            claimable0,
            "Balance wasn't increased"
        )

        claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber();

        assert.equal(
            claimable0,
            0,
            "Claimable sum wasn't decreased to zero"
        )

    })

    it('Period 15: 2024, 60 days (no holders)', async function(){

        time += days(60);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (0).toFixed(2),
            'Account 0'
        )

        const account1 = (await RewardsInstance.claimable.call(accounts[1])).toNumber() / tokenMultiplier;

        assert.equal(
            account1.toFixed(2),
            (7_251_880.96).toFixed(2),
            'Account 1'
        )

    })

    it('Period 16: stake', async function(){

        const staked0 = 7_000_000 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        const account0 = (await TokenInstance.lockedBalanceOf.call(accounts[0])).toNumber() / tokenMultiplier;

        assert.equal(
            account0.toFixed(2),
            (totalStaked0 / tokenMultiplier).toFixed(2)
        )

    })

    it('Period 16: restake', async function(){

        const claimable1 = (await RewardsInstance.claimable.call(accounts[1])).toNumber();
        
        await TokenInstance.restake.sendTransaction({ from: accounts[1] });
        
        const claimable1_after = (await RewardsInstance.claimable.call(accounts[1])).toNumber();
        const account1 = (await TokenInstance.lockedBalanceOf.call(accounts[1])).toNumber();
        totalStaked1 = account1;

        assert.equal(
            claimable1_after,
            0,
            'Claimable isn\'t zero'
        )

        assert.equal(
            claimable1,
            account1,
            'Incorrect restake'
        )

    })

    it('Period 16: 2024, 30 days', async function(){

        time += days(30);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (863_681.65).toFixed(2),
            'Account 0'
        )

        const claimable1 = (await RewardsInstance.claimable.call(accounts[1])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable1.toFixed(2),
            (894_759.50).toFixed(2),
            'Account 1'
        )

    })

    it('Period 17: 2024, 32 days', async function(){

        time += days(32);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (1_784_942.07).toFixed(2),
            'Account 0'
        )

        const claimable1 = (await RewardsInstance.claimable.call(accounts[1])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable1.toFixed(2),
            (1_849_169.63).toFixed(2),
            'Account 1'
        )

    })

    it('Period 18: 2025, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (12_515_593.81).toFixed(2)
        )

    })

    it('Period 19: 2026, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (23_380_378.69).toFixed(2)
        )

    })

    it('Period 20: 2027, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (34_281_379.53).toFixed(2)
        )

    })

    it('Period 21: 2028, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (45_112_302.50).toFixed(2)
        )

    })

    it('Change inflation down to 2%', async function(){

        await TokenInstance.setInflation.sendTransaction(200);

        const count = (await TokenInstance.countInflationPoints.call()).toNumber();
        const inflation = await TokenInstance.inflationPoint.call(count - 1);

        assert.equal(
            inflation.inflationPct,
            '200',
            'Inflation'
        )

        assert.equal(
            inflation.date,
            time.toString(),
            'Date update'
        )

    })

    it('Period 22: 2029, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (48_661_512.64).toFixed(2)
        )

    })

    it('Period 23: 2030, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (52_281_706.99).toFixed(2)
        )

    })

    it('Period 24: 2031, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (55_974_305.22).toFixed(2)
        )

    })

    it('Period 25: 2032, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (59_740_755.42).toFixed(2)
        )

    })

    it('Period 26: 2033, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (63_582_534.62).toFixed(2)
        )

    })

    it('Period 27: 2034, 365 days (skip + claim)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(300);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (64_117_090.61).toFixed(2)
        )

    })

    it('Last period (out of inflation!)', async function(){

        time += days(65);
        await updateTimestamp(time);

        await RewardsInstance.claim.sendTransaction({ from: accounts[1] });

        time += days(100);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        time += days(200);
        await updateTimestamp(time);

        assert.equal(
            claimable0.toFixed(2),
            (64_117_090.61).toFixed(2)
        )

    })

    it('Double check (out of inflation!)', async function(){

        time += days(100);
        await updateTimestamp(time);

        const claimable0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        
        assert.equal(
            claimable0.toFixed(2),
            (64_117_090.61).toFixed(2)
        )

    })

    /*it('After test 1: restake', async function(){
        await TokenInstance.restake.sendTransaction();
        //await TokenInstance.restake.sendTransaction({ from: accounts[1] });

        totalStaked0 = (await TokenInstance.lockedBalanceOf.call(accounts[0])).toNumber();
        //totalStaked1 = (await TokenInstance.lockedBalanceOf.call(accounts[1])).toNumber();
        
        assert.equal(
            (totalStaked0 / tokenMultiplier).toFixed(2),
            (1_384_018.26).toFixed(2)
        )
    })*/

    /*it('Test 2: 2021, month 5-7', async function(){
        const staked0 = 1_030_410.96 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        const staked1 = 2_500_000 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        time += days(121);
        await updateTimestamp(time);

        const account0 = (await RewardsInstance.claimable.call(accounts[0])).toNumber() / tokenMultiplier;
        const account1 = (await RewardsInstance.claimable.call(accounts[1])).toNumber() / tokenMultiplier;
        
        console.log({
            account0,
            account1
        });

        assert.equal(
            account0.toFixed(2),
            '884018.26',
            'Account 0'
        )

        assert.equal(
            account1.toFixed(2),
            '4420091.32',
            'Account 1'
        )

    })*/

    return;

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
        // console.log(new BN(boughtTokens).dividedBy(tokenMultiplier).toNumber());
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

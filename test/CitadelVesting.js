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

})

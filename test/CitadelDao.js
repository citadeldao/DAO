const EthCrypto = require('eth-crypto');
const createKeccakHash = require('keccak');

const Citadel = artifacts.require('CitadelTest');
const CitadelDao = artifacts.require('CitadelDaoTest');
const CitadelRewards = artifacts.require('CitadelRewardsTest');

const ADMIN_ROLE = keccak256('ADMIN_ROLE');

const tokenMultiplier = 10 ** 6;

const ProposalUpdater = {
    Nothing: 0,
    Inflation: 1,
    Vesting: 2,
    CreateProposal: 3,
    UpdateConfig: 4,
};

function days(n){
    return n * 86400;
}

function keccak256(str){
    return createKeccakHash('keccak256').update(str).digest();
}

contract('CitadelDao', function(accounts){

    it('Version', async function(){
        const instance = await CitadelDao.deployed();
        assert.equal(
            await instance.version.call(),
            '1.0.0'
        )
    })

})

contract('CitadelDao Managing', function(accounts){

    it('Add new admin', async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[1]);
        assert.equal(
            await instance.hasRole.call(ADMIN_ROLE, accounts[1]),
            true
        )
    })

    it('Remove admin', async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[0]);
        await instance.revokeRole.sendTransaction(ADMIN_ROLE, accounts[1]);
        assert.equal(
            await instance.hasRole.call(ADMIN_ROLE, accounts[1]),
            false
        )
    })

})

contract('CitadelDao Voting', function(accounts){

    const title = 'Hello World';
    const description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';
    const quorum = 20 * 1000;
    const support = 50 * 1000 + 1;
    let TokenInstance,
        RewardsInstance,
        DaoInstance,
        totalStaked0 = 0,
        totalStaked1 = 0,
        totalStaked2 = 0,
        time = 0; // seconds

    async function updateTimestamp(timestamp){
        await TokenInstance.setTimestamp.sendTransaction(timestamp);
        await RewardsInstance.setTimestamp.sendTransaction(timestamp);
        await DaoInstance.setTimestamp.sendTransaction(timestamp);
        return true;
    }

    it('Deposit some tokens', async function(){
        TokenInstance = await Citadel.deployed();
        deployed = time = (await TokenInstance.deployed.call()).toNumber();

        RewardsInstance = await CitadelRewards.deployed();

        DaoInstance = await CitadelDao.deployed();
        
        const amount = 1_000_000 * tokenMultiplier;

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

        await TokenInstance.delegateTokens.sendTransaction(accounts[2], amount);

        assert.equal(
            (await TokenInstance.balanceOf.call(accounts[2])).toNumber(),
            amount,
            'Account 2'
        )
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

    it('Stake tokens', async function(){

        const staked0 = 500 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        assert.equal(
            (await TokenInstance.lockedBalanceOf.call(accounts[0])).toNumber(),
            totalStaked0
        );

        const staked1 = 2_000 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        const staked2 = 2_000 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked2 - totalStaked2, { from: accounts[2] });
        totalStaked2 = staked2;

        time += days(120);
        await updateTimestamp(time);

    })

    it('Update deposit sum', async function(){
        await DaoInstance.addAdmin.sendTransaction(accounts[0]);

        await DaoInstance.createProposalAvailability.sendTransaction(true, 5_000_000 * tokenMultiplier);
        assert.equal(
            (await DaoInstance.minAmountToCreate.call()).toNumber(),
            5_000_000 * tokenMultiplier,
            'Incorrect deposit sum after update'
        );

        try {
            await DaoInstance.newProposal.sendTransaction(
                title,
                description,
                time + days(7),
                '',
                0,
                {
                    from: accounts[1]
                }
            );
        } catch(error) {
            assert.equal(
                error.reason,
                'Voting: you do not have permission'
            );
        }

        await DaoInstance.createProposalAvailability.sendTransaction(true, 1000);
        assert.equal(
            (await DaoInstance.minAmountToCreate.call()).toNumber(),
            1000,
            'Incorrect deposit sum after update (2)'
        );

        await DaoInstance.newProposal.sendTransaction(
            title,
            description,
            time + days(7),
            '',
            0,
            {
                from: accounts[1]
            }
        );
    })

    it('Cannot create proposal without permission', async function(){
        await DaoInstance.createProposalAvailability.sendTransaction(true, 1000);
        try {
            await DaoInstance.newProposal.sendTransaction(
                title,
                description,
                time + days(7),
                '',
                0,
                {
                    from: accounts[5]
                }
            );
        } catch(error) {
            assert.equal(
                error.reason,
                'Voting: you do not have permission'
            );
        }
        await DaoInstance.createProposalAvailability.sendTransaction(false, 1000);
        try {
            await DaoInstance.newProposal.sendTransaction(
                title,
                description,
                time + days(7),
                '',
                0,
                {
                    from: accounts[1]
                }
            );
        } catch(error) {
            assert.equal(
                error.reason,
                'Voting: you do not have permission'
            );
            return;
        }
        assert(false);
    })

    it('Create default proposal (yea / nay)', async function(){
        const depositAmount = 1000;
        const balance = (await TokenInstance.balanceOf.call(accounts[1])).toNumber();
        const countProposals = (await DaoInstance.countProposals.call()).toNumber();

        await DaoInstance.createProposalAvailability.sendTransaction(true, 1000);
        await DaoInstance.newProposal.sendTransaction(
            title,
            description,
            time + days(7),
            '', // no data for updating
            0, // update nothing
            {
                from: accounts[1]
            }
        );

        assert.equal(
            (await DaoInstance.countProposals.call()).toNumber(),
            countProposals + 1,
            'Did not created the proposal'
        );

        assert.equal(
            (await TokenInstance.balanceOf.call(accounts[1])).toNumber(),
            balance - depositAmount,
            'The deposit was not debited'
        );
    })

    it('Create multi proposal', async function(){
        //await DaoInstance.addAdmin.sendTransaction(accounts[0]);

        const depositAmount = 1000;
        const balance = (await TokenInstance.balanceOf.call(accounts[1])).toNumber();
        const countProposals = (await DaoInstance.countProposals.call()).toNumber();

        await DaoInstance.createProposalAvailability.sendTransaction(true, 1000);
        await DaoInstance.newMultiProposal.sendTransaction(
            title,
            description,
            time + days(10),
            [
                'one',
                'two',
                'three',
                'four',
                'five'
            ],
            0, // update nothing
            {
                from: accounts[1]
            }
        );

        assert.equal(
            (await DaoInstance.countProposals.call()).toNumber(),
            countProposals + 1,
            'Did not created the proposal'
        );

        assert.equal(
            (await TokenInstance.balanceOf.call(accounts[1])).toNumber(),
            balance - depositAmount,
            'The deposit was not debited'
        );
    })

    it('Get newest proposal', async function(){

        await DaoInstance.newProposal.sendTransaction(
            'Test getNewestProposal',
            description,
            time + days(7),
            '', // no data for updating
            0, // update nothing
        );

        const proposal = await DaoInstance.getNewestProposal.call();
        assert.equal(
            proposal.title,
            'Test getNewestProposal'
        );
    })

    it('Issue description', async function(){
        assert.equal(
            await DaoInstance.issueDescription.call(1),
            description
        );
    })

    it('Count options', async function(){
        assert.equal(
            await DaoInstance.countOptions.call(1),
            2
        );
    })

    it('Option name', async function(){
        assert.equal(
            await DaoInstance.optionName.call(1, 1),
            'yea'
        );
    })

    it('Vote', async function(){
        const issueId = 1;

        const staked = (await TokenInstance.lockedBalanceOf.call(accounts[0])).toNumber();
        const staked1 = (await TokenInstance.lockedBalanceOf.call(accounts[1])).toNumber();

        const counter = (await DaoInstance.weightedVoteCountsOf.call(issueId, 1)).toNumber();
        const weight = (await DaoInstance.weightOf.call(issueId, accounts[0])).toNumber();

        await DaoInstance.vote.sendTransaction(issueId, 1);
        
        try {
            await DaoInstance.vote.sendTransaction(issueId, 0);
        } catch(error) {
            assert.equal(
                error.reason,
                'Voting: you have already voted'
            );
        }

        await DaoInstance.vote.sendTransaction(issueId, 1, { from: accounts[1] }); // make quorum

        assert.equal(
            await DaoInstance.ballotOf.call(issueId, accounts[0]),
            1,
            'Incorrect ballot'
        );

        assert.equal(
            (await DaoInstance.weightOf.call(issueId, accounts[0])).toNumber() - weight,
            staked,
            'Incorrect weight'
        );

        assert.equal(
            (await DaoInstance.weightedVoteCountsOf.call(issueId, 1)).toNumber() - counter,
            2,
            'Incorrect counter'
        );

        const proposal = await DaoInstance.proposalInfo.call(issueId);
        assert.equal(
            proposal.title,
            title,
            'Incorrect title'
        );
        assert.equal(
            proposal.votingType,
            0,
            'Incorrect votingType'
        );
        assert.equal(
            proposal.votingUpdater,
            0,
            'Incorrect votingUpdater'
        );
        assert.equal(
            proposal.expiryTime.toNumber(),
            time + days(7),
            'Incorrect expiryTime'
        );
        assert.equal(
            proposal.hasQuorum,
            true,
            'Incorrect hasQuorum'
        );
        assert.equal(
            proposal.nay.toNumber(),
            0,
            'Incorrect nay'
        );
        assert.equal(
            proposal.yea.toNumber(),
            staked + staked1,
            'Incorrect yea'
        );
        assert.equal(
            proposal.accepted,
            false,
            'Incorrect accepted'
        );
    })

    it('Unvote', async function(){
        const issueId = 1;
        
        const staked = (await TokenInstance.lockedBalanceOf.call(accounts[0])).toNumber();
        const counter = (await DaoInstance.weightedVoteCountsOf.call(issueId, 1)).toNumber();
        const weight = (await DaoInstance.weightOf.call(issueId, accounts[0])).toNumber();
        const prevProposal = await DaoInstance.proposalInfo.call(issueId);

        assert.equal(
            staked,
            weight,
            'Incorrect staked weight'
        );

        await TokenInstance.unstake.sendTransaction(staked);

        assert.equal(
            (await DaoInstance.weightedVoteCountsOf.call(issueId, 1)).toNumber(),
            counter - 1,
            'Incorrect counter'
        );

        assert.equal(
            (await DaoInstance.weightOf.call(issueId, accounts[0])).toNumber(),
            0,
            'Incorrect weight'
        );

        const proposal = await DaoInstance.proposalInfo.call(issueId);
        assert.equal(
            proposal.yea.toNumber(),
            prevProposal.yea.toNumber() - weight,
            'Incorrect yea weight'
        );
        assert.equal(
            proposal.accepted,
            false,
            'Incorrect accepted'
        );
    })

    it('End of voting', async function(){
        const issueId = 1;

        assert.equal(
            await DaoInstance.vote.call(issueId, 1, { from: accounts[2] }),
            true,
            'Already cannot vote'
        );

        time += days(20);
        await updateTimestamp(time);

        assert.equal(
            await DaoInstance.vote.call(issueId, 1, { from: accounts[2] }),
            false,
            'Still voting'
        );

        const proposal = await DaoInstance.proposalInfo.call(issueId);
        assert.equal(
            proposal.accepted,
            true,
            'Incorrect accepted'
        );
    })

    it('Redeem deposit', async function(){
        const issueId = 1;

        const balance = (await TokenInstance.balanceOf.call(accounts[1])).toNumber();
        const deposited = (await DaoInstance.depositedForProposal.call(accounts[1], issueId)).toNumber();

        assert.equal(
            deposited,
            1000,
            'Incorrect deposited sum'
        );

        time -= days(20);
        await updateTimestamp(time);

        try {
            await DaoInstance.redeemDepositFromProposal.sendTransaction(issueId, { from: accounts[1] });
        } catch(error) {
            assert.equal(
                error.reason,
                'Voting: voting period is not finished yet'
            );
        }

        time += days(20);
        await updateTimestamp(time);

        await DaoInstance.redeemDepositFromProposal.sendTransaction(issueId, { from: accounts[1] });

        try {
            await DaoInstance.redeemDepositFromProposal.sendTransaction(issueId, { from: accounts[1] });
        } catch(error) {
            assert.equal(
                error.reason,
                'Voting: empty deposit'
            );
        }

        assert.equal(
            (await TokenInstance.balanceOf.call(accounts[1])).toNumber(),
            balance + deposited,
            'Incorrect balance'
        );
    })

    it('Proposal config', async function(){
        const instance = await CitadelDao.deployed();
        const proposal = await instance.proposalConfig.call(1);
        assert.equal(
            proposal.quorumPct.toNumber(),
            quorum,
            'Incorrect quorumPct'
        );
        assert.equal(
            proposal.supportPct.toNumber(),
            support,
            'Incorrect supportPct'
        );
        assert.equal(
            proposal.voters.toNumber(),
            1,
            'Incorrect voters'
        );
        assert.equal(
            proposal.updateData,
            '',
            'Incorrect updateData'
        );
    })

})

contract('CitadelDao Voting (Updater)', function(accounts){

    const title = 'Hello World';
    const description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';
    let TokenInstance,
        RewardsInstance,
        DaoInstance,
        totalStaked0 = 0,
        totalStaked1 = 0,
        totalStaked2 = 0,
        time = 0; // seconds

    async function updateTimestamp(timestamp){
        await TokenInstance.setTimestamp.sendTransaction(timestamp);
        await RewardsInstance.setTimestamp.sendTransaction(timestamp);
        await DaoInstance.setTimestamp.sendTransaction(timestamp);
        return true;
    }

    it('Deposit some tokens', async function(){
        TokenInstance = await Citadel.deployed();
        deployed = time = (await TokenInstance.deployed.call()).toNumber();

        RewardsInstance = await CitadelRewards.deployed();

        DaoInstance = await CitadelDao.deployed();
        
        const amount = 1_000_000 * tokenMultiplier;

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

        await TokenInstance.delegateTokens.sendTransaction(accounts[2], amount);

        assert.equal(
            (await TokenInstance.balanceOf.call(accounts[2])).toNumber(),
            amount,
            'Account 2'
        )
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

    it('Stake tokens', async function(){

        const staked0 = 500 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked0 - totalStaked0);
        totalStaked0 = staked0;

        assert.equal(
            (await TokenInstance.lockedBalanceOf.call(accounts[0])).toNumber(),
            totalStaked0
        );

        const staked1 = 2_000 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked1 - totalStaked1, { from: accounts[1] });
        totalStaked1 = staked1;

        const staked2 = 2_000 * tokenMultiplier;
        await TokenInstance.stake.sendTransaction(staked2 - totalStaked2, { from: accounts[2] });
        totalStaked2 = staked2;

        time += days(120);
        await updateTimestamp(time);

    })

    it('Add admin', async function(){
        await DaoInstance.addAdmin.sendTransaction(accounts[0]);
    })

    it('Update inflation', async function(){
        const titleInflation = 'Update inflation';
        const newValue = '400'; // 4.00%

        await DaoInstance.newProposal.sendTransaction(
            titleInflation,
            description,
            time + days(5),
            newValue,
            ProposalUpdater.Inflation,
        );

        const proposal = await DaoInstance.getNewestProposal.call();
        assert.equal(
            proposal.title,
            titleInflation,
            'Title incorrect'
        );
        assert.equal(
            proposal.votingUpdater,
            ProposalUpdater.Inflation,
            'Updater code is incorrect'
        );

        await DaoInstance.vote.sendTransaction(proposal.issueId, 0);
        await DaoInstance.vote.sendTransaction(proposal.issueId, 1, { from: accounts[1] });
        await DaoInstance.vote.sendTransaction(proposal.issueId, 1, { from: accounts[2] });
    
        time += days(10);
        await updateTimestamp(time);

        const proposalInfo = await DaoInstance.proposalInfo.call(proposal.issueId);
        assert.equal(
            proposalInfo.hasQuorum,
            true,
            'Didnt get quorum'
        );
        assert.equal(
            proposalInfo.accepted,
            true,
            'Isnt accepted'
        );

        const prevInflationCount = (await TokenInstance.countInflationPoints.call()).toNumber();
        const prevInflation = await TokenInstance.inflationPoint.call(prevInflationCount - 1);
        assert.notEqual(
            prevInflation.inflationPct,
            newValue,
            'Value has been updated'
        );

        await DaoInstance.execProposal.sendTransaction(proposal.issueId);

        const newInflationCount = (await TokenInstance.countInflationPoints.call()).toNumber();
        assert.notEqual(
            newInflationCount,
            prevInflationCount,
            'Checkpoint isnt created'
        );
        const newInflation = await TokenInstance.inflationPoint.call(newInflationCount - 1);
        assert.equal(
            newInflation.inflationPct,
            newValue,
            'Value hasnt been updated'
        );

    })

    it('Prevent double execution', async function(){
        const proposal = await DaoInstance.getNewestProposal.call();
        try {
            await DaoInstance.execProposal.sendTransaction(proposal.issueId);
        } catch (error) {
            assert.equal(
                error.reason,
                'Voting: already executed'
            );
            return;
        }
        assert(false, 'Can make double execution');
    })

    it('Update inflation (multi)', async function(){

        time += days(40);
        await updateTimestamp(time);

        const titleInflation = 'Update inflation';
        const newValue = '300'; // 3.00%

        await DaoInstance.newMultiProposal.sendTransaction(
            titleInflation,
            description,
            time + days(5),
            [
                '200',
                newValue,
                '400',
                '500',
                '600',
            ],
            ProposalUpdater.Inflation,
        );

        const proposal = await DaoInstance.getNewestProposal.call();
        assert.equal(
            proposal.title,
            titleInflation,
            'Title incorrect'
        );
        assert.equal(
            proposal.votingUpdater,
            ProposalUpdater.Inflation,
            'Updater code is incorrect'
        );

        await DaoInstance.vote.sendTransaction(proposal.issueId, 2);
        await DaoInstance.vote.sendTransaction(proposal.issueId, 2, { from: accounts[1] });
        await DaoInstance.vote.sendTransaction(proposal.issueId, 3, { from: accounts[2] });
    
        time += days(10);
        await updateTimestamp(time);

        const proposalInfo = await DaoInstance.proposalInfo.call(proposal.issueId);
        assert.equal(
            proposalInfo.hasQuorum,
            true,
            'Didnt get quorum'
        );
        assert.equal(
            proposalInfo.accepted,
            true,
            'Isnt accepted'
        );

        const prevInflationCount = (await TokenInstance.countInflationPoints.call()).toNumber();
        const prevInflation = await TokenInstance.inflationPoint.call(prevInflationCount - 1);
        assert.notEqual(
            prevInflation.inflationPct,
            newValue,
            'Value has been updated'
        );

        await DaoInstance.execProposal.sendTransaction(proposal.issueId);

        const newInflationCount = (await TokenInstance.countInflationPoints.call()).toNumber();
        assert.notEqual(
            newInflationCount,
            prevInflationCount,
            'Checkpoint isnt created'
        );
        const newInflation = await TokenInstance.inflationPoint.call(newInflationCount - 1);
        assert.equal(
            newInflation.inflationPct,
            newValue,
            'Value hasnt been updated'
        );

    })

    it('Update vesting', async function(){

        time += days(40);
        await updateTimestamp(time);

        const titleInflation = 'Update vesting';
        const newValue = '50'; // 50%

        await DaoInstance.newProposal.sendTransaction(
            titleInflation,
            description,
            time + days(5),
            newValue,
            ProposalUpdater.Vesting,
        );

        const proposal = await DaoInstance.getNewestProposal.call();
        assert.equal(
            proposal.title,
            titleInflation,
            'Title incorrect'
        );
        assert.equal(
            proposal.votingUpdater,
            ProposalUpdater.Vesting,
            'Updater code is incorrect'
        );

        await DaoInstance.vote.sendTransaction(proposal.issueId, 0);
        await DaoInstance.vote.sendTransaction(proposal.issueId, 1, { from: accounts[1] });
        await DaoInstance.vote.sendTransaction(proposal.issueId, 1, { from: accounts[2] });
    
        time += days(10);
        await updateTimestamp(time);

        const proposalInfo = await DaoInstance.proposalInfo.call(proposal.issueId);
        assert.equal(
            proposalInfo.hasQuorum,
            true,
            'Didnt get quorum'
        );
        assert.equal(
            proposalInfo.accepted,
            true,
            'Isnt accepted'
        );

        const prevInflationCount = (await TokenInstance.countInflationPoints.call()).toNumber();
        const prevInflation = await TokenInstance.inflationPoint.call(prevInflationCount - 1);
        assert.notEqual(
            prevInflation.stakingPct,
            newValue,
            'Value has been updated'
        );

        await DaoInstance.execProposal.sendTransaction(proposal.issueId);

        const newInflationCount = (await TokenInstance.countInflationPoints.call()).toNumber();
        assert.notEqual(
            newInflationCount,
            prevInflationCount,
            'Checkpoint isnt created'
        );
        const newInflation = await TokenInstance.inflationPoint.call(newInflationCount - 1);
        assert.equal(
            newInflation.stakingPct,
            newValue,
            'Value hasnt been updated'
        );

    })

    it('Update deposit to create proposal', async function(){

        time += days(40);
        await updateTimestamp(time);

        await DaoInstance.createProposalAvailability.sendTransaction(true, 5_000_000 * tokenMultiplier);
        assert.equal(
            (await DaoInstance.minAmountToCreate.call()).toNumber(),
            5_000_000 * tokenMultiplier,
            'Incorrect deposit sum after update'
        );

        try {
            await DaoInstance.newProposal.sendTransaction(
                title,
                description,
                time + days(7),
                '',
                0,
                {
                    from: accounts[1]
                }
            );
        } catch(error) {
            assert.equal(
                error.reason,
                'Voting: you do not have permission'
            );
        }
        
        const titleInflation = 'Update deposit';
        const newValue = '500'; // 50 XCT

        await DaoInstance.newProposal.sendTransaction(
            titleInflation,
            description,
            time + days(5),
            newValue,
            ProposalUpdater.CreateProposal,
        );

        const proposal = await DaoInstance.getNewestProposal.call();
        assert.equal(
            proposal.title,
            titleInflation,
            'Title incorrect'
        );
        assert.equal(
            proposal.votingUpdater,
            ProposalUpdater.CreateProposal,
            'Updater code is incorrect'
        );

        await DaoInstance.vote.sendTransaction(proposal.issueId, 0);
        await DaoInstance.vote.sendTransaction(proposal.issueId, 1, { from: accounts[1] });
        await DaoInstance.vote.sendTransaction(proposal.issueId, 1, { from: accounts[2] });
    
        time += days(10);
        await updateTimestamp(time);

        const proposalInfo = await DaoInstance.proposalInfo.call(proposal.issueId);
        assert.equal(
            proposalInfo.hasQuorum,
            true,
            'Didnt get quorum'
        );
        assert.equal(
            proposalInfo.accepted,
            true,
            'Isnt accepted'
        );

        await DaoInstance.execProposal.sendTransaction(proposal.issueId);

        assert.equal(
            (await DaoInstance.minAmountToCreate.call()).toNumber(),
            newValue,
            'Incorrect deposit sum after executing'
        );

        await DaoInstance.newProposal.sendTransaction(
            title,
            description,
            time + days(7),
            '',
            0,
            {
                from: accounts[1]
            }
        );

    })

    it('Update config', async function(){

        time += days(40);
        await updateTimestamp(time);

        const titleInflation = 'Update config';
        /*
         * (1 byte) config code: 0 - default, 1 - inflation
         * (6 bytes) quorum pct ~ 100.000%
         * (6 bytes) support pct ~ 100.000%
         */
        const newValue = '1' + '070000' + '060000';

        await DaoInstance.newProposal.sendTransaction(
            titleInflation,
            description,
            time + days(5),
            newValue, // percentages
            ProposalUpdater.UpdateConfig, // update inflation
        );

        const proposal = await DaoInstance.getNewestProposal.call();
        assert.equal(
            proposal.title,
            titleInflation,
            'Title incorrect'
        );
        assert.equal(
            proposal.votingUpdater,
            ProposalUpdater.UpdateConfig,
            'Updater code is incorrect'
        );

        await DaoInstance.vote.sendTransaction(proposal.issueId, 0);
        await DaoInstance.vote.sendTransaction(proposal.issueId, 1, { from: accounts[1] });
        await DaoInstance.vote.sendTransaction(proposal.issueId, 1, { from: accounts[2] });
    
        time += days(10);
        await updateTimestamp(time);

        const proposalInfo = await DaoInstance.proposalInfo.call(proposal.issueId);
        assert.equal(
            proposalInfo.hasQuorum,
            true,
            'Didnt get quorum'
        );
        assert.equal(
            proposalInfo.accepted,
            true,
            'Isnt accepted'
        );

        await DaoInstance.execProposal.sendTransaction(proposal.issueId);

        const result = await DaoInstance.proposalConfigRates.call(1);
        assert.equal(
            result.quorumPct.toNumber(),
            70*1000,
            'Incorrect quorumPct'
        );
        assert.equal(
            result.supportPct.toNumber(),
            60*1000,
            'Incorrect supportPct'
        );

    })

})

contract('CitadelDao Rewarding', function(accounts){

    let nonceId = 0, msg, sig;

    it('Claim staking rewards', async function(){

        const CitadelTokenInstance = await Citadel.deployed();
        const instance = await CitadelDao.deployed();

        const signer = web3.eth.accounts.create();
        const signerPrivateKey = signer.privateKey;
        const signerAddress = signer.address;

        await instance.setRewardAddress.sendTransaction(signerAddress);

        const recipient = accounts[3];

        const reward = 12345; // my reward from staking

        const incorrectNonceId = 10;

        try {
            const incorrectHash = EthCrypto.hash.keccak256([ // hash to verify data
                {type: 'address', value: recipient},
                {type: 'uint256', value: reward},
                {type: 'uint256', value: incorrectNonceId},
            ]);
            const incorrectSignature = EthCrypto.sign(signerPrivateKey, incorrectHash); // check request
            await instance.claimReward.sendTransaction(reward, incorrectNonceId, incorrectHash, incorrectSignature, { from: recipient });
        } catch (error) {
            assert.equal(
                error.reason,
                'Rewarding: incorrect nonceId',
                'Failed fake reward'
            );
        }

        const hash = EthCrypto.hash.keccak256([ // hash to verify data
            {type: 'address', value: recipient},
            {type: 'uint256', value: reward},
            {type: 'uint256', value: nonceId},
        ]);
        const signature = EthCrypto.sign(signerPrivateKey, hash); // check request

        msg = hash;
        sig = signature;

        await instance.claimReward.sendTransaction(reward, nonceId, hash, signature, { from: recipient });

        assert.equal(
            await CitadelTokenInstance.balanceOf.call(recipient),
            reward,
            'Failed first claim'
        )

        // second try
        nonceId++;
        const hash2 = EthCrypto.hash.keccak256([ // hash to verify data
            {type: 'address', value: recipient},
            {type: 'uint256', value: reward},
            {type: 'uint256', value: nonceId},
        ]);
        const signature2 = EthCrypto.sign(signerPrivateKey, hash2); // check request

        msg = hash2;
        sig = signature2;

        await instance.claimReward.sendTransaction(reward, nonceId, hash2, signature2, { from: recipient });

        assert.equal(
            await CitadelTokenInstance.balanceOf.call(recipient),
            reward * 2,
            'Failed second claim'
        )
    })

    it('Protect double claim staking rewards', async function(){

        const instance = await CitadelDao.deployed();

        const recipient = accounts[3];

        const reward = 12345; // my reward from staking
        nonceId = 0;
        try {
            await instance.claimReward.sendTransaction(reward, nonceId, msg, sig, { from: recipient });
        } catch (error) {
            assert.equal(
                error.reason,
                'Rewarding: incorrect nonceId'
            );
            return;
        }
        assert(false, 'Successful claim');

    })

    it('Protect fake staking rewards', async function(){

        const instance = await CitadelDao.deployed();

        const recipient = accounts[1];

        const reward = 12345; // my reward from staking
        nonceId = 0;
        try {
            await instance.claimReward.sendTransaction(reward, nonceId, msg, sig, { from: recipient });
        } catch (error) {
            assert.equal(
                error.reason,
                'Rewarding: incorrect hash'
            );
            return;
        }
        assert(false, 'Successful claim');

    })

})

const BN = require('bignumber.js');
const EthCrypto = require("eth-crypto");
const createKeccakHash = require('keccak');

const Citadel = artifacts.require("Citadel");
const CitadelDao = artifacts.require("CitadelDao");
const CitadelVesting = artifacts.require("CitadelVesting");

const ADMIN_ROLE = keccak256('ADMIN_ROLE');

const tokenMultiplier = 1e6;
const rate = 10000000;

function keccak256(str){
    return createKeccakHash('keccak256').update(str).digest();
}

return;

contract('CitadelDao', function(accounts){

    it("Version", async function(){
        const instance = await CitadelDao.deployed();
        assert.equal(
            await instance.version.call(),
            '0.1.0'
        )
    })

})

contract('CitadelDao Managing', function(accounts){

    it("add new admin", async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[1]);
        assert.equal(
            await instance.hasRole.call(ADMIN_ROLE, accounts[1]),
            true
        )
    })

    it("remove admin", async function(){
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
    const quorum = 50 * 1000;
    const support = 20 * 1000;
    let expiryTime; // seconds

    it("lock coins to get some vote power", async function(){
        const CitadelTokenInstance = await Citadel.deployed();
        const sendEth = 1000 * rate;
        const boughtTokens = await CitadelTokenInstance.calculateTokensEther.call(sendEth);
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
        await CitadelTokenInstance.lockCoins.sendTransaction(boughtTokens);
        await CitadelTokenInstance.lockCoins.sendTransaction(boughtTokens, {from: accounts[1]});
    })

    it("cannot createProposal without permission", async function(){
        const instance = await CitadelDao.deployed();
        try {
            await instance.newProposal.sendTransaction(title, description, expiryTime, 0, '');
        }catch(e){
            assert(true);
            return;
        }
        assert(false);
    })

    it("create default proposal (yea / nay)", async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[0]);
        expiryTime = parseInt(new Date().getTime() / 1000 + 5);
        await instance.newProposal.sendTransaction(
            title,
            description,
            expiryTime,
            0, // update nothing
            '' // no data for updating
        );
    })

    it("create multi proposal", async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[0]);
        let expiryTime2 = parseInt(new Date().getTime() / 1000 + 5);
        await instance.newMultiProposal.sendTransaction(
            title,
            description,
            expiryTime2,
            [
                'one',
                'two',
                'three',
                'four',
                'five'
            ],
            0 // update nothing
        );
    })

    it("countProposals", async function(){
        const instance = await CitadelDao.deployed();
        assert.equal(
            await instance.countProposals.call(),
            2
        )
    })

    it("getNewestProposal", async function(){
        const instance = await CitadelDao.deployed();
        let proposal = await instance.getNewestProposal.call();
        assert.equal(
            proposal.issueId,
            2,
            'issueId'
        );
        assert.equal(
            proposal.title,
            title,
            'title'
        );
    })

    it("issueDescription", async function(){
        const instance = await CitadelDao.deployed();
        assert.equal(
            await instance.issueDescription.call(1),
            description
        );
    })

    it("countOptions", async function(){
        const instance = await CitadelDao.deployed();
        assert.equal(
            await instance.countOptions.call(1),
            2
        );
    })

    it("optionName", async function(){
        const instance = await CitadelDao.deployed();
        assert.equal(
            await instance.optionName.call(1, 1),
            'yea'
        );
    })

    it("vote", async function(){
        const instance = await CitadelDao.deployed();
        await instance.vote.sendTransaction(1, 1);
        await new Promise(next => setTimeout(next, 2000));
    })

    it("ballotOf", async function(){
        const instance = await CitadelDao.deployed();
        assert.equal(
            await instance.ballotOf.call(1, accounts[0]),
            1
        );
    })

    it("weightOf", async function(){
        const instance = await CitadelDao.deployed();
        assert.equal(
            await instance.weightOf.call(1, accounts[0]),
            1000
        );
    })

    it("optionInfo", async function(){
        const instance = await CitadelDao.deployed();
        await new Promise(next => setTimeout(next, 2000));
        const opt = await instance.optionInfo.call(1, 1);
        assert.equal(
            opt.name,
            'yea',
            'name'
        );
        assert.equal(
            opt.count.toNumber(),
            1,
            'count'
        );
        assert.equal(
            opt.weight.toNumber(),
            1000,
            'amount'
        );
    })

    it("proposalInfo", async function(){
        const instance = await CitadelDao.deployed();
        const proposal = await instance.proposalInfo.call(1);
        assert.equal(
            proposal.title,
            title,
            'title'
        );
        assert.equal(
            proposal.votingType,
            0,
            'votingType'
        );
        assert.equal(
            proposal.votingUpdater,
            0,
            'votingUpdater'
        );
        assert.equal(
            proposal.expiryTime.toNumber(),
            expiryTime,
            'expiryTime'
        );
        assert.equal(
            proposal.hasQuorum,
            true,
            'hasQuorum'
        );
        assert.equal(
            proposal.nay.toNumber(),
            0,
            'nay'
        );
        assert.equal(
            proposal.yea.toNumber(),
            1000,
            'yea'
        );
        assert.equal(
            proposal.accepted,
            true,
            'accepted'
        );
    })

    it("proposalConfig", async function(){
        const instance = await CitadelDao.deployed();
        const proposal = await instance.proposalConfig.call(1);
        assert.equal(
            proposal.quorumPct.toNumber(),
            quorum,
            'quorumPct'
        );
        assert.equal(
            proposal.supportPct.toNumber(),
            support,
            'supportPct'
        );
        assert.equal(
            proposal.voters.toNumber(),
            1,
            'voters'
        );
        assert.equal(
            proposal.updateData,
            '',
            'updateData'
        );
    })

    it("everyone is allowed to create proposal", async function(){
        const instance = await CitadelDao.deployed();
        await instance.createProposalAvailability.sendTransaction(true, 500);
        assert(true);
    })

    it("cannot createProposal if they don't have enough staked coins", async function(){
        const instance = await CitadelDao.deployed();
        try {
            expiryTime = parseInt(new Date().getTime() / 1000 + 4);
            await instance.newProposal.sendTransaction(
                title,
                description,
                expiryTime,
                0,
                '',
                {from: accounts[2]}
            );
        }catch(e){
            assert(true);
            return;
        }
        assert(false);
    })

    it("can createProposal if they have enough staked coins", async function(){
        const instance = await CitadelDao.deployed();
        expiryTime = parseInt(new Date().getTime() / 1000 + 4);
        await instance.newProposal.sendTransaction(
            title,
            description,
            expiryTime,
            0,
            '',
            {from: accounts[1]}
        );
        assert(true);
    })

})

contract('CitadelDao Voting (Updater)', function(accounts){

    const title = 'Hello World';
    const description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';
    const quorum = 50 * 1000;
    const support = 20 * 1000;
    let expiryTime; // seconds

    it("lock coins to get some vote power", async function(){
        const CitadelTokenInstance = await Citadel.deployed();
        const sendEth = 1000 * rate;
        const boughtTokens = await CitadelTokenInstance.calculateTokensEther.call(sendEth);
        // 10000 Eth = 1000 XCT
        // buy some coins
        await web3.eth.sendTransaction({
            from: accounts[0],
            to: Citadel.address,
            value: sendEth,
            gas: 200000
        });
        /*await web3.eth.sendTransaction({
            from: accounts[1],
            to: Citadel.address,
            value: sendEth,
            gas: 200000
        });*/
        // do freezing coins to have some power
        await CitadelTokenInstance.lockCoins.sendTransaction(boughtTokens);
        //await CitadelTokenInstance.lockCoins.sendTransaction(boughtTokens, {from: accounts[1]});
    })

    it("create updater inflation", async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[0]);
        expiryTime = parseInt(new Date().getTime() / 1000 + 2);
        await instance.newProposal.sendTransaction(
            title,
            description,
            expiryTime,
            1, // update inflation
            (50*1000+50).toString() // 50 for staking + 50 for vesting
        );
    })

    it("vote for updater inflation", async function(){
        const instance = await CitadelDao.deployed();
        let proposal = await instance.getNewestProposal.call();
        await instance.vote.sendTransaction(proposal.issueId, 1);
        await new Promise(next => setTimeout(next, 2000 + expiryTime * 1000 - new Date().getTime()));
        let result = await instance.proposalInfo.call(proposal.issueId);
        assert.equal(
            result.hasQuorum,
            true,
            'hasQuorum'
        );
        assert.equal(
            result.accepted,
            true,
            'accepted'
        );
    })

    it("execute updater inflation", async function(){
        const instance = await CitadelDao.deployed();
        let proposal = await instance.getNewestProposal.call();
        await instance.execProposal.sendTransaction(proposal.issueId);
    })

    it("check updated inflation", async function(){
        const instance = await Citadel.deployed();
        let staking = await instance.getStakingInfo.call();
        let vesting = await instance.getVestingInfo.call();
        assert.equal(
            staking.pct.toNumber(),
            50,
            'staking'
        );
        assert.equal(
            vesting.pct.toNumber(),
            50,
            'vesting'
        );
    })

    it("create updater inflation (multi)", async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[0]);
        expiryTime = parseInt(new Date().getTime() / 1000 + 2);
        await instance.newMultiProposal.sendTransaction(
            title,
            description,
            expiryTime,
            [
                (10*1000+90).toString(),
                (30*1000+70).toString(),
                (50*1000+50).toString(),
                (70*1000+30).toString(),
                (90*1000+10).toString(),
            ],
            1, // update inflation
        );
    })

    it("vote for updater inflation (multi)", async function(){
        const instance = await CitadelDao.deployed();
        let proposal = await instance.getNewestProposal.call();
        await instance.vote.sendTransaction(proposal.issueId, 1);
        await new Promise(next => setTimeout(next, 2000 + expiryTime * 1000 - new Date().getTime()));
        let info = await instance.proposalInfo.call(proposal.issueId);
        assert.equal(
            info.hasQuorum,
            true,
            'hasQuorum'
        );
        let config = await instance.proposalConfig.call(proposal.issueId);
        let countOptions = await instance.countOptions.call(proposal.issueId);
        let maxIndex = -1;
        let maxWeight = -1;
        let totalWeight = 0;
        let tie = false;
        for(let i = 0; i < countOptions; i++){
            let option = await instance.optionInfo.call(proposal.issueId, i);
            let weight = option.weight.toNumber();
            totalWeight += weight;
            if(weight > maxWeight){
                maxIndex = i;
                maxWeight = weight;
                tie = false;
            } else if (weight == maxWeight) {
                tie = true;
            }
        }
        assert.equal(
            tie,
            false,
            'tie'
        );
        assert.equal(
            maxIndex,
            1,
            'chosenOption'
        );
        const curWeight = maxWeight * 100000 / totalWeight;
        const supportPct = config.supportPct.toNumber();
        assert.equal(
            curWeight >= supportPct,
            true,
            'accepted'
        );
    })

    it("execute updater inflation (multi)", async function(){
        const instance = await CitadelDao.deployed();
        let proposal = await instance.getNewestProposal.call();
        await instance.execProposal.sendTransaction(proposal.issueId);
    })

    it("check updated inflation (multi)", async function(){
        const instance = await Citadel.deployed();
        let staking = await instance.getStakingInfo.call();
        let vesting = await instance.getVestingInfo.call();
        assert.equal(
            staking.pct.toNumber(),
            30,
            'staking'
        );
        assert.equal(
            vesting.pct.toNumber(),
            70,
            'vesting'
        );
    })

    it("create updater minimum to create proposal", async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[0]);
        expiryTime = parseInt(new Date().getTime() / 1000 + 2);
        await instance.newProposal.sendTransaction(
            title,
            description,
            expiryTime,
            2, // update minimum to create proposal
            '500' // 500 frozen coins to create proposal
        );
    })

    it("vote for updater minimum to create proposal", async function(){
        const instance = await CitadelDao.deployed();
        let proposal = await instance.getNewestProposal.call();
        await instance.vote.sendTransaction(proposal.issueId, 1);
        await new Promise(next => setTimeout(next, 2000 + expiryTime * 1000 - new Date().getTime()));
        let result = await instance.proposalInfo.call(proposal.issueId);
        assert.equal(
            result.hasQuorum,
            true,
            'hasQuorum'
        );
        assert.equal(
            result.accepted,
            true,
            'accepted'
        );
    })

    it("execute updater minimum to create proposal", async function(){
        const instance = await CitadelDao.deployed();
        let proposal = await instance.getNewestProposal.call();
        await instance.execProposal.sendTransaction(proposal.issueId);
    })

    it("check updated minimum to create proposal", async function(){
        const instance = await CitadelDao.deployed();
        assert.equal(
            (await instance.minAmountToCreate.call()).toNumber(),
            500
        );
    })

    it("create updater config", async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[0]);
        expiryTime = parseInt(new Date().getTime() / 1000 + 2);
        await instance.newProposal.sendTransaction(
            title,
            description,
            expiryTime,
            3, // update minimum to create proposal
            '1070000060000' // 500 frozen coins to create proposal
        );
    })

    it("vote for updater config", async function(){
        const instance = await CitadelDao.deployed();
        let proposal = await instance.getNewestProposal.call();
        await instance.vote.sendTransaction(proposal.issueId, 1);
        await new Promise(next => setTimeout(next, 2000 + expiryTime * 1000 - new Date().getTime()));
        let result = await instance.proposalInfo.call(proposal.issueId);
        assert.equal(
            result.hasQuorum,
            true,
            'hasQuorum'
        );
        assert.equal(
            result.accepted,
            true,
            'accepted'
        );
    })

    it("execute updater config", async function(){
        const instance = await CitadelDao.deployed();
        let proposal = await instance.getNewestProposal.call();
        await instance.execProposal.sendTransaction(proposal.issueId);
    })

    it("check updated config", async function(){
        const instance = await CitadelDao.deployed();
        let result = await instance.proposalConfigRates.call(1);
        assert.equal(
            result.quorumPct.toNumber(),
            70*1000,
            'quorumPct'
        );
        assert.equal(
            result.supportPct.toNumber(),
            60*1000,
            'supportPct'
        );
    })

})

contract('CitadelDao Rewarding', function(accounts){

    let date, msg, sig;

    it("claim staking rewards", async function(){

        const instance = await CitadelDao.deployed();

        const signer = web3.eth.accounts.create();
        const signerPrivateKey = signer.privateKey;
        const signerAddress = signer.address;

        await instance.setRewardAddress.sendTransaction(signerAddress);

        const recipient = accounts[3];

        const reward = 12345; // my reward from staking
        const timestamp = parseInt(new Date().getTime() / 1000); // seconds
        const hash = EthCrypto.hash.keccak256([ // hash to verify data
            {type: "address", value: recipient},
            {type: "uint256", value: reward},
            {type: "uint256", value: timestamp},
        ]);
        const signature = EthCrypto.sign(signerPrivateKey, hash); // check request

        date = timestamp;
        msg = hash;
        sig = signature;

        await instance.claimReward.sendTransaction(reward, timestamp, hash, signature, {from: recipient});

        const CitadelTokenInstance = await Citadel.deployed();
        assert.equal(
            await CitadelTokenInstance.balanceOf.call(recipient),
            reward
        )
    })

    it("protect double claim staking rewards", async function(){

        const instance = await CitadelDao.deployed();

        const recipient = accounts[3];

        const reward = 12345; // my reward from staking
        try {
            await instance.claimReward.call(reward, date, msg, sig, {from: recipient});
        } catch(e) {
            assert(e.message.includes('Rewarding: freeze period'));
            return;
        }
        assert(false);

    })

})

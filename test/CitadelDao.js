const BN = require('bignumber.js');
const EthCrypto = require("eth-crypto");
const createKeccakHash = require('keccak');

function keccak256(str){
    return createKeccakHash('keccak256').update(str).digest();
}

const Citadel = artifacts.require("Citadel");
const CitadelDao = artifacts.require("CitadelDao");

const ADMIN_ROLE = keccak256('ADMIN_ROLE');

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
    const support = 35 * 1000;
    const expiryTime = parseInt(new Date().getTime() / 1000 + 1000); // seconds

    it("lock coins to get some vote power", async function(){
        const CitadelTokenInstance = await Citadel.deployed();
        const sendEth = 10000;
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
            await instance.createProposal.sendTransaction(title, description);
        }catch(e){
            assert(true);
            return;
        }
        assert(false);
    })

    it("create default proposal (yea / nay)", async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[0]);
        await instance.createProposal.sendTransaction(
            title,
            description,
            quorum,
            support,
            expiryTime
        );
    })

    it("create multi proposal", async function(){
        const instance = await CitadelDao.deployed();
        await instance.addAdmin.sendTransaction(accounts[0]);
        await instance.createProposal.sendTransaction(
            title,
            description,
            quorum,
            support,
            expiryTime,
            [
                'one',
                'two',
                'three',
                'four',
                'five'
            ]
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

    it("proposalInfoNative", async function(){
        const instance = await CitadelDao.deployed();
        const proposal = await instance.proposalInfoNative.call(1);
        assert.equal(
            proposal.title,
            title,
            'title'
        );
        assert.equal(
            proposal.votingType,
            0x00,
            'votingType'
        );
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
            proposal.expiryTime.toNumber(),
            expiryTime,
            'expiryTime'
        );
        assert.equal(
            proposal.voters.toNumber(),
            1,
            'voters'
        );
        assert.equal(
            proposal.hasQuorum,
            true,
            'hasQuorum'
        );
        assert.equal(
            proposal.isOpen,
            false,
            'isOpen'
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

    it("everyone is allowed to create proposal", async function(){
        const instance = await CitadelDao.deployed();
        await instance.createProposalAvailability.sendTransaction(true, 500);
        assert(true);
    })

    it("cannot createProposal if they don't have enough staked coins", async function(){
        const instance = await CitadelDao.deployed();
        try {
            await instance.createProposal.sendTransaction(
                title,
                description,
                quorum,
                support,
                expiryTime,
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
        await instance.createProposal.sendTransaction(
            title,
            description,
            quorum,
            support,
            expiryTime,
            {from: accounts[1]}
        );
        assert(true);
    })

})

contract('CitadelDao Rewarding', function(accounts){

    it("claim staking rewards", async function(){

        const instance = await CitadelDao.deployed();

        const signer = web3.eth.accounts.create();
        const signerPrivateKey = signer.privateKey;
        const signerAddress = signer.address;

        await instance.setRewardAddress.sendTransaction(signerAddress);

        const recipient = accounts[3];

        const reward = 12345; // my reward from staking
        const hash = EthCrypto.hash.keccak256([ // hash to verify data
            {type: "address", value: recipient},
            {type: "uint256", value: reward}
        ]);
        const signature = EthCrypto.sign(signerPrivateKey, hash); // check request

        await instance.claimReward.sendTransaction(reward, hash, signature, {from: recipient});

        const CitadelTokenInstance = await Citadel.deployed();
        assert.equal(
            await CitadelTokenInstance.balanceOf.call(recipient),
            reward
        )
    })

})

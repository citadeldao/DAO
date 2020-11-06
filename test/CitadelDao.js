const BN = require('bignumber.js');
const createKeccakHash = require('keccak');

function keccak256(str){
    return createKeccakHash('keccak256').update(str).digest();
}

var CitadelDao = artifacts.require("CitadelDao");

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
        const ADMIN_ROLE = keccak256('ADMIN_ROLE');
        await instance.addAdmin.sendTransaction(accounts[1]);
        assert.equal(
            await instance.hasRole.call(ADMIN_ROLE, accounts[1]),
            true
        )
    })

    it("remove admin", async function(){
        const instance = await CitadelDao.deployed();
        const ADMIN_ROLE = keccak256('ADMIN_ROLE');
        await instance.addAdmin.sendTransaction(accounts[0]);
        await instance.revokeRole.sendTransaction(ADMIN_ROLE, accounts[1]);
        assert.equal(
            await instance.hasRole.call(ADMIN_ROLE, accounts[1]),
            false
        )
    })

})

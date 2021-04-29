# DAO

truffle migrate -f 3 --to 3 --network testnet

Where '-f' is 'from'.

Starting migrations...
======================
> Network name:    'testnet'
> Network id:      97
> Block gas limit: 30000000 (0x1c9c380)


3_deploy_testnet.js
===================

   Replacing 'Citadel'
   -------------------
   > transaction hash:    0x1f00edd46b8f7a5a0f6e1caef286aaba9dedbf16c6221c8313b070c30582ea23
   > Blocks: 3            Seconds: 9
   > contract address:    0x2193E7A9184A7Cfbcf210aeaC6761c1da6c8f823
   > block number:        8408925
   > block timestamp:     1619716968
   > account:             0x80928d7cFDdF14bF2Fb54fFdE20fd52DDcde76f9
   > balance:             1.5897106
   > gas used:            5951176 (0x5acec8)
   > gas price:           20 gwei
   > value sent:          0 ETH
   > total cost:          0.11902352 ETH

   Pausing for 3 confirmations...
   ------------------------------
   > confirmation number: 2 (block: 8408928)
   > confirmation number: 3 (block: 8408929)

   Replacing 'CitadelDao'
   ----------------------
   > transaction hash:    0xd3efdaafce92286576c68eb8811ede9e6afb356daa33473deceef31618104127
   > Blocks: 1            Seconds: 5
   > contract address:    0xc0ef392436A611Ab896B211A5bF0946D28A29a8d
   > block number:        8408938
   > block timestamp:     1619717007
   > account:             0x80928d7cFDdF14bF2Fb54fFdE20fd52DDcde76f9
   > balance:             1.4907755
   > gas used:            4539183 (0x45432f)
   > gas price:           20 gwei
   > value sent:          0 ETH
   > total cost:          0.09078366 ETH

   Pausing for 3 confirmations...
   ------------------------------
   > confirmation number: 2 (block: 8408941)
   > confirmation number: 3 (block: 8408942)

   Replacing 'CitadelVesting'
   --------------------------
   > transaction hash:    0x5d7edd50324f2c8c17637ba261f33b9b22b438bfbe1b3c21f5490d7dfdddc4c9
   > Blocks: 1            Seconds: 5
   > contract address:    0xA1bd69c7331a926Cd51D92f7823293DB8606e0ce
   > block number:        8408948
   > block timestamp:     1619717037
   > account:             0x80928d7cFDdF14bF2Fb54fFdE20fd52DDcde76f9
   > balance:             1.47100228
   > gas used:            945057 (0xe6ba1)
   > gas price:           20 gwei
   > value sent:          0 ETH
   > total cost:          0.01890114 ETH

   Pausing for 3 confirmations...
   ------------------------------
   > confirmation number: 2 (block: 8408951)
   > confirmation number: 3 (block: 8408952)
   > Saving artifacts
   -------------------------------------
   > Total cost:          0.22870832 ETH


Summary
=======
> Total deployments:   3
> Final cost:          0.22870832 ETH
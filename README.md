# RISC Zero 
## Anti-Sandwich 🚫🥪

The goal of this project is multifacited, but likely will not acheive everything it sets out to do.

- verify the cannonical order of transactions within a multicall type execution
- verify index position on the mined block
- offload computation such signature validation for large hashes

The practical application of this is directly to be used for crosschain and sequencing restake slashing proofs. During execution/inclusion of a transaction all parts of a transaction must execute in a specific order without tampering (sandwich, frontend, etc) by the solver/sequencer. One method would be to have an event be executed by RISC Zero, where in the event of malicous activity a callback would execute the slash mechamism.

For brevity the execution proof will prove the ERC1271 executions of a multicall contract are canonically executed.
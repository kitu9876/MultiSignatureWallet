# MultiSignatureWallet
A wallet which require multiple approvals from a list of owners to perform any transaction.

The purpose of this multi signature wallet is to increase security by requiring multiple parties to agree on transactions before execution. Transactions can be executed only when confirmed by a predefined number of owners.

# Features

One administrator to the contract who can add or remove the address from the owners of the wallet contract.

Any of the owners can submit a new transaction proposal.

Administrator has the power to change the minimum percentage of confirmations required before any transaction is being executed.

Minimum percentage cannot be less than 60%.


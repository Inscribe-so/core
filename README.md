# Inscribe Contracts

Inscribe is a protocol that allows anyone to add arbitrary metadata on top of existing NFTs across any chain.

Media that can be attached may include photos, videos, text.

Use cases include hand written signatures, attaching trophies or badges for winning a tournament, and more!

For a specific usecase, visit our authentic handwritten signatures platform at https://inscribe.so

### Init

Installs the latest dependieces required to run and deploy the Inscribe smart contracts
```
npm install
```

Ensure that the latest truffle is installed. https://www.trufflesuite.com/docs/truffle/getting-started/installation
```
npm install -g truffle
```

Create a .env folder and enter the required parameters
```
INFURA_ID=XXX
ETHERSCAN_API_KEY=XXX
INSCRIBE_RINKEBY_PRIVATE_KEY=XXX
```

### Truffle commands

Compiles the latest contracts
```
truffle compile
```

Deploys to Rinkeby
```
truffle migrate --reset --network rinkeby
```

Verifies contract on etherscan
```
truffle run verify Inscribe --network rinkeby
```

### Latest Contract Deployments

#### Rinkeby
```
Inscribe.sol
0x65Aeaf50E1c762add60d7E5a7CBF98C4D94A6A73
```

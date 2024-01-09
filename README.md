# Wonderland Governor storage proofs

⚠️ The code has not been audited yet, tread with caution.

## Overview

Wonderland Governor is a DAO governance solution designed to address the current limitations in delegation within governance protocols. Unlike old systems where users give all their voting power to one delegate, it offers a flexible solution, introducing innovative features to empower users and enhance governance processes in decentralized organizations.

This project enhances the [Wonderland governor](https://github.com/defi-wonderland/wonderland-governooor-poc) solution using storage proofs instead of snapshots

## Setup

This project uses [Foundry](https://book.getfoundry.sh/). To build it locally, run:

```sh
git clone git@github.com:defi-wonderland/wonderland-governor-sp.git
cd wonderland-governor-sp
yarn install
yarn build
```

### Available Commands

| Yarn Command            | Description                                                |
| ----------------------- | ---------------------------------------------------------- |
| `yarn build`            | Compile all contracts.                                     |
| `yarn deploy:local`     | Deploy the contracts to a local fork.                      |
| `yarn deploy:goerli`    | Deploy the contracts to Goerli testnet.                    |
| `yarn deploy:optimism`  | Deploy the contracts to Optimism mainnet.                  |
| `yarn deploy:mainnet`   | Deploy the contracts to Ethereum mainnet.                  |

## Licensing

The primary license for Wonderland Governor contracts is MIT, see [`LICENSE`](./LICENSE).

## Contributors

Wonderland Governor was built with ❤️ by [Wonderland](https://defi.sucks).

Wonderland is a team of top Web3 researchers, developers, and operators who believe that the future needs to be open-source, permissionless, and decentralized.

[DeFi sucks](https://defi.sucks), but Wonderland is here to make it better.
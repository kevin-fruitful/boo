# Boo

![Boo Project Visualization](./images/booooo.webp)

Using [Axiom Quickstart](https://github.com/axiom-crypto/axiom-quickstart)

## Introduction

BOO.

This is an experimental implementation of novel reward mechanisms to attract users of competing platforms onto Aave using cutting edge zero knowledge technology by Axiom to enable the Boo contract to access historical blockchain data.

Boo is an extention of Aave v3's Pool contract.

It implements two mechanisms to attract liquidity to Aave:

A new method called `boo()` which withdraws collateral from a competing lending platform and deposits it into Aave. Currently, this method is specific to withdrawing USDC from Compound Comet.

A user can choose to lock this collateral for a period of time to guarantee incentives on the Aave platform.
Incentives can include:
    - Rebates on fees paid on borrows
    - Discounts on borrow rates
    - Aave tokens
    - Clout
    - ???

A user is not forced to lock in their collateral. Boo enforces reward eligibility via Axiom which enables the ability to check historic state to ensure that a user attempting to collect rewards meets reward criteria. This is really cool since this gives flexibility to the user while still allowing Aave to properly reward their avid users in a completely trustless manner!

### Further exploration

    - Incentivize based on the user's fee paid on borrows.
    - The current code is not validating the reward conditions and parameters. The current code is experimental.

This starter repo is a guide to get you started making your first [Axiom](https://axiom.xyz) query as quickly as possible using the [Axiom SDK](https://github.com/axiom-crypto/axiom-sdk-client) and [Axiom smart contract client](https://github.com/axiom-crypto/axiom-v2-periphery). To learn more about Axiom, check out the developer docs at [docs.axiom.xyz](https://docs.axiom.xyz) or join our developer [Telegram](https://t.me/axiom_discuss).

A guide on how to use this repository is available in the [Axiom Docs: Quickstart](https://docs.axiom.xyz/introduction/quickstart).

#### Installation

This repo contains both Foundry and Javascript packages. To install, run:

```bash
forge install
pnpm install     # or `npm install` or `yarn install`
cp .env.example .env
```

For installation instructions for Foundry or a Javascript package manager (`npm`, `yarn`, or `pnpm`), see [Package Manager Installation](#package-manager-installation).

Copy `.env.example` to `.env` and fill in your JSON-RPC provider URL. If you'd like to send transactions from a local hot wallet on testnet also add a Sepolia private key.

> ⚠️ **WARNING**: Never use your mainnet private key on a testnet! If you use this option, make sure you are not using the same account on mainnet.

## Test

To run Foundry tests that simulate the Axiom integration flow, run

```bash
forge test -vvvv
```

## Package Manager Installation

Install `npm` or `yarn` or `pnpm`:

```bash
# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
source ~/.bashrc  # or `source ~/.zshrc` on newer macs

# Install latest LTS node
nvm install --lts

# Install pnpm
npm install -g pnpm
pnpm setup
source ~/.bashrc  # or `source ~/.zshrc` on newer macs
```

Install [Foundry](https://book.getfoundry.sh/getting-started/installation). The recommended way to do this is using Foundryup:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

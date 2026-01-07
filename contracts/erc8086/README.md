# ERC-8086: Native Privacy Token

> Reference implementation for native privacy-preserving fungible tokens

## Overview

This directory contains the **complete, standalone** reference implementation of ERC-8086 (IZRC20).

**This implementation is independent** - it does not depend on or share code with ERC-8085 or any other implementation in this repository.

## Directory Structure

```
erc8086/
├── interfaces/
│   ├── IZRC20.sol          # Core privacy token interface
│   └── IVerifier.sol       # ZK-SNARK verifier interfaces
└── reference/
    ├── PrivacyToken.sol    # Privacy token implementation
    └── PrivacyTokenFactory.sol  # Factory for deploying tokens
```

## Key Features

- **Pure Privacy**: All balances and transfers are private by default
- **UTXO Model**: Uses commitments and nullifiers (not account balances)
- **ZK-SNARK Proofs**: Groth16 proofs for mint and transfer operations
- **Dual-Layer Merkle Tree**: Optimized for scalability (~68 billion capacity)

## Deployment

See `deployments/erc8086/base-sepolia.json` for deployed contract addresses.

**Demo App**: [testnative.zkprotocol.xyz](https://testnative.zkprotocol.xyz/)

## Specification

Full specification: [docs/erc-8086.md](../../docs/erc-8086.md)

## Verifier Interfaces

| Interface | Public Signals | Purpose |
|-----------|---------------|---------|
| `IMintVerifier` | 4 | Regular mint |
| `IMintRolloverVerifier` | 7 | Mint with subtree rollover |
| `IActiveTransferVerifier` | 12 | Transfer within active subtree |
| `IFinalizedTransferVerifier` | 13 | Transfer from finalized tree |
| `ITransferRolloverVerifier` | 12 | Transfer with subtree rollover |

## License

CC0-1.0 (Public Domain)

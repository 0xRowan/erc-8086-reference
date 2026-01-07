# ERC-8085: Dual-Mode Token

> Reference implementation for dual-mode fungible tokens (Public + Privacy)

## Overview

This directory contains the **complete, standalone** reference implementation of ERC-8085 (IDualModeToken).

**This implementation is independent** - it does not depend on or share code with ERC-8086 or any other implementation in this repository. While ERC-8085 conceptually builds upon ERC-8086 principles, this reference implementation is self-contained with its own interfaces and contracts.

## Directory Structure

```
erc8085/
├── interfaces/
│   ├── IZRC20.sol          # Privacy interface (ERC-8086 compatible)
│   ├── IVerifier.sol       # ZK-SNARK verifier interfaces
│   └── IDualModeToken.sol  # Dual-mode token interface
└── reference/
    ├── PrivacyToken.sol    # Base privacy layer (abstract)
    ├── DualModeToken.sol   # Dual-mode implementation
    └── DualModeTokenFactory.sol  # Factory for deploying tokens
```

## Key Features

- **Dual Mode**: Supports both ERC-20 (public) and ZK-SNARK (privacy) modes
- **Mode Conversion**: `toPrivacy()` and `toPublic()` for seamless switching
- **ERC-20 Compatible**: Works with existing wallets, DEXs, and DeFi
- **Unified Liquidity**: Single token address, no liquidity fragmentation

## Mode Operations

| Operation | Function | Description |
|-----------|----------|-------------|
| Public Mint | `mintPublic()` | Mint ERC-20 tokens |
| Public Transfer | `transfer(to, amount)` | Standard ERC-20 transfer |
| To Privacy | `toPrivacy()` | Convert public → privacy |
| Privacy Transfer | `transfer(proofType, proof, notes)` | ZK-SNARK transfer |
| To Public | `toPublic()` | Convert privacy → public |

## Deployment

See `deployments/erc8085/base-sepolia.json` for deployed contract addresses.

**Demo App**: [testdmt.zkprotocol.xyz](https://testdmt.zkprotocol.xyz/)

## Specification

Full specification: [docs/erc-8085.md](../../docs/erc-8085.md)

## Verifier Interfaces

| Interface | Public Signals | Purpose |
|-----------|---------------|---------|
| `IMintVerifier` | 4 | Regular mint |
| `IMintRolloverVerifier` | 7 | Mint with subtree rollover |
| `IActiveTransferVerifier` | 13 | Transfer (includes conversionAmount) |
| `IFinalizedTransferVerifier` | 14 | Finalized transfer (includes conversionAmount) |
| `ITransferRolloverVerifier` | 13 | Transfer with rollover |

> Note: The verifier interfaces differ from ERC-8086 due to the additional `conversionAmount` field needed for mode conversion.

## Relationship to ERC-8086

ERC-8085 is designed as an **application layer** that combines ERC-20 with ERC-8086 privacy features. However:

- This reference implementation is **completely standalone**
- No import dependencies on the `erc8086/` directory
- Different ZK circuits with different public signal counts
- Can be deployed independently without ERC-8086 contracts

## License

CC0-1.0 (Public Domain)

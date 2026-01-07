# ERC-8086: Privacy Token Standard

> A minimal interface for native privacy-preserving fungible tokens on Ethereum

[![ERC Status](https://img.shields.io/badge/ERC-8086-blue)](https://ethereum-magicians.org/t/erc-8086-privacy-token/26623)
[![ERC Status](https://img.shields.io/badge/ERC-8085-green)](https://ethereum-magicians.org/t/erc-8085-dual-mode-fungible-tokens/26592)
[![License: CC0-1.0](https://img.shields.io/badge/License-CC0_1.0-lightgrey.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

## Overview

This repository contains **two complementary ERC standards** for privacy-preserving tokens on Ethereum:

| Standard | Name | Description |
|----------|------|-------------|
| **ERC-8086** | Privacy Token (IZRC20) | Foundation layer - minimal interface for native privacy tokens |
| **ERC-8085** | Dual-Mode Token | Application layer - combines ERC-20 and ERC-8086 in one token |

```
Ecosystem Stack:
┌─────────────────────────────────────┐
│  Applications (DeFi, DAO, Gaming)   │
├─────────────────────────────────────┤
│  ERC-8085: Dual-Mode Token          │  ← Public + Privacy in one token
│  Wrapper Protocols (ERC-20→ZRC-20)  │  ← Privacy for existing tokens
├─────────────────────────────────────┤
│  ERC-8086: IZRC20 Privacy Interface │  ← Foundation layer
├─────────────────────────────────────┤
│  Ethereum L1 / L2s                  │
└─────────────────────────────────────┘
```

### ERC-8086: The Foundation

ERC-8086 defines **IZRC20**, a minimal interface standard for native privacy tokens. It enables:

- **Wrapper Protocols**: Add privacy to existing ERC-20 tokens (DAI → zDAI → DAI)
- **Dual-Mode Tokens**: Combine public (ERC-20) and private (ZRC-20) modes in one contract

### ERC-8085: Dual-Mode Token

ERC-8085 builds on ERC-8086 to create tokens that support **both transparent and privacy modes**:

```
Single Token Contract
  ↓
Public Mode (ERC-20) ←→ Privacy Mode (ZK-SNARK)
  ↓                           ↓
DeFi/DEX Trading          Private Holdings
```

**Key Features**:
- `toPrivacy()` - Convert public tokens to privacy mode
- `toPublic()` - Convert privacy tokens back to public mode
- Full ERC-20 compatibility for DeFi integration
- Unified liquidity (no separate wrapped token)

## Live Testnet Deployments

Both implementations are deployed and verified on **Base Sepolia**. Anyone can interact with and verify the contracts.

### Try It Now

| Standard | Demo App |
|----------|----------|
| **ERC-8086** (Native Privacy Token) | [testnative.zkprotocol.xyz](https://testnative.zkprotocol.xyz/) |
| **ERC-8085** (Dual-Mode Token) | [testdmt.zkprotocol.xyz](https://testdmt.zkprotocol.xyz/) |

---

### ERC-8086: Native Privacy Token Contracts

| Contract | Address | Basescan |
|----------|---------|----------|
| **PrivacyTokenFactory** | `0x04df6DbAe3BAe8bC91ef3b285d0666d36dda24af` | [View](https://sepolia.basescan.org/address/0x04df6DbAe3BAe8bC91ef3b285d0666d36dda24af#code) |
| **PrivacyToken (Implementation)** | `0xa025070b46a38d5793F491097A6aae1A6109000c` | [View](https://sepolia.basescan.org/address/0xa025070b46a38d5793F491097A6aae1A6109000c#code) |
| MintVerifier | `0x1C9260008DA7a12dF2DE2E562dC72b877f4B9a4b` | [View](https://sepolia.basescan.org/address/0x1C9260008DA7a12dF2DE2E562dC72b877f4B9a4b#code) |
| MintRolloverVerifier | `0x9423767D08eF34CEC1F1aD384e2884dd24c68f5B` | [View](https://sepolia.basescan.org/address/0x9423767D08eF34CEC1F1aD384e2884dd24c68f5B#code) |
| ActiveTransferVerifier | `0x14834a1b1E67977e4ec9a33fc84e58851E21c4Aa` | [View](https://sepolia.basescan.org/address/0x14834a1b1E67977e4ec9a33fc84e58851E21c4Aa#code) |
| FinalizedTransferVerifier | `0x1b7c464ed02af392a44CE7881081d1fb1D15b970` | [View](https://sepolia.basescan.org/address/0x1b7c464ed02af392a44CE7881081d1fb1D15b970#code) |
| RolloverTransferVerifier | `0x4dd4D44f99Afb3AE4F4e8C03BAdA2Ff84E75f9Cb` | [View](https://sepolia.basescan.org/address/0x4dd4D44f99Afb3AE4F4e8C03BAdA2Ff84E75f9Cb#code) |

---

### ERC-8085: Dual-Mode Token Contracts

| Contract | Address | Basescan |
|----------|---------|----------|
| **DualModeTokenFactory** | `0xf5c16f708777cCb57C3A8887065b4EC02eAf9130` | [View](https://sepolia.basescan.org/address/0xf5c16f708777cCb57C3A8887065b4EC02eAf9130#code) |
| **DualModeToken (Implementation)** | `0x1EFab166064AaD33fcB6074Ec8bA6302013C965C` | [View](https://sepolia.basescan.org/address/0x1EFab166064AaD33fcB6074Ec8bA6302013C965C#code) |
| MintVerifier | `0xC655b758f07bAaE8B956c95b055424a5c3B04e79` | [View](https://sepolia.basescan.org/address/0xC655b758f07bAaE8B956c95b055424a5c3B04e79#code) |
| MintRolloverVerifier | `0x9a6898B2e6C963EA81D17dCB9B0D483B590e168f` | [View](https://sepolia.basescan.org/address/0x9a6898B2e6C963EA81D17dCB9B0D483B590e168f#code) |
| ActiveTransferVerifier | `0x7159EcAc6d1BB1433922b597fc2887dCA33a3A62` | [View](https://sepolia.basescan.org/address/0x7159EcAc6d1BB1433922b597fc2887dCA33a3A62#code) |
| FinalizedTransferVerifier | `0x0f9b6F788774671C8c47D8adE9D36E884c96580D` | [View](https://sepolia.basescan.org/address/0x0f9b6F788774671C8c47D8adE9D36E884c96580D#code) |
| RolloverTransferVerifier | `0x0B22df9887351Ecfb403cfB27056f3A371F3bD92` | [View](https://sepolia.basescan.org/address/0x0B22df9887351Ecfb403cfB27056f3A371F3bD92#code) |

---

**Network**: Base Sepolia (Chain ID: 84532)

## Interface Specification

```solidity
interface IZRC20 {
    // Events
    event CommitmentAppended(uint32 indexed subtreeIndex, bytes32 commitment, uint32 indexed leafIndex, uint256 timestamp);
    event NullifierSpent(bytes32 indexed nullifier);
    event Minted(address indexed minter, bytes32 commitment, bytes encryptedNote, uint32 subtreeIndex, uint32 leafIndex, uint256 timestamp);
    event Transaction(bytes32[2] newCommitments, bytes[] encryptedNotes, uint256[2] ephemeralPublicKey, uint256 viewTag);

    // Metadata (OPTIONAL but RECOMMENDED)
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    // Core Functions
    function mint(uint8 proofType, bytes calldata proof, bytes calldata encryptedNote) external payable;
    function transfer(uint8 proofType, bytes calldata proof, bytes[] calldata encryptedNotes) external;
}
```

## Key Concepts

| Term | Description |
|------|-------------|
| **Commitment** | Cryptographic binding of value and ownership (hides amount & recipient) |
| **Nullifier** | Unique identifier proving a commitment is spent (prevents double-spending) |
| **Note** | Off-chain encrypted data `(amount, publicKey, randomness)` for recipient |
| **View Tag** | Single-byte scanning optimization (~99.6% filtering efficiency) |
| **Proof Type** | Routes to different verifiers (Active/Finalized/Rollover transfers) |

## Architecture: Dual-Layer Merkle Tree

This implementation uses a dual-layer architecture for scalability:

```
┌─────────────────────────────────────────────┐
│           Root Tree (20 levels)             │  ← Archives finalized subtrees
│         Capacity: 1,048,576 subtrees        │
├─────────────────────────────────────────────┤
│         Active Subtree (16 levels)          │  ← Recent commitments
│         Capacity: 65,536 notes              │  ← Fast proof generation
└─────────────────────────────────────────────┘

Total Capacity: 68.7 billion notes
```

**Benefits**:
- **2-3x faster** proof generation for active transfers
- **Decades** of capacity without architectural changes
- Efficient client synchronization (scan only active subtree)

## Proof Types

| Type | Value | Description | Use Case |
|------|-------|-------------|----------|
| **Active Transfer** | 0 | Both inputs from active subtree | Most common (~90% of txs) |
| **Finalized Transfer** | 1 | Inputs from finalized (historical) tree | Spending old notes |
| **Rollover Transfer** | 2 | Triggers subtree finalization | When active subtree is full |

## Repository Structure

```
erc-8086-reference/
├── README.md                           # This file
├── contracts/
│   ├── erc8086/                        # ERC-8086: Native Privacy Token
│   │   ├── interfaces/
│   │   │   ├── IZRC20.sol              # Core privacy token interface
│   │   │   └── IVerifier.sol           # ZK verifier interfaces
│   │   └── reference/
│   │       ├── PrivacyToken.sol        # Privacy token implementation
│   │       └── PrivacyTokenFactory.sol # Factory for deploying privacy tokens
│   │
│   └── erc8085/                        # ERC-8085: Dual-Mode Token
│       ├── interfaces/
│       │   └── IDualModeToken.sol      # Dual-mode token interface
│       └── reference/
│           ├── PrivacyToken.sol        # Base class (extends ERC-8086)
│           ├── DualModeToken.sol       # Dual-mode token implementation
│           └── DualModeTokenFactory.sol # Factory for deploying dual-mode tokens
│
├── deployments/
│   ├── erc8086/
│   │   └── base-sepolia.json           # ERC-8086 deployment addresses
│   └── erc8085/
│       └── base-sepolia.json           # ERC-8085 deployment addresses
│
├── docs/
│   ├── erc-8086.md                     # ERC-8086 full specification
│   └── erc-8085.md                     # ERC-8085 full specification
│
└── examples/
    └── interaction.md                  # How to interact with contracts
```

## Links

### ERC-8086 (Native Privacy Token)
- **EIP Discussion**: [ethereum-magicians.org/t/erc-8086-privacy-token](https://ethereum-magicians.org/t/erc-8086-privacy-token/26623)
- **Testnet App**: [testnative.zkprotocol.xyz](https://testnative.zkprotocol.xyz/)

### ERC-8085 (Dual-Mode Token)
- **EIP Discussion**: [ethereum-magicians.org/t/erc-8085-dual-mode-fungible-tokens](https://ethereum-magicians.org/t/erc-8085-dual-mode-fungible-tokens/26592)
- **Testnet App**: [testdmt.zkprotocol.xyz](https://testdmt.zkprotocol.xyz/)

## Security Considerations

1. **Nullifier Uniqueness**: Each nullifier can only be spent once
2. **Proof Verification**: All zk-SNARK proofs verified on-chain before state changes
3. **Merkle Tree Integrity**: Append-only structure prevents history modification
4. **Circuit Soundness**: Enforces value conservation and ownership proofs

## Community

- **X (Twitter)**: [@0xzkprotocol](https://x.com/0xzkprotocol)
- **Website**: [zkprotocol.xyz](https://zkprotocol.xyz)
- **GitHub**: [github.com/ZK-Protocol](https://github.com/ZK-Protocol)

## License

This project is licensed under [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/).

# ERC-8086: Privacy Token Standard

> A minimal interface for native privacy-preserving fungible tokens on Ethereum

[![ERC Status](https://img.shields.io/badge/ERC-8086-blue)](https://ethereum-magicians.org/t/erc-8086-privacy-token/26623)
[![License: CC0-1.0](https://img.shields.io/badge/License-CC0_1.0-lightgrey.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

## Overview

ERC-8086 defines **IZRC20**, a minimal interface standard for native privacy tokens on Ethereum. This standard enables:

- **Wrapper Protocols**: Add privacy to existing ERC-20 tokens (DAI → zDAI → DAI)
- **Dual-Mode Tokens**: Combine public (ERC-20) and private (ZRC-20) modes in one contract

```
Ecosystem Stack:
┌─────────────────────────────────────┐
│  Applications (DeFi, DAO, Gaming)   │
├─────────────────────────────────────┤
│  Dual-Mode Tokens (ERC-20 + ZRC-20) │  ← Future privacy-native tokens
│  Wrapper Protocols (ERC-20→ZRC-20)  │  ← Privacy for existing tokens
├─────────────────────────────────────┤
│  IZRC20: Native Privacy Interface   │  ← This standard (foundation)
├─────────────────────────────────────┤
│  Ethereum L1 / L2s                  │
└─────────────────────────────────────┘
```

## Live Testnet Deployment

The reference implementation is deployed and verified on **Base Sepolia**. Anyone can interact with and verify the contracts.

### Try It Now

**Launch App**: [https://testnative.zkprotocol.xyz/](https://testnative.zkprotocol.xyz/)

### Deployed Contracts

| Contract | Address | Basescan |
|----------|---------|----------|
| **PrivacyTokenFactory** | `0x04df6DbAe3BAe8bC91ef3b285d0666d36dda24af` | [View](https://sepolia.basescan.org/address/0x04df6DbAe3BAe8bC91ef3b285d0666d36dda24af#code) |
| **PrivacyToken (Implementation)** | `0xa025070b46a38d5793F491097A6aae1A6109000c` | [View](https://sepolia.basescan.org/address/0xa025070b46a38d5793F491097A6aae1A6109000c#code) |
| MintVerifier | `0x1C9260008DA7a12dF2DE2E562dC72b877f4B9a4b` | [View](https://sepolia.basescan.org/address/0x1C9260008DA7a12dF2DE2E562dC72b877f4B9a4b#code) |
| MintRolloverVerifier | `0x9423767D08eF34CEC1F1aD384e2884dd24c68f5B` | [View](https://sepolia.basescan.org/address/0x9423767D08eF34CEC1F1aD384e2884dd24c68f5B#code) |
| ActiveTransferVerifier | `0x14834a1b1E67977e4ec9a33fc84e58851E21c4Aa` | [View](https://sepolia.basescan.org/address/0x14834a1b1E67977e4ec9a33fc84e58851E21c4Aa#code) |
| FinalizedTransferVerifier | `0x1b7c464ed02af392a44CE7881081d1fb1D15b970` | [View](https://sepolia.basescan.org/address/0x1b7c464ed02af392a44CE7881081d1fb1D15b970#code) |
| RolloverTransferVerifier | `0x4dd4D44f99Afb3AE4F4e8C03BAdA2Ff84E75f9Cb` | [View](https://sepolia.basescan.org/address/0x4dd4D44f99Afb3AE4F4e8C03BAdA2Ff84E75f9Cb#code) |

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
│   ├── interfaces/
│   │   ├── IZRC20.sol                  # Core interface (ERC-8086)
│   │   └── IVerifier.sol               # Verifier interfaces
│   └── reference/
│       ├── PrivacyToken.sol            # Reference implementation
│       └── PrivacyTokenFactory.sol     # Factory for deploying tokens
├── deployments/
│   └── base-sepolia.json               # Deployment addresses & config
├── docs/
│   └── erc-8086.md                     # Full ERC specification
└── examples/
    └── interaction.md                  # How to interact with contracts
```

## Links

- **EIP Discussion**: [ethereum-magicians.org/t/erc-8086-privacy-token](https://ethereum-magicians.org/t/erc-8086-privacy-token/26623)
- **Testnet App**: [testnative.zkprotocol.xyz](https://testnative.zkprotocol.xyz/)

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

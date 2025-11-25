# EIP-8086: Privacy Token Standard

> A minimal interface for native privacy-preserving fungible tokens on Ethereum

[![EIP Status](https://img.shields.io/badge/EIP-8086-blue)](https://eips.ethereum.org/EIPS/eip-8086)
[![License: CC0-1.0](https://img.shields.io/badge/License-CC0_1.0-lightgrey.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

## Overview

EIP-8086 defines **IZRC20**, a minimal interface standard for native privacy tokens on Ethereum. This standard enables:

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
| **PrivacyTokenFactory** | `0x8303A804fa17f40a4725D1b4d9aF9CB63244289c` | [View](https://sepolia.basescan.org/address/0x8303A804fa17f40a4725D1b4d9aF9CB63244289c#code) |
| **PrivacyToken (Implementation)** | `0xB329Dc91f458350a970Fe998e3322Efb08dDA7d1` | [View](https://sepolia.basescan.org/address/0xB329Dc91f458350a970Fe998e3322Efb08dDA7d1#code) |
| MintVerifier | `0x59B96075Dd61e182f73F181259fB86ee5154F6c9` | [View](https://sepolia.basescan.org/address/0x59B96075Dd61e182f73F181259fB86ee5154F6c9#code) |
| MintRolloverVerifier | `0x1CAEB20665C98D17cCAE542382f4113b02b75ffe` | [View](https://sepolia.basescan.org/address/0x1CAEB20665C98D17cCAE542382f4113b02b75ffe#code) |
| ActiveTransferVerifier | `0xB3D901e4498654e518F7cf386FBA16be62C3d481` | [View](https://sepolia.basescan.org/address/0xB3D901e4498654e518F7cf386FBA16be62C3d481#code) |
| FinalizedTransferVerifier | `0xF878D3edF4F39f6B813cC12A83FcE4725B06Bb47` | [View](https://sepolia.basescan.org/address/0xF878D3edF4F39f6B813cC12A83FcE4725B06Bb47#code) |
| RolloverTransferVerifier | `0xdBfb58cc0275cBD38dB1e0e0b36E619934f6c0Cb` | [View](https://sepolia.basescan.org/address/0xdBfb58cc0275cBD38dB1e0e0b36E619934f6c0Cb#code) |

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
eip-8086-reference/
├── README.md                           # This file
├── contracts/
│   ├── interfaces/
│   │   ├── IZRC20.sol                  # Core interface (EIP-8086)
│   │   └── IVerifier.sol               # Verifier interfaces
│   └── reference/
│       ├── PrivacyToken.sol            # Reference implementation
│       └── PrivacyTokenFactory.sol     # Factory for deploying tokens
├── deployments/
│   └── base-sepolia.json               # Deployment addresses & config
├── docs/
│   └── erc-8086.md                     # Full EIP specification
└── examples/
    └── interaction.md                  # How to interact with contracts
```

## Links

- **EIP Discussion**: [ethereum-magicians.org/t/erc-8086-privacy-token](https://ethereum-magicians.org/t/erc-8086-privacy-token/26623)
- **Testnet App**: [testnative.zkprotocol.xyz](https://testnative.zkprotocol.xyz/)
- **Whitepaper**: [docs/whitepaper.md](./docs/whitepaper.md)

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

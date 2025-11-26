# Interacting with ERC-8086 Privacy Tokens

This guide explains how to interact with the deployed ERC-8086 reference implementation on Base Sepolia.

## Quick Start

The easiest way to interact with the protocol is through the web interface:

**Launch App**: [https://testnative.zkprotocol.xyz/](https://testnative.zkprotocol.xyz/)

## Contract Addresses (Base Sepolia)

```
Factory:                    0x04df6DbAe3BAe8bC91ef3b285d0666d36dda24af
PrivacyToken Implementation: 0xa025070b46a38d5793F491097A6aae1A6109000c
```

## Reading Contract State

### Using Ethers.js

```javascript
import { ethers } from 'ethers';

// Connect to Base Sepolia
const provider = new ethers.JsonRpcProvider('https://sepolia.base.org');

// Factory ABI (simplified)
const factoryABI = [
  'function creationFee() view returns (uint256)',
  'function platformFeeBps() view returns (uint256)',
  'function subtree_height() view returns (uint8)',
  'function roottree_height() view returns (uint8)',
  'event TokenCreated(address indexed tokenAddress, address indexed creator, string name, string symbol, uint256 maxSupply, uint256 mintAmount, uint256 mintPrice, uint256 subTreeHeight, uint256 rootTreeHeight)'
];

const factory = new ethers.Contract(
  '0x04df6DbAe3BAe8bC91ef3b285d0666d36dda24af',
  factoryABI,
  provider
);

// Read factory configuration
async function getFactoryConfig() {
  const creationFee = await factory.creationFee();
  const platformFeeBps = await factory.platformFeeBps();
  const subtreeHeight = await factory.subtree_height();
  const rootTreeHeight = await factory.roottree_height();

  console.log('Creation Fee:', ethers.formatEther(creationFee), 'ETH');
  console.log('Platform Fee:', platformFeeBps / 100, '%');
  console.log('Subtree Height:', subtreeHeight);
  console.log('Root Tree Height:', rootTreeHeight);
}
```

### Privacy Token State

```javascript
// Privacy Token ABI (simplified)
const tokenABI = [
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function totalSupply() view returns (uint256)',
  'function MINT_PRICE() view returns (uint256)',
  'function MINT_AMOUNT() view returns (uint256)',
  'function MAX_SUPPLY() view returns (uint256)',
  'function activeSubtreeRoot() view returns (bytes32)',
  'function finalizedRoot() view returns (bytes32)',
  'function nullifiers(bytes32) view returns (bool)',
  'function state() view returns (uint32 currentSubtreeIndex, uint32 nextLeafIndexInSubtree, uint8 subTreeHeight, uint8 rootTreeHeight, bool initialized)'
];

async function getTokenState(tokenAddress) {
  const token = new ethers.Contract(tokenAddress, tokenABI, provider);

  const name = await token.name();
  const symbol = await token.symbol();
  const totalSupply = await token.totalSupply();
  const mintPrice = await token.MINT_PRICE();
  const state = await token.state();

  console.log(`Token: ${name} (${symbol})`);
  console.log('Total Supply:', ethers.formatEther(totalSupply));
  console.log('Mint Price:', ethers.formatEther(mintPrice), 'ETH');
  console.log('Current Subtree Index:', state.currentSubtreeIndex);
  console.log('Next Leaf Index:', state.nextLeafIndexInSubtree);
}
```

## Listening to Events

### Monitor New Token Creations

```javascript
// Listen for new privacy tokens
factory.on('TokenCreated', (tokenAddress, creator, name, symbol, maxSupply, mintAmount, mintPrice) => {
  console.log('New Token Created!');
  console.log('  Address:', tokenAddress);
  console.log('  Creator:', creator);
  console.log('  Name:', name);
  console.log('  Symbol:', symbol);
  console.log('  Max Supply:', ethers.formatEther(maxSupply));
});
```

### Monitor Privacy Transactions

```javascript
const token = new ethers.Contract(tokenAddress, [
  'event CommitmentAppended(uint32 indexed subtreeIndex, bytes32 commitment, uint32 indexed leafIndex, uint256 timestamp)',
  'event NullifierSpent(bytes32 indexed nullifier)',
  'event Transaction(bytes32[2] newCommitments, bytes[] encryptedNotes, uint256[2] ephemeralPublicKey, uint256 viewTag)',
  'event Minted(address indexed minter, bytes32 commitment, bytes encryptedNote, uint32 subtreeIndex, uint32 leafIndex, uint256 timestamp)'
], provider);

// Listen for mints
token.on('Minted', (minter, commitment, encryptedNote, subtreeIndex, leafIndex, timestamp) => {
  console.log('New Mint!');
  console.log('  Minter:', minter);
  console.log('  Commitment:', commitment);
  console.log('  Subtree:', subtreeIndex, 'Leaf:', leafIndex);
});

// Listen for transfers
token.on('Transaction', (newCommitments, encryptedNotes, ephemeralPublicKey, viewTag) => {
  console.log('Privacy Transfer!');
  console.log('  New Commitments:', newCommitments);
  console.log('  View Tag:', viewTag);
});

// Listen for nullifier spending (detect double-spend attempts)
token.on('NullifierSpent', (nullifier) => {
  console.log('Nullifier Spent:', nullifier);
});
```

## Querying Historical Events

```javascript
async function getTokenHistory(tokenAddress, fromBlock = 0) {
  const token = new ethers.Contract(tokenAddress, tokenABI, provider);

  // Get all mints
  const mintFilter = token.filters.Minted();
  const mints = await token.queryFilter(mintFilter, fromBlock);
  console.log(`Found ${mints.length} mints`);

  // Get all transfers
  const txFilter = token.filters.Transaction();
  const transfers = await token.queryFilter(txFilter, fromBlock);
  console.log(`Found ${transfers.length} transfers`);

  // Get all commitments
  const commitmentFilter = token.filters.CommitmentAppended();
  const commitments = await token.queryFilter(commitmentFilter, fromBlock);
  console.log(`Found ${commitments.length} commitments`);

  return { mints, transfers, commitments };
}
```

## Check Nullifier Status

```javascript
async function isNullifierSpent(tokenAddress, nullifier) {
  const token = new ethers.Contract(tokenAddress, tokenABI, provider);
  const spent = await token.nullifiers(nullifier);
  return spent;
}

// Example
const nullifier = '0x1234...';
const spent = await isNullifierSpent(tokenAddress, nullifier);
console.log('Nullifier spent:', spent);
```

## Understanding Proof Types

| Type | Value | Use Case |
|------|-------|----------|
| Regular Mint | 0 | Standard minting when subtree has capacity |
| Rollover Mint | 1 | Minting that triggers subtree finalization |
| Active Transfer | 0 | Transfer within active subtree (fastest) |
| Finalized Transfer | 1 | Transfer from historical subtrees |
| Rollover Transfer | 2 | Transfer that triggers subtree finalization |

## Verifying Contracts on Basescan

All contracts are verified. Click to view source code:

- [Factory](https://sepolia.basescan.org/address/0x04df6DbAe3BAe8bC91ef3b285d0666d36dda24af#code)
- [PrivacyToken Implementation](https://sepolia.basescan.org/address/0xa025070b46a38d5793F491097A6aae1A6109000c#code)
- [MintVerifier](https://sepolia.basescan.org/address/0x1C9260008DA7a12dF2DE2E562dC72b877f4B9a4b#code)
- [ActiveTransferVerifier](https://sepolia.basescan.org/address/0x14834a1b1E67977e4ec9a33fc84e58851E21c4Aa#code)

## Note on Privacy

**Important**: The `mint()` and `transfer()` functions require zero-knowledge proofs generated off-chain. These proofs are complex cryptographic constructs that:

1. Prove ownership of input notes
2. Prove value conservation (inputs = outputs)
3. Prove Merkle tree membership
4. Generate valid nullifiers and commitments

The web application at [testnative.zkprotocol.xyz](https://testnative.zkprotocol.xyz/) handles all proof generation automatically.

## Resources

- [ERC-8086 Specification](../docs/erc-8086.md)
- [Whitepaper](../docs/whitepaper.md)
- [Discussion Forum](https://ethereum-magicians.org/t/erc-8086-privacy-token/26623)

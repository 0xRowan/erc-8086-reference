// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVerifier.sol";
import "../interfaces/IZRC20.sol";

/**
 * @title PrivacyToken
 * @notice Reference implementation of EIP-8086 (IZRC20) with dual-layer Merkle tree architecture
 * @dev This implementation uses a dual-layer tree structure:
 *      - Active Subtree (16 levels): Stores recent commitments, enables fast proof generation
 *      - Root Tree (20 levels): Archives finalized subtree roots
 *      Total capacity: 2^16 × 2^20 = 68.7 billion notes
 */
contract PrivacyToken is IZRC20, ReentrancyGuard {

    // ===================================
    //        CUSTOM ERRORS
    // ===================================
    error AlreadyInitialized();
    error InvalidProofType(uint8 receivedType);
    error InvalidProof();
    error InvalidPublicSignalLength(uint256 expected, uint256 received);
    error IncorrectMintPrice(uint256 expected, uint256 sent);
    error MaxSupplyExceeded();
    error IncorrectMintAmount(uint256 expected, uint256 proven);
    error CommitmentAlreadyExists(bytes32 commitment);
    error DoubleSpend(bytes32 nullifier);
    error OldActiveRootMismatch(bytes32 expected, bytes32 received);
    error OldFinalizedRootMismatch(bytes32 expected, bytes32 received);
    error IncorrectSubtreeIndex(uint256 expected, uint256 received);
    error InvalidStateForRegularMint();
    error InvalidStateForRollover();
    error SubtreeCapacityExceeded(uint256 needed, uint256 available);
    error NoFeesToDistribute();
    error FeeTransferFailed();

    // ===================================
    //        STATE VARIABLES
    // ===================================

    // --- Token Metadata ---
    string private _name;
    string private _symbol;
    uint256 public MAX_SUPPLY;
    uint256 public override MINT_PRICE;
    uint256 public override MINT_AMOUNT;

    // --- Fee Distribution ---
    address public initiator;
    address public platformTreasury;
    uint256 public platformFeeBps;

    // --- Verifiers ---
    IActiveTransferVerifier public activeTransferVerifier;
    IFinalizedTransferVerifier public finalizedTransferVerifier;
    ITransferRolloverVerifier public rolloverTransferVerifier;
    IMintVerifier public mintVerifier;
    IMintRolloverVerifier public mintRolloverVerifier;

    // --- Privacy State ---
    mapping(bytes32 => bool) public nullifiers;
    mapping(bytes32 => bool) public commitmentHashes;
    uint256 public override totalSupply;

    // --- Contract State (Packed for gas efficiency) ---
    ContractState public state;

    // --- Tree Configuration ---
    bytes32 public EMPTY_SUBTREE_ROOT;
    bytes32 public override activeSubtreeRoot;
    bytes32 public override finalizedRoot;
    uint256 public SUBTREE_CAPACITY;

    /**
     * @dev Structured transaction data extracted from ZK proof public signals
     */
    struct TransactionData {
        bytes32[2] nullifiers;
        bytes32[2] commitments;
        uint256[2] ephemeralPublicKey;
        uint256 viewTag;
    }

    constructor() {}

    /**
     * @notice Initializes the cloned contract (called by factory)
     * @dev Replaces constructor for minimal proxy pattern
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 max_supply_,
        uint256 mintPrice_,
        uint256 mint_amount_,
        address initiator_,
        address platformTreasury_,
        uint256 platformFeeBps_,
        address[5] memory verifiers_,
        uint8 subtreeHeight_,
        uint8 rootTreeHeight_,
        bytes32 initialSubtreeEmptyRoot_,
        bytes32 initialFinalizedEmptyRoot_
    ) external {
        if (state.initialized) revert AlreadyInitialized();
        state.initialized = true;

        initiator = initiator_;
        _name = name_;
        _symbol = symbol_;
        MAX_SUPPLY = max_supply_;
        MINT_PRICE = mintPrice_;
        MINT_AMOUNT = mint_amount_;
        platformTreasury = platformTreasury_;
        platformFeeBps = platformFeeBps_;

        mintVerifier = IMintVerifier(verifiers_[0]);
        mintRolloverVerifier = IMintRolloverVerifier(verifiers_[1]);
        activeTransferVerifier = IActiveTransferVerifier(verifiers_[2]);
        finalizedTransferVerifier = IFinalizedTransferVerifier(verifiers_[3]);
        rolloverTransferVerifier = ITransferRolloverVerifier(verifiers_[4]);

        state.subTreeHeight = subtreeHeight_;
        SUBTREE_CAPACITY = 1 << subtreeHeight_;
        state.rootTreeHeight = rootTreeHeight_;
        EMPTY_SUBTREE_ROOT = initialSubtreeEmptyRoot_;

        activeSubtreeRoot = initialSubtreeEmptyRoot_;
        finalizedRoot = initialFinalizedEmptyRoot_;
        state.nextLeafIndexInSubtree = 0;
    }

    // ===================================
    //        METADATA VIEWS
    // ===================================

    function name() external view override returns (string memory) { return _name; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function decimals() external pure override returns (uint8) { return 18; }

    // ===================================
    //        MINTING INTERFACE
    // ===================================

    /**
     * @notice Mints new privacy tokens
     * @param proofType 0 for regular mint, 1 for rollover mint
     * @param proof ABI-encoded zk-SNARK proof with public signals
     * @param encryptedNote Encrypted note for the minter
     */
    function mint(
        uint8 proofType,
        bytes calldata proof,
        bytes calldata encryptedNote
    ) external override payable nonReentrant {
        if (msg.value != MINT_PRICE) revert IncorrectMintPrice(MINT_PRICE, msg.value);
        if (totalSupply + MINT_AMOUNT > MAX_SUPPLY) revert MaxSupplyExceeded();

        if (proofType == 0) {
            _mintRegular(proof, encryptedNote);
        } else if (proofType == 1) {
            _mintAndRollover(proof, encryptedNote);
        } else {
            revert InvalidProofType(proofType);
        }
    }

    function _mintRegular(bytes calldata _proof, bytes calldata _encryptedNote) internal {
        if (state.nextLeafIndexInSubtree >= SUBTREE_CAPACITY) revert InvalidStateForRegularMint();

        (uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[4] memory pubSignals) =
            abi.decode(_proof, (uint[2], uint[2][2], uint[2], uint[4]));

        bytes32 newActiveRoot = bytes32(pubSignals[0]);
        bytes32 oldActiveRoot_from_proof = bytes32(pubSignals[1]);
        bytes32 newCommitment = bytes32(pubSignals[2]);
        uint256 mintAmount_from_proof = pubSignals[3];

        if (commitmentHashes[newCommitment]) revert CommitmentAlreadyExists(newCommitment);
        commitmentHashes[newCommitment] = true;

        if (activeSubtreeRoot != oldActiveRoot_from_proof) revert OldActiveRootMismatch(activeSubtreeRoot, oldActiveRoot_from_proof);
        if (MINT_AMOUNT != mintAmount_from_proof) revert IncorrectMintAmount(MINT_AMOUNT, mintAmount_from_proof);
        if (!mintVerifier.verifyProof(a, b, c, pubSignals)) revert InvalidProof();

        totalSupply += MINT_AMOUNT;
        activeSubtreeRoot = newActiveRoot;

        emit CommitmentAppended(state.currentSubtreeIndex, newCommitment, state.nextLeafIndexInSubtree, block.timestamp);
        state.nextLeafIndexInSubtree++;

        emit Minted(msg.sender, newCommitment, _encryptedNote, state.currentSubtreeIndex, state.nextLeafIndexInSubtree-1, block.timestamp);
    }

    function _mintAndRollover(bytes calldata _proof, bytes calldata _encryptedNote) internal {
        if (state.nextLeafIndexInSubtree != SUBTREE_CAPACITY) revert InvalidStateForRollover();

        (uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[7] memory pubSignals) =
            abi.decode(_proof, (uint[2], uint[2][2], uint[2], uint[7]));

        bytes32 newActiveRoot = bytes32(pubSignals[0]);
        bytes32 newFinalizedRoot = bytes32(pubSignals[1]);
        bytes32 oldActiveRoot_from_proof = bytes32(pubSignals[2]);
        bytes32 oldFinalizedRoot_from_proof = bytes32(pubSignals[3]);
        bytes32 newCommitment = bytes32(pubSignals[4]);
        uint256 mintAmount_from_proof = pubSignals[5];
        uint256 subtreeIndex_from_proof = pubSignals[6];

        if (commitmentHashes[newCommitment]) revert CommitmentAlreadyExists(newCommitment);
        commitmentHashes[newCommitment] = true;

        if (activeSubtreeRoot != oldActiveRoot_from_proof) revert OldActiveRootMismatch(activeSubtreeRoot, oldActiveRoot_from_proof);
        if (finalizedRoot != oldFinalizedRoot_from_proof) revert OldFinalizedRootMismatch(finalizedRoot, oldFinalizedRoot_from_proof);
        if (MINT_AMOUNT != mintAmount_from_proof) revert IncorrectMintAmount(MINT_AMOUNT, mintAmount_from_proof);
        if (state.currentSubtreeIndex != subtreeIndex_from_proof) revert IncorrectSubtreeIndex(state.currentSubtreeIndex, subtreeIndex_from_proof);

        if (!mintRolloverVerifier.verifyProof(a, b, c, pubSignals)) revert InvalidProof();

        emit SubtreeFinalized(state.currentSubtreeIndex, activeSubtreeRoot);

        activeSubtreeRoot = newActiveRoot;
        finalizedRoot = newFinalizedRoot;
        state.currentSubtreeIndex++;
        state.nextLeafIndexInSubtree = 0;

        totalSupply += MINT_AMOUNT;

        emit CommitmentAppended(state.currentSubtreeIndex, newCommitment, state.nextLeafIndexInSubtree, block.timestamp);
        state.nextLeafIndexInSubtree++;

        emit Minted(msg.sender, newCommitment, _encryptedNote, state.currentSubtreeIndex, state.nextLeafIndexInSubtree-1, block.timestamp);
    }

    // ===================================
    //        TRANSFER INTERFACE
    // ===================================

    /**
     * @notice Executes a privacy-preserving transfer
     * @param proofType 0=Active, 1=Finalized, 2=Rollover
     * @param proof ABI-encoded zk-SNARK proof with public signals
     * @param encryptedNotes Encrypted notes for recipients
     */
    function transfer(
        uint8 proofType,
        bytes calldata proof,
        bytes[] calldata encryptedNotes
    ) external override {
        if (proofType == 0) {
            _transferActive(proof, encryptedNotes);
        } else if (proofType == 1) {
            _transferFinalized(proof, encryptedNotes);
        } else if (proofType == 2) {
            _transferAndRollover(proof, encryptedNotes);
        } else {
            revert InvalidProofType(proofType);
        }
    }

    function _transferActive(bytes calldata _proof, bytes[] calldata _encryptedNotes) internal {
        (uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[12] memory pubSignals) =
            abi.decode(_proof, (uint[2], uint[2][2], uint[2], uint[12]));

        bytes32 newActiveSubTreeRoot = bytes32(pubSignals[2]);
        uint256 numRealOutputs = pubSignals[3];
        bytes32 oldActiveSubTreeRoot = bytes32(pubSignals[4]);

        uint256 availableCapacity = uint256(SUBTREE_CAPACITY - state.nextLeafIndexInSubtree);
        if (numRealOutputs > availableCapacity) revert SubtreeCapacityExceeded(numRealOutputs, availableCapacity);
        if (activeSubtreeRoot != oldActiveSubTreeRoot) revert OldActiveRootMismatch(activeSubtreeRoot, oldActiveSubTreeRoot);
        if (!activeTransferVerifier.verifyProof(a, b, c, pubSignals)) revert InvalidProof();

        activeSubtreeRoot = newActiveSubTreeRoot;

        TransactionData memory data;
        data.ephemeralPublicKey = [pubSignals[0], pubSignals[1]];
        data.nullifiers = [bytes32(pubSignals[5]), bytes32(pubSignals[6])];
        data.commitments = [bytes32(pubSignals[7]), bytes32(pubSignals[8])];
        data.viewTag = pubSignals[11];

        _processTransaction(data, _encryptedNotes);
    }

    function _transferFinalized(bytes calldata _proof, bytes[] calldata _encryptedNotes) internal {
        (uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[13] memory pubSignals) =
            abi.decode(_proof, (uint[2], uint[2][2], uint[2], uint[13]));

        bytes32 newActiveRoot = bytes32(pubSignals[2]);
        uint256 numRealOutputs = pubSignals[3];
        bytes32 oldFinalizedRoot = bytes32(pubSignals[4]);
        bytes32 oldActiveRoot = bytes32(pubSignals[5]);

        uint256 availableCapacity = uint32(SUBTREE_CAPACITY - state.nextLeafIndexInSubtree);
        if (numRealOutputs > availableCapacity) revert SubtreeCapacityExceeded(numRealOutputs, availableCapacity);
        if (activeSubtreeRoot != oldActiveRoot) revert OldActiveRootMismatch(activeSubtreeRoot, oldActiveRoot);
        if (finalizedRoot != oldFinalizedRoot) revert OldFinalizedRootMismatch(finalizedRoot, oldFinalizedRoot);
        if (!finalizedTransferVerifier.verifyProof(a, b, c, pubSignals)) revert InvalidProof();

        activeSubtreeRoot = newActiveRoot;

        TransactionData memory data;
        data.ephemeralPublicKey = [pubSignals[0], pubSignals[1]];
        data.nullifiers = [bytes32(pubSignals[6]), bytes32(pubSignals[7])];
        data.commitments = [bytes32(pubSignals[8]), bytes32(pubSignals[9])];
        data.viewTag = pubSignals[12];

        _processTransaction(data, _encryptedNotes);
    }

    function _transferAndRollover(bytes calldata _proof, bytes[] calldata _encryptedNotes) internal {
        (uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[12] memory pubSignals) =
            abi.decode(_proof, (uint[2], uint[2][2], uint[2], uint[12]));

        bytes32 newActive = bytes32(pubSignals[2]);
        bytes32 newFinalized = bytes32(pubSignals[3]);
        bytes32 oldActive = bytes32(pubSignals[4]);
        bytes32 oldFinalized = bytes32(pubSignals[5]);
        uint256 subtreeIndex_from_proof = pubSignals[11];

        if (state.nextLeafIndexInSubtree != SUBTREE_CAPACITY) revert InvalidStateForRollover();
        if (activeSubtreeRoot != oldActive) revert OldActiveRootMismatch(activeSubtreeRoot, oldActive);
        if (finalizedRoot != oldFinalized) revert OldFinalizedRootMismatch(finalizedRoot, oldFinalized);
        if (state.currentSubtreeIndex != subtreeIndex_from_proof) revert IncorrectSubtreeIndex(state.currentSubtreeIndex, subtreeIndex_from_proof);
        if (!rolloverTransferVerifier.verifyProof(a, b, c, pubSignals)) revert InvalidProof();

        emit SubtreeFinalized(state.currentSubtreeIndex, activeSubtreeRoot);

        activeSubtreeRoot = newActive;
        finalizedRoot = newFinalized;
        state.currentSubtreeIndex++;
        state.nextLeafIndexInSubtree = 0;

        TransactionData memory data;
        data.ephemeralPublicKey = [pubSignals[0], pubSignals[1]];
        data.nullifiers = [bytes32(pubSignals[6]), bytes32(0)];
        data.commitments = [bytes32(pubSignals[7]), bytes32(0)];
        data.viewTag = pubSignals[10];

        _processTransaction(data, _encryptedNotes);
    }

    // ===================================
    //        INTERNAL HELPERS
    // ===================================

    function _processTransaction(
        TransactionData memory _data,
        bytes[] calldata _encryptedNotes
    ) internal {
        // Spend Nullifiers
        for (uint32 i = 0; i < _data.nullifiers.length; i++) {
            bytes32 n = _data.nullifiers[i];
            if (n != bytes32(0)) {
                if (nullifiers[n]) revert DoubleSpend(n);
                nullifiers[n] = true;
                emit NullifierSpent(n);
            }
        }

        // Append Commitments
        for (uint i = 0; i < _data.commitments.length; i++) {
            bytes32 c = _data.commitments[i];
            if (c != bytes32(0)) {
                emit CommitmentAppended(state.currentSubtreeIndex, c, state.nextLeafIndexInSubtree, block.timestamp);
                state.nextLeafIndexInSubtree++;
                if (state.nextLeafIndexInSubtree >= SUBTREE_CAPACITY) revert InvalidStateForRegularMint();
            }
        }
        emit Transaction(_data.commitments, _encryptedNotes, _data.ephemeralPublicKey, _data.viewTag);
    }

    // ===================================
    //        FEE DISTRIBUTION
    // ===================================

    function distributeFees() external nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoFeesToDistribute();

        uint256 platformAmount = (balance * platformFeeBps) / 10000;
        uint256 initiatorAmount = balance - platformAmount;

        if (platformAmount > 0) {
            (bool success1, ) = platformTreasury.call{value: platformAmount}("");
            if (!success1) revert FeeTransferFailed();
        }

        if (initiatorAmount > 0) {
            (bool success2, ) = initiator.call{value: initiatorAmount}("");
            if (!success2) revert FeeTransferFailed();
        }
    }

    // ===================================
    //        ADDITIONAL EVENTS
    // ===================================

    event SubtreeFinalized(uint32 indexed subtreeIndex, bytes32 root);
}


// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVerifier {
    /**
     * @dev Verifies a ZK-SNARK proof.
     * @param _pA The A point of the proof.
     * @param _pB The B point of the proof.
     * @param _pC The C point of the proof.
     * @param _pubSignals An array of public signals. The length and order
     *                    must match what the specific verifier expects.
     * @return bool True if the proof is valid.
     */
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[] calldata _pubSignals
    ) external view returns (bool);
}


interface IMintVerifier {
    /**
     * @dev Verifies a ZK-SNARK proof.
     * @param _pA The A point of the proof.
     * @param _pB The B point of the proof.
     * @param _pC The C point of the proof.
     * @param _pubSignals An array of public signals. The length and order
     *                    must match what the specific verifier expects.
     * @return bool True if the proof is valid.
     */
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[4] calldata _pubSignals
    ) external view returns (bool);
}

interface IMintRolloverVerifier {
    /**
     * @dev Verifies a ZK-SNARK proof.
     * @param _pA The A point of the proof.
     * @param _pB The B point of the proof.
     * @param _pC The C point of the proof.
     * @param _pubSignals An array of public signals. The length and order
     *                    must match what the specific verifier expects.
     * @return bool True if the proof is valid.
     */
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[7] calldata _pubSignals
    ) external view returns (bool);
}

interface ITransferRolloverVerifier {
    /**
     * @dev Verifies a ZK-SNARK proof.
     * @param _pA The A point of the proof.
     * @param _pB The B point of the proof.
     * @param _pC The C point of the proof.
     * @param _pubSignals An array of public signals. The length and order
     *                    must match what the specific verifier expects.
     *                    Updated to 13 to include conversionAmount output.
     * @return bool True if the proof is valid.
     */
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[13] calldata _pubSignals
    ) external view returns (bool);
}

//ProveActiveTransferVerifier
interface IActiveTransferVerifier {
    /**
     * @dev Verifies a ZK-SNARK proof.
     * @param _pA The A point of the proof.
     * @param _pB The B point of the proof.
     * @param _pC The C point of the proof.
     * @param _pubSignals An array of public signals. The length and order
     *                    must match what the specific verifier expects.
     *                    Updated to 13 to include conversionAmount output.
     * @return bool True if the proof is valid.
     */
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[13] calldata _pubSignals
    ) external view returns (bool);
}

interface IFinalizedTransferVerifier {
    /**
     * @dev Verifies a ZK-SNARK proof.
     * @param _pA The A point of the proof.
     * @param _pB The B point of the proof.
     * @param _pC The C point of the proof.
     * @param _pubSignals An array of public signals. The length and order
     *                    must match what the specific verifier expects.
     *                    Updated to 14 to include conversionAmount output.
     * @return bool True if the proof is valid.
     */
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[14] calldata _pubSignals
    ) external view returns (bool);
}

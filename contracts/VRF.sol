// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@kenshi.io/vrf-consumer/contracts/VRFUtils.sol";

contract VRFOracle {
    address private _owner;
    address private _oracle;
    uint256 private _requestId;
    VRFUtils private _utils;
    mapping(uint256 => bool) private _alreadyFulfilled;

    constructor(bytes memory publicKey) {
        _owner = msg.sender;
        _utils = new VRFUtils();
        _utils.setPublicKey(publicKey);
    }

    /**
     * Sets the oracle address to prevent anyone else from
     * calling the "setVRF" method
     */
    function setOracle(address oracle) external {
        require(msg.sender == _owner, "Only owner can call this");
        _oracle = oracle;
    }

    // A simple event to make randomness requests
    event RandomnessRequest(uint256 requestId);
    event RandomnessRequestFulfilled(uint256 requestId, uint256 randomness);

    /**
     * Emit an event that will be picked up by the Kenshi
     * Oracle Network and sent to your oracle for processing
     */
    function requestRandomness() external {
        emit RandomnessRequest(_requestId++);
    }

    /**
     * This method will be called by the Kenshi Oracle Network
     * with the result returned from your oracle
     *
     * Note: We encourage reading the IETF ECVRF drafts to understand
     * what's going on: https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf
     */
    function setRandomness(
        uint256[4] memory proof,
        bytes memory message,
        uint256[2] memory uPoint,
        uint256[4] memory vComponents,
        uint256 requestId
    ) external {
        require(msg.sender == _oracle, "Only the oracle can deliver!");
        require(!_alreadyFulfilled[requestId], "Already fulfilled");
        _alreadyFulfilled[requestId] = true;
        bool isValid = _utils.fastVerify(proof, message, uPoint, vComponents);
        require(
            isValid,
            "Delivered randomness is not valid or is tampered with!"
        );
        bytes32 beta = _utils.gammaToHash(proof[0], proof[1]);
        uint256 randomness = uint256(beta);
        emit RandomnessRequestFulfilled(requestId, randomness);
    }
}

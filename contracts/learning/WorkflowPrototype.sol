// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Lernpfad Tag 11–14 — Vollständige State Machine
/// @notice Basis: VCdeterministic.sol (MilestoneRelease)
/// @dev Remix-Link:
/// https://remix.ethereum.org/#url=https://raw.githubusercontent.com/buenje/plan-approval-logic/main/contracts/learning/Tag14_Vollstaendig.sol

// ================================================================
// TAG 11–12 — State Machine mit Rollen und kombinierten modifiers
// ================================================================

/// @notice Meilenstein-Freigabe: drei Rollen, vier Zustände
/// @dev Direkte Vorstufe zu WorkflowPFV — dasselbe Muster, kleiner Maßstab
contract Tag11_MilestoneRelease {

    // Vier Zustände — strenge Reihenfolge
    enum State {
        Defined,            // Meilenstein definiert
        EvidenceSubmitted,  // Nachweis eingereicht
        Verified,           // Nachweis geprüft
        Released            // Freigabe erteilt
    }

    State public state;

    // Drei Rollen — jede darf nur einen Schritt auslösen
    address public founder;
    address public verifier;
    address public gp;

    event StateChanged(State from, State to);

    error WrongState();
    error NotAuthorized();

    // modifier mit Parameter — wiederverwendbar für alle Rollen
    modifier only(address a) {
        if (msg.sender != a) revert NotAuthorized();
        _;
    }

    // modifier prüft ob Contract im richtigen Zustand ist
    modifier inState(State s) {
        if (state != s) revert WrongState();
        _;
    }

    constructor(address _founder, address _verifier, address _gp) {
        founder = _founder;
        verifier = _verifier;
        gp = _gp;
        state = State.Defined;
    }

    // Jede Funktion kombiniert zwei modifier — Rolle + Zustand
    function submitEvidence() external only(founder) inState(State.Defined) {
        _set(State.EvidenceSubmitted);
    }

    function verify() external only(verifier) inState(State.EvidenceSubmitted) {
        _set(State.Verified);
    }

    function release() external only(gp) inState(State.Verified) {
        _set(State.Released);
    }

    // internal = nur innerhalb des Contracts aufrufbar
    function _set(State next) internal {
        emit StateChanged(state, next);
        state = next;
    }

    // TODO Tag 11: Deploye den Contract mit drei verschiedenen Adressen.
    // Versuche verify() aufzurufen bevor submitEvidence() — was passiert?
    // Warum schlägt es fehl?

    // TODO Tag 12: Vergleiche diesen Contract mit WorkflowPFV.
    // Was ist gleich? Was ist komplexer in WorkflowPFV?
    // Schreibe drei Unterschiede auf.
}

// ================================================================
// TAG 13–14 — Erweiterung: bytes32, Hashes, Verbindung zu Fundament
// ================================================================

contract Tag13_MilestoneWithHash {

    enum State {
        Defined,
        EvidenceSubmitted,
        Verified,
        Released
    }

    State public state;

    address public founder;
    address public verifier;
    address public gp;

    // bytes32 = kryptographischer Hash — Kernkonzept von Fundament
    bytes32 public evidenceHash;

    event StateChanged(State from, State to);
    event EvidenceAnchored(bytes32 indexed hash, address indexed by);

    error WrongState();
    error NotAuthorized();

    modifier only(address a) {
        if (msg.sender != a) revert NotAuthorized();
        _;
    }

    modifier inState(State s) {
        if (state != s) revert WrongState();
        _;
    }

    constructor(address _founder, address _verifier, address _gp) {
        founder = _founder;
        verifier = _verifier;
        gp = _gp;
        state = State.Defined;
    }

    // Nachweis einreichen + Hash verankern
    function submitEvidence(bytes32 _hash) external only(founder) inState(State.Defined) {
        evidenceHash = _hash;
        emit EvidenceAnchored(_hash, msg.sender);
        _set(State.EvidenceSubmitted);
    }

    function verify() external only(verifier) inState(State.EvidenceSubmitted) {
        _set(State.Verified);
    }

    function release() external only(gp) inState(State.Verified) {
        _set(State.Released);
    }

    function _set(State next) internal {
        emit StateChanged(state, next);
        state = next;
    }

    // TODO Tag 13: Erzeuge einen Hash in Remix:
    // keccak256(abi.encodePacked("mein_dokument.pdf")) 
    // Übergib ihn an submitEvidence().
    // Lies evidenceHash — was siehst du?

    // TODO Tag 14: Das ist Fundament im Kleinen.
    // Erkläre in einem Satz wie dieser Contract und WorkflowPFV
    // zusammenhängen.
    // Was würde Fundament als Infrastrukturschicht hinzufügen?
}
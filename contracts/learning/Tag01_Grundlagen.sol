[Dateiin// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Lernpfad Tag 1–6 — Grundlagen
/// @notice Basis: Counter.sol + ToggelLock.sol + DonatePause.sol
/// @dev Kein lokales Setup nötig — in Remix öffnen:
/// https://remix.ethereum.org/#url=https://raw.githubusercontent.com/buenje/plan-approval-logic/main/contracts/learning/Tag01_Grundlagen.sol

// ================================================================
// TAG 1 — State lesen und schreiben, Events beobachten
// ================================================================

contract Tag01_Counter {

    uint256 private _count;
    address public immutable owner;

    event Incremented(uint256 newValue, address indexed by);
    event Reset(uint256 oldValue, address indexed by);

    constructor(uint256 initial) {
        owner = msg.sender;
        _count = initial;
    }

    // Blauer Button = lesen (kein Chain-Eintrag)
    function count() external view returns (uint256) {
        return _count;
    }

    // Oranger Button = schreiben (erzeugt Transaktion)
    function increment() external {
        _count += 1;
        emit Incremented(_count, msg.sender);
    }

    // TODO Tag 1: Klick increment() dreimal.
    // Lies count() nach jedem Klick. Was ändert sich im Event-Log?

    function reset() external {
        require(msg.sender == owner, "not owner");
        uint256 old = _count;
        _count = 0;
        emit Reset(old, msg.sender);
    }

    // TODO Tag 2: Provoziere den Fehler in reset().
    // Wechsle die Adresse in Remix (Account-Dropdown) und ruf reset() auf.
    // Ändere danach die Fehlermeldung auf Deutsch: "nicht berechtigt"
}

// ================================================================
// TAG 3–4 — modifier, custom error, toggle pattern
// ================================================================

contract Tag03_ToggelLock {

    address public immutable owner;
    bool public locked;

    event Locked(address indexed by);
    event Unlocked(address indexed by);

    error NotOwner();

    constructor() {
        owner = msg.sender;
        locked = false;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function lock() external onlyOwner {
        locked = true;
        emit Locked(msg.sender);
    }

    function unlock() external onlyOwner {
        locked = false;
        emit Unlocked(msg.sender);
    }

    // TODO Tag 3: Ergänze timestamp als zweiten Parameter im Event:
    // event Locked(address indexed by, uint256 timestamp);
    // Passe lock() an: emit Locked(msg.sender, block.timestamp);

    // TODO Tag 4: Ersetze bool locked durch einen enum:
    // enum LockState { Unlocked, Locked, Maintenance }
    // LockState public state;
    // Was ändert sich beim Lesen des Zustands in Remix?
}

// ================================================================
// TAG 5–6 — payable, modifier kombinieren, Pause-Muster
// ================================================================

contract Tag05_DonatePause {

    address public immutable owner;
    bool private _paused;

    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event Donated(address indexed from, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "nicht berechtigt");
        _;
    }

    modifier notPaused() {
        require(!_paused, "pausiert");
        _;
    }

    constructor() {
        owner = msg.sender;
        _paused = false;
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    function pause() external onlyOwner {
        require(!_paused, "schon pausiert");
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        require(_paused, "nicht pausiert");
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function donate() external payable notPaused {
        require(msg.value > 0, "kein Betrag");
        emit Donated(msg.sender, msg.value);
    }

    function sweep() external onlyOwner {
        (bool ok,) = owner.call{value: address(this).balance}("");
        require(ok, "Überweisung fehlgeschlagen");
    }

    receive() external payable {}

    // TODO Tag 5: Teste die Reihenfolge:
    // 1. pause() aufrufen
    // 2. donate() versuchen — was passiert?
    // 3. unpause() aufrufen
    // 4. donate() mit Wert (Value-Feld in Remix) aufrufen

    // TODO Tag 6: Füge einen dritten modifier hinzu:
    // modifier onlyWhenLocked() { require(_paused, "nicht pausiert"); _; }
    // Wofür könnte das nützlich sein?
}halt hier einfügen]

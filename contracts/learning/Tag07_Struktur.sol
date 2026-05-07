// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Lernpfad Tag 7–10 — Strukturen und Mappings
/// @notice Basis: SafeShop.sol + SafeVault.sol
/// @dev Remix-Link:
/// https://remix.ethereum.org/#url=https://raw.githubusercontent.com/buenje/plan-approval-logic/main/contracts/learning/Tag07_Struktur.sol

// ================================================================
// TAG 7–8 — struct, mapping, Pause-Muster kombiniert
// ================================================================

contract Tag07_SafeShop {

    address public immutable i_owner;
    bool public isPaused;

    // struct = zusammengesetzte Datenstruktur
    struct Customer {
        uint256 totalSpent;
        bool isVip;
    }

    // mapping = Adressbuch: Adresse → Customer
    mapping(address => Customer) public customers;

    constructor() {
        i_owner = msg.sender;
    }

    function deposit() external payable {
        require(!isPaused, "Shop pausiert");

        // Struct direkt über mapping aktualisieren
        customers[msg.sender].totalSpent += msg.value;

        // Logik: Wer mehr als 1 Ether zahlt wird VIP
        if (customers[msg.sender].totalSpent >= 1 ether) {
            customers[msg.sender].isVip = true;
        }
    }

    function togglePause() external {
        require(msg.sender == i_owner, "Nicht Chef");
        isPaused = !isPaused;
    }

    // TODO Tag 7: Lies customers[deineAdresse] in Remix.
    // Was siehst du vor und nach deposit()?
    // Warum hat der Struct zwei Felder?

    // TODO Tag 8: Füge ein Event hinzu:
    // event VipUpgrade(address indexed kunde, uint256 totalSpent);
    // Emittiere es wenn isVip auf true gesetzt wird.
}

// ================================================================
// TAG 9–10 — Checks-Effects-Interactions Pattern
// ================================================================

contract Tag09_SafeVault {

    // mapping: Jede Adresse hat ihr eigenes Guthaben
    mapping(address => uint256) public balances;

    // 1. DEPOSIT: Geld einzahlen
    // 'payable' erlaubt dem Contract Ether anzunehmen
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 2. WITHDRAW: Alles abheben
    // WICHTIG: Reihenfolge ist entscheidend — Checks-Effects-Interactions
    function withdrawAll() external {

        // CHECK: Wie viel hat der User?
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Kein Guthaben vorhanden");

        // EFFECT: Guthaben auf 0 setzen VOR dem Senden
        // Warum? Schutz gegen Reentrancy-Angriff
        balances[msg.sender] = 0;

        // INTERACTION: Geld senden
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer fehlgeschlagen");
    }

    // TODO Tag 9: Teste die Reihenfolge in Remix:
    // 1. deposit() mit 1 ETH aufrufen
    // 2. balances[deineAdresse] lesen — was siehst du?
    // 3. withdrawAll() aufrufen
    // 4. balances[deineAdresse] nochmal lesen — was jetzt?

    // TODO Tag 10: Was passiert wenn du withdrawAll() zweimal
    // hintereinander aufrufst? Warum schlägt der zweite fehl?
    // Erkläre den Checks-Effects-Interactions Pattern in einem Satz.
}
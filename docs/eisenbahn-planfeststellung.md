# Blockchain in Railway Planning Procedures: Technical Documentation

**Companion documentation to a journal article in *Eisenbahntechnische Rundschau (ETR)*, Issue 5/2026.**

*This documentation and the accompanying article were created privately as author contributions. They do not represent the position of any authority or employer. The basis is exclusively publicly available legal sources; internal rules of individual authorities or companies have not been incorporated.*

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Principles](#architecture-principles)
3. [Smart Contract Design](#smart-contract-design)
4. [Procedure Walkthrough](#procedure-walkthrough)
5. [Implementation Details](#implementation-details)
6. [Security & Privacy](#security--privacy)
7. [Deployment Scenarios](#deployment-scenarios)

---

## Overview

### What Is a *Planfeststellungsverfahren*?

A *Planfeststellungsverfahren* (planning approval procedure) is the formal legal process required in Germany before major infrastructure projects — railways, motorways, waterways — can be constructed. It is governed by the Administrative Procedure Act (*Verwaltungsverfahrensgesetz*, VwVfG) and, for railways specifically, by § 18 of the General Railway Act (*Allgemeines Eisenbahngesetz*, AEG).

The procedure involves:
- The **project sponsor** (*Vorhabenträger*) submitting a complete application with technical plans
- A **planning authority** (*Planfeststellungsbehörde*) — here, the Federal Railway Authority (*Eisenbahn-Bundesamt*, EBA) — leading the process
- Mandatory **public display** of documents and a formal **objection period**
- Consultation of **public bodies** (*Träger öffentlicher Belange*, TÖB)
- A final legally binding **planning decision** (*Planfeststellungsbeschluss*)

The process is inherently multi-party, deadline-driven, and subject to strict formal requirements. These properties make it a strong candidate for workflow automation.

### Why Blockchain?

Three properties of distributed ledger technology are relevant here:

| Property | Benefit in this context |
|---|---|
| **Immutability** | Phase transitions and document anchors cannot be altered retroactively |
| **Transparency** | All participants can verify deadlines were met and objections were received — without filing information requests |
| **Automated gates** | Formal prerequisites for each procedural step are enforced by code, not by manual checklist |

### What Blockchain Cannot Do

- Replace substantive legal judgment
- Automate official decisions (*hoheitliche Entscheidungen*)
- Reduce the inherent complexity of the procedure
- Guarantee that off-chain documents are correct

The smart contract enforces **procedural formality only**. The competent authority retains full decision-making power.

### Legal Framework

| Provision | Relevance |
|---|---|
| § 18 AEG | Defines the planning approval requirement for railways |
| §§ 72 ff. VwVfG | Governs the phases, deadlines, and participation rights |
| § 3a VwVfG | Digital documents in administrative procedures |
| § 73 Abs. 4 VwVfG | Objection deadlines and preclusion |
| § 371a ZPO | Evidentiary value of digital documents |
| Art. 5, 17 GDPR | Data minimisation and right to erasure |

---

## Architecture Principles

### 1. Off-Chain / On-Chain Separation

The core design decision: **no document contents and no personal data reach the blockchain**.

```
┌────────────────────────────────────────┐
│  OFF-CHAIN (Data & Work Processes)     │
│  ─────────────────────────────────────│
│  • E-file / Document management system │
│  • Application and participation portal│
│  • Personal data                       │
│  • Original documents (PDF, CAD, BIM)  │
│  • Specialist systems (GIS, etc.)      │
└──────────────┬─────────────────────────┘
               │  cryptographic hashes only
               ▼
┌────────────────────────────────────────┐
│  ON-CHAIN (Evidence & Control)         │
│  ─────────────────────────────────────│
│  • Hash registry (document versions)   │
│  • Smart contracts (workflow logic)    │
│  • Event log (audit trail)             │
│  • Role assignments (access control)   │
└────────────────────────────────────────┘
```

The link between off-chain documents and on-chain anchors is established exclusively through cryptographic hashes (32 bytes). Anyone holding the original document can verify that it matches the on-chain anchor. The blockchain proves *that* a document existed at a specific time in a specific version — not *what* it contains.

### 2. Permissioned Consortium Network

This design is intended for a **private, authority-controlled network**, not a public blockchain:

- **Consensus:** Proof of Authority (PoA) — known, accountable validators
- **Participants:** Designated government bodies and approved stakeholders
- **Compatibility:** EVM-compatible infrastructure

This is distinct from decentralised public networks. The goal is tamper-proof record-keeping within a trusted consortium, not trustless global consensus.

### 3. Legal Engineering Mapping

Legal requirements translate directly into code constructs:

| Legal requirement | Legal basis | Technical implementation |
|---|---|---|
| Deadline enforcement / preclusion | § 73 Abs. 4 VwVfG | `modifier onlyBeforeDeadline()` |
| Digital document submission | § 3a Abs. 2 VwVfG | `function submitObjection(bytes32 _hash)` |
| Public notification | § 73 Abs. 5 VwVfG | `event ObjectionRegistered(...)` |
| Immutability of records | Rule-of-law principle | `mapping(bytes32 => Objection) private objections` |

---

## Smart Contract Design

### State Machine: Procedure Phases

```solidity
enum Status {
    Einreichung,        // 0: Application submitted
    Vollstaendigkeit,   // 1: Completeness review
    Auslegung,          // 2: Public display + TÖB consultation
    Abwaegung,          // 3: Consideration of objections
    BeschlussEntwurf,   // 4: Internal draft decision
    Beschluss,          // 5: Planning decision issued
    Rechtskraft         // 6: Decision becomes legally binding
}
```

The contract stores the current phase for each procedure. Phase transitions are the only way to advance a dossier. No phase can be skipped.

### Workflow Gates

Each phase transition is conditional on all gate requirements being met. The Planning Department triggers the transition; the contract validates the conditions.

#### Gate 1: Submission → Completeness Review
```solidity
function _checkGate_Vollstaendigkeit(bytes32 _dossierId) internal view {
    Verfahren memory v = verfahren[_dossierId];

    // Required: Merkle root set (document package anchored)
    require(v.merkleRoot != bytes32(0), "Planunterlagen fehlen");

    // Required: Applicant address registered
    require(v.vorhabentraeger != address(0), "Vorhabentraeger ungueltig");
}
```

#### Gate 2: Completeness → Public Display
```solidity
function _checkGate_Auslegung(bytes32 _dossierId) internal view {
    Verfahren memory v = verfahren[_dossierId];

    // Required: Completeness formally confirmed
    require(v.vollstaendigkeitBestaetigt, "Vollstaendigkeit nicht bestaetigt");

    // Required: Display period set in the future
    require(v.auslegungsfrist > block.timestamp, "Auslegungsfrist ungueltig");
}
```

#### Gate 3: Public Display → Hearing
```solidity
function _checkGate_Anhoerung(bytes32 _dossierId) internal view {
    Verfahren memory v = verfahren[_dossierId];

    // Required: Display period has expired
    require(block.timestamp > v.auslegungsfrist, "Auslegungsfrist laeuft noch");

    // Required: TÖB consultation completed
    require(v.toebBeteiligt, "TOEB-Beteiligung nicht abgeschlossen");
}
```

#### Gate 4: Hearing → Draft Decision
```solidity
function _checkGate_Beschluss(bytes32 _dossierId) internal view {
    Verfahren memory v = verfahren[_dossierId];

    // Required: All objections formally addressed
    require(v.offeneEinwendungen == 0, "Noch offene Einwendungen");
}
```

### Event Trail

Every action is logged as an on-chain event — permanently, in order, with timestamp and actor:

```solidity
event Fortschritt(
    bytes32 indexed dossierId,
    Status von,
    Status nach,
    uint256 zeitstempel,
    address initiator
);

event DokumentVerankert(
    bytes32 indexed dossierId,
    bytes32 indexed dokumentId,
    bytes32 hash,
    uint256 zeitstempel
);

event EinwendungEingereicht(
    bytes32 indexed dossierId,
    bytes32 indexed einwendungsId,
    address einwender,
    uint256 zeitstempel,
    bool fristgerecht
);
```

The complete procedure history can be reconstructed from events alone. This is the audit trail.

---

## Procedure Walkthrough

A complete run through all seven phases. All identifiers are fictional and for demonstration only.

```solidity
// 1. SUBMISSION (project sponsor)
bytes32 dossierId = keccak256("DEMO_PROJECT_0001");
bytes32 merkleRoot = calculateMerkleRoot(planDocuments);
workflow.verfahrenEinreichen(dossierId, merkleRoot);

// 2. COMPLETENESS REVIEW (Planning Department)
workflow.vollstaendigkeitPruefen(dossierId, true);
// → Status changes to "Vollstaendigkeit"

// 3. START PUBLIC DISPLAY (Planning Department)
uint256 displayEnd = block.timestamp + 30 days;
workflow.auslegungStarten(dossierId, displayEnd);
// → Status changes to "Auslegung"
// → Portal opens for public objections

// 4. OBJECTION (member of the public)
bytes32 objectionHash = keccak256(abi.encodePacked(objectionText));
workflow.einwendungEinreichen(dossierId, objectionHash);
// → Event: EinwendungEingereicht

// 5. CLOSE CONSIDERATION (after display period)
workflow.abwaegungAbschliessen(dossierId);
// → Status changes to "Abwaegung"

// 6. ISSUE DECISION (Planning Department)
bytes32 decisionHash = keccak256(abi.encodePacked(decisionDocument));
workflow.beschlussErstellen(dossierId, decisionHash);
// → Status changes to "Beschluss"

// 7. LEGAL EFFECT (after challenge period expires)
workflow.rechtskraftFeststellen(dossierId);
// → Status changes to "Rechtskraft"
```

---

## Implementation Details

### Merkle Trees for Document Packages

**Problem:** A *Planfeststellungsverfahren* involves hundreds to thousands of documents (plans, expert reports, statements, correspondence).

**Solution:** A Merkle tree compresses all documents into a single 32-byte root hash:

```
         Root Hash (on-chain)
           /        \
        H(AB)      H(CD)
        /  \        /  \
      H(A) H(B)  H(C) H(D)
       |    |     |    |
     Doc1 Doc2 Doc3 Doc4
    (off-chain)
```

Any individual document can later be proven to be part of the package using a Merkle proof — without revealing any other documents.

```solidity
function calculateMerkleRoot(bytes32[] memory dokumentHashes)
    public
    pure
    returns (bytes32)
{
    uint256 n = dokumentHashes.length;
    require(n > 0, "Keine Dokumente");

    while (n > 1) {
        for (uint256 i = 0; i < n / 2; i++) {
            dokumentHashes[i] = keccak256(
                abi.encodePacked(
                    dokumentHashes[2 * i],
                    dokumentHashes[2 * i + 1]
                )
            );
        }
        if (n % 2 == 1) {
            dokumentHashes[n / 2] = dokumentHashes[n - 1];
            n = n / 2 + 1;
        } else {
            n = n / 2;
        }
    }
    return dokumentHashes[0];
}
```

### Objection Management

Public objections are submitted as hashes of the objection text. The actual text remains off-chain. The contract records receipt, timestamp, and whether the deadline was met:

```solidity
struct Einwendung {
    bytes32 einwendungsId;
    bytes32 dossierId;
    address einwender;
    bytes32 dokumentHash;       // Hash of objection text (off-chain)
    uint256 eingangsDatum;
    bool fristgerecht;          // Was the deadline met?
    bool bearbeitet;            // Has the authority addressed this?
}

function einwendungEinreichen(bytes32 _dossierId, bytes32 _dokumentHash)
    external
    verfahrenExistiert(_dossierId)
{
    Verfahren storage v = verfahren[_dossierId];
    require(v.status == Status.Auslegung, "Keine Auslegungsphase");

    bool fristgerecht = block.timestamp <= v.auslegungsfrist;

    bytes32 einwendungsId = keccak256(
        abi.encodePacked(_dossierId, msg.sender, block.timestamp)
    );

    einwendungen[einwendungsId] = Einwendung({
        einwendungsId: einwendungsId,
        dossierId: _dossierId,
        einwender: msg.sender,
        dokumentHash: _dokumentHash,
        eingangsDatum: block.timestamp,
        fristgerecht: fristgerecht,
        bearbeitet: false
    });

    verfahrenEinwendungen[_dossierId].push(einwendungsId);

    if (fristgerecht) {
        v.anzahlEinwendungen++;
        v.offeneEinwendungen++;
    }

    emit EinwendungEingereicht(
        _dossierId, einwendungsId, msg.sender, block.timestamp, fristgerecht
    );
}
```

Gate 4 cannot be passed until `offeneEinwendungen == 0` — meaning the authority has formally addressed every timely objection.

---

## Security & Privacy

### GDPR Compliance

**Art. 5(1)(e) GDPR — Storage limitation:**
Off-chain storage of all personal data. On-chain records contain only anonymous hashes.

**Art. 17 GDPR — Right to erasure:**
Personal data remains off-chain and can be deleted. On-chain hashes contain no information that allows identifying individuals.

**Art. 5(1)(b) GDPR — Purpose limitation:**
On-chain data is limited to what is necessary for procedural proof.

### Access Control

```solidity
modifier nurRolle(Role _rolle) {
    require(rollen[msg.sender] == _rolle, "Unzureichende Berechtigung");
    _;
}

modifier nurVerfahrensleitung() {
    require(
        rollen[msg.sender] == Role.Verfahrensleitung,
        "Nur Verfahrensleitung"
    );
    _;
}
```

Every function that changes state is protected by role-based modifiers. Unauthorised calls revert with an explicit error message.

### Override Mechanism

Automated gates can, in exceptional cases, conflict with administrative discretion. For example, the fiction effect under § 73 Abs. 3a VwVfG may allow a procedure to advance even if a gate condition is not formally satisfied in the expected way.

The override mechanism allows the Planning Department to bypass a gate with a mandatory written justification. The deviation is permanently recorded on-chain:

```solidity
event GateOverride(
    bytes32 indexed dossierId,
    Status von,
    Status nach,
    string begruendung,
    address initiator,
    uint256 zeitstempel
);

function overrideGate(
    bytes32 _dossierId,
    Status _neuerStatus,
    string memory _begruendung
)
    external
    nurVerfahrensleitung
{
    require(bytes(_begruendung).length > 20, "Begruendung zu kurz");

    Verfahren storage v = verfahren[_dossierId];
    Status alterStatus = v.status;
    v.status = _neuerStatus;

    emit GateOverride(
        _dossierId, alterStatus, _neuerStatus,
        _begruendung, msg.sender, block.timestamp
    );
}
```

The mechanism does not replace a legal decision. It ensures that any deviation from formal gate logic is cryptographically documented and remains traceable indefinitely.

---

## Deployment Scenarios

### Scenario 1: Shadow Run (Pilot)

The blockchain runs in parallel to the existing procedure without any legal effect. This phase validates assumptions, measures KPIs, and generates lessons learned.

- Duration: 6–12 months
- Risk: low — existing process unchanged
- Output: empirical data for go/no-go decision

### Scenario 2: Selected Integration

The blockchain is authoritative for selected procedural steps — for example, objection management and deadline tracking only. Other steps remain in legacy systems.

- Suitable for: high-value, high-risk sub-processes
- Allows incremental validation before full commitment

### Scenario 3: Full Integration

The complete procedure runs on-chain. Maximum transparency and process discipline.

- Prerequisite: successful piloting under Scenario 1 and 2
- Requires: legal and organisational adaptation, stakeholder training

---

## Glossary

| German term | English equivalent |
|---|---|
| Planfeststellungsverfahren | Planning approval procedure |
| Planfeststellungsbeschluss | Planning decision (legally binding) |
| Vorhabenträger | Project sponsor / applicant |
| Sachbereich Planfeststellung | Planning Department |
| Träger öffentlicher Belange (TÖB) | Public bodies with statutory consultation rights |
| Auslegungsfrist | Public display period |
| Einwendung | Formal objection |
| Rechtskraft | Legal finality / binding effect |
| Verwaltungsverfahrensgesetz (VwVfG) | Administrative Procedure Act |
| Allgemeines Eisenbahngesetz (AEG) | General Railway Act |
| Eisenbahn-Bundesamt (EBA) | Federal Railway Authority |

---

---

# Deutsch: Technische Dokumentation

**Begleitdokumentation zu einem Fachbeitrag in der Eisenbahntechnischen Rundschau (ETR), Ausgabe 5/2026.**

*Diese Dokumentation wie auch der zugehörige Fachbeitrag wurden privat und als Autorentätigkeit erstellt. Sie geben nicht die Position einer Behörde oder eines Dienstherrn wieder. Grundlage sind ausschließlich öffentlich zugängliche Rechtsquellen.*

---

### Inhaltsverzeichnis (DE)

1. [Überblick](#überblick-de)
2. [Architekturprinzipien](#architekturprinzipien-de)
3. [Smart Contract Design](#smart-contract-design-de)
4. [Implementierungsdetails](#implementierungsdetails-de)
5. [Sicherheit und Datenschutz](#sicherheit-und-datenschutz-de)
6. [Deployment-Szenarien](#deployment-szenarien-de)

---

### Überblick {#überblick-de}

#### Motivation

Planfeststellungsverfahren sind durch ihre Komplexität und lange Verfahrensdauer gekennzeichnet. Blockchain-Technologie bietet Potenzial zur Verbesserung der:

- **Nachvollziehbarkeit** aller Verfahrensschritte — lückenlose Dokumentation von Einreichungen, Zustellungen und Statusänderungen
- **Transparenz** gegenüber allen Beteiligten — Verfahrensstände und Dokumentenstatus sind eigenständig verifizierbar, ohne Akteneinsichtsantrag
- **Prozessdisziplin** durch automatisierte Gates — Verfahrensschritte können erst nach erfüllten Voraussetzungen fortschreiten

#### Abgrenzung

**Was Blockchain kann:** Dokumentenversionen fälschungssicher verankern · Verfahrensschritte automatisiert kontrollieren · lückenlose Protokollierung aller Aktionen.

**Was Blockchain nicht kann:** Juristische Abwägungen ersetzen · hoheitliche Entscheidungen automatisieren · Komplexität des Verfahrens grundsätzlich reduzieren.

#### Rechtlicher Rahmen

- § 18 AEG · §§ 72 ff. VwVfG · § 3a VwVfG · § 73 Abs. 4 VwVfG · § 371a ZPO · Art. 5, 17 DSGVO

---

### Architekturprinzipien {#architekturprinzipien-de}

#### Off-Chain / On-Chain Trennung

```
┌────────────────────────────────────────┐
│  OFF-CHAIN (Daten & Arbeitsprozesse)   │
│  ─────────────────────────────────────│
│  • E-Akte / Dokumentenmanagementsystem │
│  • Antrags- und Beteiligungsportal     │
│  • Personenbezogene Daten              │
│  • Originaldokumente (PDF, CAD)        │
│  • Fachverfahren (GIS, BIM)            │
└──────────────┬─────────────────────────┘
               │ nur kryptografische Hashes
               ▼
┌────────────────────────────────────────┐
│  ON-CHAIN (Beweise & Kontrolle)        │
│  ─────────────────────────────────────│
│  • Hash-Registry (Dokumentversionen)   │
│  • Smart Contracts (Workflow-Logik)    │
│  • Event-Log (Audit-Trail)             │
│  • Rollenverwaltung (Access Control)   │
└────────────────────────────────────────┘
```

#### Legal Engineering Mapping

| Rechtliche Anforderung | Rechtsgrundlage | Technische Implementierung |
|---|---|---|
| Präklusion / Fristen | § 73 Abs. 4 VwVfG | `modifier onlyBeforeDeadline()` |
| Schriftformersatz | § 3a Abs. 2 VwVfG | `function submitObjection(bytes32 _hash)` |
| Bekanntmachung | § 73 Abs. 5 VwVfG | `event ObjectionRegistered(...)` |
| Unveränderbarkeit | Rechtsstaatsprinzip | `mapping(bytes32 => Objection) private objections` |

---

### Smart Contract Design {#smart-contract-design-de}

#### State Machine

```solidity
enum Status {
    Einreichung,        // 0: Antrag eingereicht
    Vollstaendigkeit,   // 1: Vollständigkeitsprüfung
    Auslegung,          // 2: Öffentliche Auslegung + TÖB
    Abwaegung,          // 3: Abwägung der Einwendungen
    BeschlussEntwurf,   // 4: Beschlussentwurf intern
    Beschluss,          // 5: Planfeststellungsbeschluss
    Rechtskraft         // 6: Beschluss rechtskräftig
}
```

#### Workflow-Gates

Jeder Phasenwechsel ist an definierte Bedingungen geknüpft. Die vollständige Gate-Implementierung ist im englischen Teil dieser Dokumentation beschrieben.

#### Event-Trail

```solidity
event Fortschritt(
    bytes32 indexed dossierId,
    Status von,
    Status nach,
    uint256 zeitstempel,
    address initiator
);
```

Alle Verfahrensschritte werden unveränderlich als Events auf der Blockchain protokolliert. Die vollständige Verfahrensgeschichte kann aus den Events rekonstruiert werden.

---

### Implementierungsdetails {#implementierungsdetails-de}

#### Merkle-Bäume für Dokumentenpakete

Planfeststellungsverfahren umfassen hunderte bis tausende Dokumente. Ein Merkle-Baum verdichtet alle Dokumente zu einem einzigen 32-Byte-Hash. Einzelne Dokumente können später mit einem Merkle-Proof als Teil des Pakets bewiesen werden, ohne andere Dokumente offenzulegen.

#### Einwendungsmanagement

Einwendungen werden als Hashes eingereicht. Der Einwendungstext verbleibt off-chain. Der Contract protokolliert Eingang, Zeitstempel und Fristgerechtigkeit. Gate 4 kann erst passiert werden, wenn alle fristgerechten Einwendungen formal beantwortet wurden (`offeneEinwendungen == 0`).

#### Dokumentierte Abweichung (Override-Mechanismus)

Automatisierte Gates können in Ausnahmefällen den Verfahrensfortschritt formal blockieren, obwohl die rechtliche Voraussetzung auf anderem Wege erfüllt ist (z. B. Fiktionswirkung nach § 73 Abs. 3a VwVfG). Der Override-Mechanismus erlaubt der Verfahrensleitung eine begründete Abweichung. Die Abweichung wird vollständig und unveränderlich protokolliert. Die vollständige Implementierung ist im englischen Teil beschrieben.

---

### Sicherheit und Datenschutz {#sicherheit-und-datenschutz-de}

**Art. 5 Abs. 1 lit. e DSGVO (Speicherbegrenzung):** Gelöst durch Off-Chain-Speicherung aller personenbezogenen Daten. On-Chain nur anonyme Hashes.

**Art. 17 DSGVO (Recht auf Löschung):** Personenbezogene Daten verbleiben off-chain und können gelöscht werden. On-Chain-Hashes enthalten keine Rückschlüsse auf Personen.

---

### Deployment-Szenarien {#deployment-szenarien-de}

| Szenario | Setup | Dauer / Zweck |
|---|---|---|
| **Shadow-Run (Pilot)** | Blockchain läuft parallel, keine Rechtswirkung | 6–12 Monate Validierung |
| **Selektive Integration** | Blockchain verbindlich für ausgewählte Schritte (z. B. Einwendungsmanagement) | Schrittweise Integration |
| **Vollintegration** | Komplettes Verfahren läuft über Blockchain | Nach erfolgreicher Pilotierung |

---

**Autor:** Klaus Walter
**Version:** 2.0
**Stand:** Mai 2026
**Lizenz:** MIT

# Plan Approval Logic — Smart Contract for Railway Planning Procedures

> Technical demonstrator accompanying the journal article **"Blockchain in der Planfeststellung: Möglichkeiten für Effizienz und Nachvollziehbarkeit"**, published in *Eisenbahntechnische Rundschau (ETR)*, Issue 5/2026.

This repository contains a Solidity smart contract that models the procedural logic of a German railway planning approval procedure (*Planfeststellungsverfahren*) under § 18 AEG in conjunction with §§ 72 ff. VwVfG as a finite state machine. The project is a **research and demonstration proof-of-concept — not intended for production use**.

---

## Live Demo on Sepolia

The contract is deployed and verified on the Ethereum Sepolia testnet. Readers can inspect the source code and all transactions directly:

| | |
|---|---|
| **Contract Address** | `0x2aa68e465455e2da532dc4c8a64ceee52703f25e` |
| **Network** | Ethereum Sepolia Testnet |
| **Etherscan** | [sepolia.etherscan.io/address/0x2aa68e…3f25e](https://sepolia.etherscan.io/address/0x2aa68e465455e2da532dc4c8a64ceee52703f25e#code) |
| **Verification** | Source Code Verified (Exact Match) |

[Interactive Procedure Dashboard](https://buenje.github.io/plan-approval-logic/demo/WorkflowPFV_Demo.html)

> **Note:** The dashboard is a static prototype for illustration purposes — it has no live connection to the smart contract. It shows what a frontend for procedure participants could look like.

This demonstration runs on the Ethereum Sepolia testnet as a proof-of-concept. The underlying process logic is infrastructure-agnostic, permissioned ledgers or other cryptographic backends are equally applicable depending on compliance requirements.
---

## What This Is

German railway infrastructure projects require a formal multi-phase planning approval (*Planfeststellungsverfahren*) before construction can begin. The procedure involves dozens of stakeholders, public objection periods, mandatory deadlines, and legal compliance checks at every step.

This contract demonstrates how such a procedure can be modelled as a **finite state machine on a blockchain**: each phase transition is gated by formal prerequisites, every action is permanently logged, and no step can be skipped or falsified after the fact.

The smart contract enforces **procedural formality only**. Substantive legal judgment and official decision authority remain exclusively with the competent authority.

---

## Procedure Phases

Seven phases, six automated gates:

```
Einreichung → Vollständigkeit → Auslegung → Anhörung → Beschlussentwurf → Beschluss → Rechtskraft
(Submission)  (Completeness)   (Display)   (Hearing)  (Draft Decision)   (Decision)  (Legal Effect)
```

Each gate checks defined conditions before the procedure can advance:

| Gate | Transition | Prerequisites |
|---|---|---|
| Gate 1 | Submission → Completeness | All required documents present, Merkle root set, applicant signature |
| Gate 2 | Completeness → Public Display  | Completeness confirmed, display period set, objection portal open |
| Gate 3 | Display → Hearing | Display period expired, objections recorded with timestamps |
| Gate 4 | Hearing → Draft Decision | All objections addressed, hearing documented, no open reviews |
| Gate 5 | Draft → Final Decision | Internal approvals granted, decision hash anchored |
| Gate 6 | Decision → Legal Effect | Challenge period expired (1 month) or legal remedies concluded |

Only the Planning Department (*Sachbereich Planfeststellung*) can trigger phase transitions. The contract automatically verifies that all gate conditions are met.

---

## Architecture

**Off-Chain (Working Level)**
- E-file and document management systems
- Application and public participation portal
- Original documents, personal data

**On-Chain (Evidence Level)**
- Hash registry (Merkle roots of document packages)
- Workflow gates (state machine)
- Event trail (tamper-proof audit log)
- Role assignments and access control

No document contents and no personal data reach the blockchain. The link between off-chain documents and on-chain anchors is established exclusively through cryptographic hashes.

---

## Roles

| Role | Description | Permissions |
|---|---|---|
| `SACHBEREICH_ROLE` | Planning Department (SB1PF) | Phase transitions, gate checks, workflow control |
| `EBA_ADMIN_ROLE` | Authority administration | Role management, configuration |
| `BEARBEITUNGSTEAM_ROLE` | Internal technical review | Expert opinions |
| `TOEB_ROLE` | Public bodies (*Träger öffentlicher Belange*) | Time-bound statements |
| `VORHABENTRAEGER_ROLE` | Applicant / project sponsor | Submit documents, plan amendments |
| `KANZLEI_ROLE` | Registry / secretariat | Administrative support |
| — | General public | Submit objections, read access |

---

## Legal Foundation

- § 18 Allgemeines Eisenbahngesetz (AEG) — General Railway Act
- §§ 72 ff. Verwaltungsverfahrensgesetz (VwVfG) — Administrative Procedure Act
- § 3a VwVfG — Digital documents in administrative procedures
- § 371a ZPO — Evidentiary value of digital documents
- Art. 5, 17 DSGVO / GDPR — Data protection principles

---

## Privacy & GDPR

GDPR-compliant by design through strict separation:

- **On-chain:** Only hashes, reference IDs, timestamps — no personal data
- **Off-chain:** All document contents and personal data, stored in government e-file systems

This satisfies the storage limitation principle (Art. 5 GDPR) and preserves the right to erasure (Art. 17 GDPR): personal data can be deleted off-chain without affecting the cryptographic integrity of on-chain records.

---

## For Domain Experts

Coming from engineering, law, or public administration and want to understand how to read and adapt a smart contract? The learning path in this repository is designed for people who think in processes, not in syntax.

[Workflow Exploration Guide (Solidity)](./learnpath/WORKFLOW_EXPLORATION.md)

40% reading · 30% clicking · 30% small edits (1–10 lines)

---

## Running the Tests

```bash
forge test --match-path test/WorkflowPFV.t.sol
```

Tests cover the regular procedure flow as well as failure cases: late objections, unauthorized access, missed deadlines, and duplicate prevention.

---

## Academic Publication

**"Blockchain in der Planfeststellung: Möglichkeiten für Effizienz und Nachvollziehbarkeit"**
Klaus Walter, *Eisenbahntechnische Rundschau (ETR)*, Issue 5/2026.

The article outlines a reference design for blockchain technology in planning approval procedures and proposes a shadow-run pilot as a realistic entry point.

---

## Status

**Academic Proof of Concept.** Research and demonstration purposes only. The contract is deployed and verified on Sepolia, but does not replace production software or constitute legal advice.

---

## License

MIT License — see [LICENSE](LICENSE).

---

## Author

**Dipl.-Ing. Klaus Walter**
Technical Official at the Federal Railway Authority (*Eisenbahn-Bundesamt / EBA*), Frankfurt a. M., Planning Department.

The contents published here reflect the author's professional assessment and do not represent an official position of the Federal Railway Authority.

---

---

# Deutsch

## Plan Approval Logic — Smart Contract für Planfeststellungsverfahren

> Technischer Demonstrator zum Fachartikel **„Blockchain in der Planfeststellung: Möglichkeiten für Effizienz und Nachvollziehbarkeit"**, erschienen in *Eisenbahntechnische Rundschau (ETR)*, Ausgabe 5/2026.

Dieses Repository enthält einen Solidity-Smart-Contract, der die Verfahrenslogik eines Eisenbahn-Planfeststellungsverfahrens nach § 18 AEG i. V. m. §§ 72 ff. VwVfG als Zustandsautomat abbildet. Das Projekt ist ein Forschungs- und Demonstrationsprojekt und **nicht für den produktiven Einsatz vorgesehen**.

---

### Live-Demo auf Sepolia

Der Contract ist auf dem Ethereum Sepolia Testnet deployed und verifiziert. Leser können den Quellcode und alle Transaktionen direkt einsehen:

| | |
|---|---|
| **Contract-Adresse** | `0x2aa68e465455e2da532dc4c8a64ceee52703f25e` |
| **Netzwerk** | Ethereum Sepolia Testnet |
| **Etherscan** | [sepolia.etherscan.io/address/0x2aa68e…3f25e](https://sepolia.etherscan.io/address/0x2aa68e465455e2da532dc4c8a64ceee52703f25e#code) |
| **Verifizierung** | Source Code Verified (Exact Match) |

[Interaktives Verfahrensdashboard](https://buenje.github.io/plan-approval-logic/demo/WorkflowPFV_Demo.html)

> **Hinweis:** Das Dashboard ist ein statischer Prototyp zur Veranschaulichung — keine Live-Verbindung zum Smart Contract. Es zeigt, wie ein Frontend für Verfahrensbeteiligte aussehen könnte.

---

### Verfahrensablauf

Sieben Verfahrensphasen, sechs Gates:

```
Einreichung → Vollständigkeit → Auslegung → Anhörung → Beschlussentwurf → Beschluss → Rechtskraft
```

Nur der Sachbereich Planfeststellung kann einen Phasenwechsel auslösen. Der Smart Contract prüft automatisch, ob alle Gate-Bedingungen erfüllt sind.

---

### Architektur

**Off-Chain (Arbeitsebene):** E-Akte, Dokumentenmanagementsystem, Antragsportal, Originaldokumente, personenbezogene Daten.

**On-Chain (Beweisebene):** Hash-Registry (Merkle-Roots), Workflow-Gates (Zustandsautomat), Event-Trail (Audit-Log), Rollenverwaltung.

Keine Dokumenteninhalte und keine personenbezogenen Daten gelangen auf die Blockchain.

---

### Rechtliche Grundlagen

- § 18 AEG · §§ 72 ff. VwVfG · § 3a VwVfG · § 371a ZPO · Art. 5, 17 DSGVO

---

### Tests ausführen

```bash
forge test --match-path test/WorkflowPFV.t.sol
```

---

### Begleitartikel

**„Blockchain in der Planfeststellung: Möglichkeiten für Effizienz und Nachvollziehbarkeit"**
Klaus Walter, *Eisenbahntechnische Rundschau (ETR)*, Ausgabe 5/2026.

---

### Autor

**Dipl.-Ing. Klaus Walter**
Technischer Beamter beim Eisenbahn-Bundesamt (EBA), Frankfurt a. M., Sachbereich 1 Planfeststellung.

Die hier veröffentlichten Inhalte geben die fachliche Einschätzung des Autors wieder und stellen keine offizielle Position des Eisenbahn-Bundesamtes dar.

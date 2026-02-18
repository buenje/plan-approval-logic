# Railway Planning Approval Smart Contract

## 🇬🇧 English Overview

This repository contains a proof-of-concept smart contract that models
the procedural logic of railway planning approval processes
(Planfeststellungsverfahren) under German administrative law.

The project demonstrates how blockchain-based state machines and
validation logic can be used to:
- increase traceability of procedural milestones
- ensure integrity of decision-relevant documents
- document transitions between legally defined process phases

⚠️ This project does **not** replace legal assessment, administrative
discretion, or sovereign decision-making.  
It serves purely as a technical and architectural exploration.

### Scope
- Rule-based workflow modeling (state machines)
- On-chain validation gates
- Auditability and evidence integrity
- Separation of on-chain evidence and off-chain working processes

### Status
Academic proof of concept (PoC)  
Research and demonstration purpose only  
Not intended for productive or operational use

---

## 🇩🇪 Deutsche Beschreibung

# Eisenbahn-Planfeststellung Smart Contract

Spezifische Implementierung des generischen PlanApproval-Frameworks für Planfeststellungsverfahren im Eisenbahnwesen nach § 18 AEG i.V.m. § 76 VwVfG.

## 🎯 Anwendungsfall

Dieses Modul demonstriert wie Blockchain-Technologie die Nachvollziehbarkeit und Prozessdisziplin in Eisenbahn-Planfeststellungsverfahren erhöhen kann, ohne die juristische Abwägung oder hoheitliche Entscheidungen zu ersetzen.

## 📋 Verfahrensablauf

```
Einreichung → Vollständigkeit → Auslegung → Abwägung → Beschlussentwurf → Beschluss → Rechtskraft
```

Jeder Übergang wird durch "Gates" kontrolliert, die definierte Bedingungen prüfen:
- Vollständigkeit der Unterlagen (nach EBA-Leitfaden)
- Einhaltung von Fristen (TÖB-Beteiligung, Auslegung)
- Bearbeitung aller Einwendungen
- Interne Freigaben (Fachprüfungen)

## 🏗️ Architektur

### Off-Chain (Arbeitsebene)
- E-Akte / DMS
- Antrags- und Beteiligungsportal des Bundes
- Personenbezogene Daten
- Originaldokumente

### On-Chain (Beweisebene)
- Hash-Registry (Merkle-Roots der Dokumentenpakete)
- Workflow-Gates (State Machine)
- Event-Trail (Audit-Log)

## 👥 Rollen

| Rolle | Beschreibung | Befugnisse |
|-------|--------------|------------|
| `Sachbereich1PF` | Verfahrensleitung | Phasenwechsel, Workflow-Konfiguration |
| `Fach` | Fachprüfer | Fachliche Stellungnahmen (Wasser, Natur, etc.) |
| `Toeb` | Träger öffentlicher Belange | Stellungnahmen gemäß Zuständigkeit |
| `Vorhabentraeger` | Antragsteller (z.B. DB InfraGO) | Unterlagen einreichen, Planänderungen |
| `None` | Öffentlichkeit | Lesezugriff, Einwendungen einreichen |

## 📄 Rechtliche Grundlagen

- § 18 Allgemeines Eisenbahngesetz (AEG)
- § 76 Verwaltungsverfahrensgesetz (VwVfG)
- Planfeststellungsrichtlinien des Eisenbahn-Bundesamtes
- Leitfaden zur Gestaltung von Antragsunterlagen (EBA)

## 🔐 Datenschutz

**DSGVO-konform durch strikte Trennung:**
- **On-Chain:** Nur Hashes, IDs, Zeitstempel
- **Off-Chain:** Alle Inhalte und personenbezogene Daten

## 🚀 Verwendung

```solidity
// 1. Rollen zuweisen (nur Sachbereich1PF)
workflow.rolleZuweisen(vorhabentraegerAdresse, Role.Vorhabentraeger);

// 2. Verfahren einreichen (Vorhabenträger)
bytes32 dossierId = keccak256("PF_2026_001_NBS_Hamburg_Berlin");
bytes32 merkleRoot = calculateMerkleRoot(planunterlagen);
workflow.verfahrenEinreichen(dossierId, merkleRoot);

// 3. Vollständigkeit prüfen (Sachbereich1PF)
workflow.vollstaendigkeitPruefen(dossierId, true);

// 4. Auslegung starten
uint256 fristEnde = block.timestamp + 30 days;
workflow.auslegungStarten(dossierId, fristEnde);

// 5. Einwendung einreichen (Öffentlichkeit)
bytes32 einwendungsHash = keccak256(abi.encodePacked(einwendungstext));
workflow.einwendungEinreichen(dossierId, einwendungsHash);
```

## 🧪 Tests

```bash
# Alle Tests ausführen
forge test --match-path test/planfeststellung/*

# Spezifischen Test
forge test --match-test test_VerfahrenEinreichen
```

## 📚 Dokumentation

Ausführliche Dokumentation zur Implementierung siehe:
-- [docs/eisenbahn-planfeststellung.md](docs/eisenbahn-planfeststellung.md)

## 📖 Begleitartikel

Dieses Modul begleitet den Fachartikel:

**"Blockchain in der Planfeststellung – Möglickeiten für Effizienz und Nachvollziehbarkeit"**

Erschienen in: *Eisenbahntechnische Rundschau (ETR)*, Ausgabe 5/2026

## ⚠️ Status

**🚧 Proof of Concept (Academic PoC)**

Dieses Projekt ist für Forschungs- und Demonstrationszwecke. Es ersetzt keine rechtliche Beratung und ist nicht für den produktiven Einsatz vorgesehen.

## 🔗 Related Work

Dieses Modul nutzt das generische Framework aus [PlanApproval.sol](../contracts/PlanApproval.sol) und passt es spezifisch für Eisenbahn-Planfeststellungsverfahren an.

---

**Version:** 0.1.0 | **Status:** In Entwicklung | **Lizenz:** MIT

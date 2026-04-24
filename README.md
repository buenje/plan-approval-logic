# Plan Approval Logic — Smart Contract

## 🇬🇧 English Overview

This repository contains a proof-of-concept smart contract that models
the procedural logic of formal planning approval processes
(Planfeststellungsverfahren) under German administrative law
(§ 18 AEG in conjunction with §§ 72 ff. VwVfG).

The project demonstrates how blockchain-based state machines and
validation logic can be used to:

* increase traceability of procedural milestones
* ensure integrity of decision-relevant documents
* document transitions between legally defined process phases

⚠️ This project does **not** replace legal assessment, administrative
discretion, or sovereign decision-making. It serves purely as a
technical and architectural exploration based on publicly available
legal sources.

### Scope

* Rule-based workflow modeling (state machines)
* On-chain validation gates
* Auditability and evidence integrity
* Separation of on-chain evidence and off-chain working processes

### Status

Academic proof of concept (PoC). Research and demonstration purpose only.
Not intended for productive or operational use.

---

## 🇩🇪 Deutsche Beschreibung

Generische Referenzimplementierung eines Zustandsautomaten für formelle
Planfeststellungsverfahren nach § 18 AEG i.V.m. §§ 72 ff. VwVfG.

## 🎯 Gegenstand

Dieses Repository demonstriert, wie blockchainbasierte Zustandsautomaten
und Validierungslogik grundsätzlich eingesetzt werden können, um die
Nachvollziehbarkeit und Prozessdisziplin in formellen Planungsverfahren
zu erhöhen — ohne die rechtliche Abwägung oder hoheitliche Entscheidungen
zu ersetzen.

Grundlage sind ausschließlich öffentlich zugängliche Rechtsquellen
(AEG, VwVfG). Interne Regelwerke einzelner Behörden sind nicht
Grundlage dieser Arbeit.

## 📋 Modellierter Verfahrensablauf

```
Einreichung → Vollständigkeit → Auslegung → Abwägung → Beschlussentwurf → Beschluss → Rechtskraft
```

Jeder Übergang wird durch Gates kontrolliert, die formal definierte
Bedingungen prüfen:

* Vollständigkeit der Unterlagen nach § 73 VwVfG
* Einhaltung der gesetzlichen Fristen (Beteiligung Träger öffentlicher Belange, Auslegungsfrist)
* Bearbeitung der form- und fristgerecht erhobenen Einwendungen
* Interne fachliche Stellungnahmen als Voraussetzung der Abwägung

## 🏗️ Architektur

### Off-Chain (Arbeitsebene)

* Dokumentenmanagement / elektronische Akte
* Antrags- und Beteiligungsportale
* Personenbezogene Daten
* Originaldokumente

### On-Chain (Beweisebene)

* Hash-Registry (Merkle-Roots der Dokumentenpakete)
* Workflow-Gates (State Machine)
* Event-Trail (Audit-Log)

## 👥 Rollenmodell

| Rolle | Funktion im Modell | Befugnisse |
| --- | --- | --- |
| `Verfahrensleitung` | Zuständige Planfeststellungsbehörde | Phasenwechsel, Workflow-Konfiguration |
| `Fach` | Fachprüfer (z.B. Immissionsschutz, Wasserrecht, Naturschutz) | Fachliche Stellungnahmen |
| `Toeb` | Träger öffentlicher Belange | Stellungnahmen gemäß Zuständigkeit |
| `Vorhabentraeger` | Antragsteller (Infrastrukturunternehmen) | Unterlagen einreichen, Planänderungen |
| `None` | Öffentlichkeit | Lesezugriff, Einwendungen einreichen |

Das Modell abstrahiert von konkreten Behörden- oder Unternehmensnamen.
Es bildet die Rollenstruktur ab, wie sie sich aus dem Verwaltungsrecht
ergibt.

## 📄 Rechtliche Grundlagen

* § 18 Allgemeines Eisenbahngesetz (AEG)
* §§ 72 ff. Verwaltungsverfahrensgesetz (VwVfG)

## 🔐 Datenschutz

Das Modell ist durch strikte Trennung datenschutzkonform aufgebaut:

* **On-Chain:** Nur Hashes, IDs, Zeitstempel
* **Off-Chain:** Alle Inhalte und personenbezogene Daten

## 🚀 Verwendung (Beispielaufrufe)

```solidity
// 1. Rollen zuweisen (nur Verfahrensleitung)
workflow.rolleZuweisen(vorhabentraegerAdresse, Role.Vorhabentraeger);

// 2. Verfahren einreichen (Vorhabenträger)
bytes32 dossierId = keccak256("DEMO_PROJEKT_0001");
bytes32 merkleRoot = calculateMerkleRoot(planunterlagen);
workflow.verfahrenEinreichen(dossierId, merkleRoot);

// 3. Vollständigkeit prüfen (Verfahrensleitung)
workflow.vollstaendigkeitPruefen(dossierId, true);

// 4. Auslegung starten
uint256 fristEnde = block.timestamp + 30 days;
workflow.auslegungStarten(dossierId, fristEnde);

// 5. Einwendung einreichen (Öffentlichkeit)
bytes32 einwendungsHash = keccak256(abi.encodePacked(einwendungstext));
workflow.einwendungEinreichen(dossierId, einwendungsHash);
```

Alle Bezeichner sind fiktiv und dienen ausschließlich der Demonstration.

## 🧪 Tests

```bash
# Alle Tests ausführen
forge test --match-path test/planfeststellung/*

# Spezifischen Test
forge test --match-test test_VerfahrenEinreichen
```

## 📚 Dokumentation

Ausführliche Dokumentation zur Implementierung siehe:

* [docs/eisenbahn-planfeststellung.md](docs/eisenbahn-planfeststellung.md)

## 📖 Begleitartikel

Dieses Repository begleitet einen Fachbeitrag in der
*Eisenbahntechnischen Rundschau (ETR)*, Ausgabe 5/2026, zur
grundsätzlichen Frage, welche Rolle Blockchain-Technologie in
formellen Planungsverfahren spielen kann — und welche nicht.

Der Artikel wie auch dieses Repository wurden privat und als
Autorentätigkeit erstellt. Sie geben nicht die Position einer Behörde
oder eines Dienstherrn wieder.

## ⚠️ Status und Abgrenzung

**🚧 Academic Proof of Concept**

Dieses Projekt ist ausschließlich für Forschungs- und
Demonstrationszwecke bestimmt. Es ersetzt keine rechtliche Beratung
und ist nicht für den produktiven Einsatz vorgesehen.

Der Code basiert auf öffentlich zugänglichen Rechtsquellen.
Interne Regelwerke einzelner Behörden oder Unternehmen sind nicht
eingeflossen.

## 🔗 Related Work

Dieses Modul nutzt ein generisches Framework zur Modellierung
rechtlich gebundener Workflows und passt es für Planfeststellungs-
verfahren an.

---

**Version:** 0.1.0 | **Status:** In Entwicklung | **Lizenz:** MIT

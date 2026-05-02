# Plan Approval Logic — Smart Contract für Planfeststellungsverfahren

> Technischer Demonstrator zum Fachartikel **„Blockchain in der Planfeststellung: Möglichkeiten für Effizienz und Nachvollziehbarkeit"**, erschienen in *Eisenbahntechnische Rundschau (ETR)*, Ausgabe 5/2026.

Dieses Repository enthält einen Solidity-Smart-Contract, der die Verfahrenslogik eines Eisenbahn-Planfeststellungsverfahrens nach § 18 AEG i. V. m. §§ 72 ff. VwVfG als Zustandsautomat abbildet. Das Projekt ist ein Forschungs- und Demonstrationsprojekt und **nicht für den produktiven Einsatz vorgesehen**.

---

## 🔗 Live-Demo auf Sepolia

Der Contract ist auf dem Ethereum Sepolia Testnet deployed und verifiziert. Leser können den Quellcode und alle Transaktionen direkt einsehen:

| | |
|---|---|
| **Contract-Adresse** | `0x2aa68e465455e2da532dc4c8a64ceee52703f25e` |
| **Netzwerk** | Ethereum Sepolia Testnet |
| **Etherscan** | [sepolia.etherscan.io/address/0x2aa68e…3f25e](https://sepolia.etherscan.io/address/0x2aa68e465455e2da532dc4c8a64ceee52703f25e#code) |
| **Verifizierung** | ✅ Source Code Verified (Exact Match) |


→ [Interaktives Verfahrensdashboard](https://buenje.github.io/plan-approval-logic/demo/WorkflowPFV_Demo.html)

> ⚠️ **Hinweis:** Das Dashboard ist ein statischer Prototyp zur Veranschaulichung —
> keine Live-Verbindung zum Smart Contract.
> Es zeigt, wie ein Frontend für Verfahrensbeteiligte aussehen könnte.

---

## 🎯 Anwendungsfall

Der Contract demonstriert, wie sich die Verfahrensphasen eines Planfeststellungsverfahrens als endlicher Zustandsautomat (Finite State Machine) modellieren lassen. Gates zwischen den Phasen prüfen automatisch, ob alle formalen Voraussetzungen für den nächsten Schritt erfüllt sind.

Die juristische Abwägung und die hoheitliche Entscheidung bleiben bei der zuständigen Behörde. Der Smart Contract ersetzt keine behördliche Entscheidung, er erzwingt lediglich die Einhaltung formaler Verfahrenslogik.

---
## 🎓 Einstieg für Domänenexperten

Du kommst aus Ingenieurwesen, Recht oder Verwaltung — und willst
verstehen, wie man einen Smart Contract liest und anpasst?

→ [14-Tage-Lernpfad (Solidity)](./learnpath/LEARNPFAD_14_TAGE.md)

Strukturiert für Menschen, die in Prozessen denken, nicht in Syntax.
40 % lesen · 30 % klicken · 30 % kleine Edits (1–10 Zeilen).

## 📋 Verfahrensablauf

Sieben Verfahrensphasen, sechs Gates:

```
Einreichung → Vollständigkeit → Auslegung → Anhörung → Beschlussentwurf → Beschluss → Rechtskraft
```

Jedes Gate prüft definierte Bedingungen:

- **Gate 1 (Einreichung → Vollständigkeit):** Alle Pflichtunterlagen vorhanden, Unterlagen versioniert (Merkle-Root), Vorhabenträger-Signatur
- **Gate 2 (Vollständigkeit → Auslegung):** Vollständigkeit bestätigt, Auslegungsfrist gesetzt, Einwendungsportal geöffnet
- **Gate 3 (Auslegung → Anhörung):** Auslegungsfrist abgelaufen, Einwendungen erfasst und zeitgestempelt, Entscheidung Erörterungstermin
- **Gate 4 (Anhörung → Beschlussentwurf):** Jede Einwendung beantwortet, Dokumentation Erörterungstermin, keine offenen Fachprüfungen
- **Gate 5 (Beschlussentwurf → Beschluss):** Interne Freigaben erteilt, Sachbereich-Signatur, Beschluss-Hash verankert
- **Gate 6 (Beschluss → Rechtskraft):** Klagefrist abgelaufen (1 Monat) oder Rechtsmittel erledigt, Bestandskraft eingetreten

Nur der Sachbereich Planfeststellung kann einen Phasenwechsel auslösen. Der Smart Contract prüft automatisch, ob alle Gate-Bedingungen erfüllt sind.

---

## 🏗️ Architektur

**Off-Chain (Arbeitsebene)**
- E-Akte und Dokumentenmanagementsystem
- Antrags- und Beteiligungsportal des Bundes
- Originaldokumente, personenbezogene Daten

**On-Chain (Beweisebene)**
- Hash-Registry (Merkle-Roots der Dokumentenpakete)
- Workflow-Gates (Zustandsautomat)
- Event-Trail (lückenloses Audit-Log)

Keine Dokumenteninhalte und keine personenbezogenen Daten gelangen auf die Blockchain. Die Verknüpfung zwischen Off-Chain-Dokumenten und On-Chain-Ankern erfolgt ausschließlich über kryptografische Hashes.

---

## 👥 Rollen

| Rolle | Beschreibung | Befugnisse |
|---|---|---|
| `SACHBEREICH_ROLE` | Sachbereich 1 Planfeststellung (SB1PF) | Phasenwechsel, Gate-Prüfung, Workflow-Steuerung |
| `EBA_ADMIN_ROLE` | EBA-Administration | Rollenverwaltung, Konfiguration |
| `BEARBEITUNGSTEAM_ROLE` | Interne Fachprüfung | Fachliche Stellungnahmen |
| `TOEB_ROLE` | Träger öffentlicher Belange | Fristgebundene Stellungnahmen |
| `VORHABENTRAEGER_ROLE` | Antragsteller | Unterlagen einreichen, Planänderungen, Nachbesserungen |
| `KANZLEI_ROLE` | Kanzlei / Sekretariat | Verwaltungsunterstützung |
| — | Öffentlichkeit | Einwendungen einreichen, Lesezugriff |

---

## 📜 Rechtliche Grundlagen

- § 18 Allgemeines Eisenbahngesetz (AEG)
- §§ 72 ff. Verwaltungsverfahrensgesetz (VwVfG)
- Planfeststellungsrichtlinien des Eisenbahn-Bundesamtes
- Leitfaden zur Gestaltung von Antragsunterlagen (EBA)

---

## 🔐 Datenschutz

DSGVO-konform durch strikte Trennung:

- **On-Chain:** Nur Hashes, Referenz-IDs, Zeitstempel
- **Off-Chain:** Alle Inhalte und personenbezogenen Daten

---

## 🧪 Tests

Der Contract wurde mit automatisierten Tests geprüft — vom regulären Verfahrensablauf bis hin zu Fehlerfällen wie verspäteten Einwendungen, unberechtigten Zugriffen und Fristversäumnissen.

```bash
forge test --match-path test/WorkflowPFV.t.sol
```

---

## 📖 Begleitartikel

**„Blockchain in der Planfeststellung: Möglichkeiten für Effizienz und Nachvollziehbarkeit"**
Klaus Walter, Eisenbahntechnische Rundschau (ETR), Ausgabe 5/2026.

Der Artikel skizziert ein Referenzdesign für den Einsatz von Blockchain-Technologie in der Planfeststellung und schlägt einen Shadow-Run-Piloten als realistischen Einstieg vor.

---

## 🚧 Status

**Academic Proof of Concept.** Forschungs- und Demonstrationszwecke. Der Contract ist auf Sepolia deployed und verifiziert, ersetzt jedoch keine produktive Software und keine rechtliche Beratung.

---

## 📄 Lizenz

MIT License — siehe [LICENSE](LICENSE).

---

## 👤 Autor

**Dipl.-Ing. Klaus Walter**
Technischer Beamter beim Eisenbahn-Bundesamt (EBA), Frankfurt a. M., Sachbereich 1 Planfeststellung.

Die hier veröffentlichten Inhalte geben die fachliche Einschätzung des Autors wieder und stellen keine offizielle Position des Eisenbahn-Bundesamtes dar.

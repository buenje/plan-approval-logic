# Smart Contract PoC: Planfeststellungsverfahren (PlanApproval)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Solidity](https://img.shields.io/badge/solidity-%5E0.8.0-lightgrey)
![Status](https://img.shields.io/badge/status-Academic_PoC-orange)

> **Begleit-Repository zum Fachartikel:** *"Smart Contracts im Planfeststellungsverfahren: Ansätze für eine rechtssichere und effiziente Verfahrensstruktur"

## 📄 Über dieses Projekt

Dieses Repository enthält den **Proof of Concept (PoC)** für die Implementierung deutscher Verwaltungsverfahrens-Logik auf der Ethereum Virtual Machine (EVM).

Ziel ist es, die abstrakten rechtlichen Anforderungen des **Verwaltungsverfahrensgesetzes (VwVfG)** – insbesondere im Kontext komplexer Planfeststellungsverfahren (§ 73 VwVfG) – in deterministischen, unveränderbaren Code zu übersetzen. Der Fokus liegt auf Transparenz, Fristenwahrung und Revisionssicherheit.

---

## ⚖️ Legal Engineering: Vom Gesetz zum Code

Die Kerninnovation liegt in der direkten Abbildung juristischer Normen in technische Logik-Gatter. Die folgende Tabelle zeigt das Mapping zwischen VwVfG und Smart Contract Architektur:

| Juristische Anforderung | Rechtsgrundlage (DE) | Technische Implementierung (Solidity) |
| :--- | :--- | :--- |
| **Präklusion / Fristen** | § 73 Abs. 4 VwVfG | `modifier onlyBeforeDeadline()` <br> *Sperrt Schreibzugriffe nach Ablauf des Unix-Timestamps.* |
| **Schriftformersatz** | § 3a Abs. 2 VwVfG | `function submitObjection(string memory _hash)` <br> *Verarbeitet den kryptographischen Hash des Dokuments.* |
| **Bekanntmachung** | § 73 Abs. 5 VwVfG | `event ObjectionRegistered(address indexed sender, ...)` <br> *Erzeugt einen öffentlichen, unveränderbaren Log-Eintrag.* |
| **Unveränderbarkeit** | Rechtsstaatsprinzip | `mapping(bytes32 => Objection) private objections` <br> *Keine Update-Funktion für bereits geschriebene Daten.* |

---

## 🛠 Technische Architektur (State Machine)

Aus ingenieurwissenschaftlicher Sicht wird das Verwaltungsverfahren als **Endlicher Automat (Finite State Machine)** modelliert. Der Smart Contract erlaubt Zustandsübergänge nur, wenn definierte Vorbedingungen erfüllt sind.

*(Platzhalter für Diagramm)
### Kern-Funktionen
* **`initializeProcess`**: Setzt unveränderbare Parameter (Behörden-Adresse, Fristdauer).
* **`submitObjection`**: Nimmt den Hash einer Einwendung entgegen, prüft Frist und Duplikate.
* **`closeProceedings`**: Finalisiert den Status nach Fristablauf.

---

## 🚀 Quick Start (Keine Installation nötig)

Um den Smart Contract und die Logik ohne lokale Entwicklungsumgebung zu testen, kann der Code direkt in der Web-IDE **Remix** ausgeführt werden.

1. **[Klicken Sie hier, um den Code in Remix zu öffnen](https://remix.ethereum.org)** (Copy-Paste des Codes aus `/contracts/PlanApproval.sol`).
2. Kompilieren Sie den Contract (Tab "Solidity Compiler").
3. Gehen Sie auf "Deploy & Run Transactions".
4. Wählen Sie als Environment "Remix VM (Cancun)".
5. Deployen Sie den Contract und testen Sie die Funktionen `submitObjection` etc.

---

## 📂 Repository Struktur

```text
/plan-approval-logic
├── contracts/
│   └── PlanApproval.sol       # Der Haupt-Vertrags-Code (Solidity)
├── tests/
│   └── PlanApproval.test.js   # Unit Tests zur Verifizierung der Fristenlogik
├── docs/                      # Zusätzliche Dokumentation & Diagramme
└── README.md                  # Diese Datei

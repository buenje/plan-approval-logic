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
### Prozess-Logik (State Machine)
```mermaid
## Prozess-Logik (State Machine)

Das ist der allgemeine Ablauf:

```mermaid
flowchart LR
    A([Start]) --> B[Antrag]
    B --> C[Prüfung]
    C -->|unvollständig| D[Rücksendung]
    D --> E[Rücklauf]
    E --> C
    C -->|vollständig| F[[Anhörung]]
```

Und hier ist das Detail-Verfahren für Planänderungen:

## Prozess-Logik (State Machine)

Das ist der allgemeine Ablauf:

```mermaid
flowchart LR
    A([Start]) --> B[Antrag]
    B --> C[Prüfung]
    C -->|unvollständig| D[Rücksendung]
    D --> E[Rücklauf]
    E --> C
    C -->|vollständig| F[[Anhörung]]
```

Und hier ist das Detail-Verfahren für Planänderungen (§ 76 VwVfG):
{/* Schritt 5: Eingang der Stellungnahmen & Einwendungen */}
            <div className="flex items-start gap-4">
              <div className="bg-purple-500 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold flex-shrink-0">5</div>
              <div className="flex-grow">
                <div className="font-semibold">Eingang & Bündelung (On-Chain Logging)</div>
                <div className="text-sm text-gray-600 mt-1">
                  Sammlung aller Eingänge aus drei Quellen:
                  <ul className="list-disc ml-5 mt-1 text-xs">
                    <li><strong>TÖB:</strong> Fachbehörden, Gemeinden</li>
                    <li><strong>Vereinigungen:</strong> Naturschutz (§ 63 BNatSchG)</li>
                    <li><strong>Private:</strong> Betroffene Eigentümer/Anwohner</li>
                  </ul>
                </div>
                <div className="bg-purple-50 p-2 rounded mt-2 text-xs font-mono border border-purple-200">
                  Status: WAITING_FOR_FEEDBACK -> RECEIVED
                </div>
              </div>
            </div>

            <div className="border-l-2 border-gray-300 ml-4 h-8"></div>

            {/* Schritt 6: Erstellung der Synopse */}
            <div className="flex items-start gap-4">
              <div className="bg-indigo-500 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold flex-shrink-0">6</div>
              <div className="flex-grow">
                <div className="font-semibold">VT erstellt Synopse (Das "Gegenüberstellungs-Dokument")</div>
                <div className="text-sm text-gray-600 mt-1">
                  Der Vorhabenträger (VT) muss jeden Punkt erwidern.
                </div>
                <div className="bg-white p-3 rounded mt-2 border border-gray-300 shadow-sm">
                  <table className="w-full text-xs text-left">
                    <thead>
                      <tr className="bg-gray-100 border-b">
                        <th className="p-1">Lfd. Nr.</th>
                        <th className="p-1">Einwender</th>
                        <th className="p-1">Argument</th>
                        <th className="p-1">Erwiderung VT</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr className="border-b">
                        <td className="p-1">001</td>
                        <td className="p-1">Naturschutz-V.</td>
                        <td className="p-1">Lärmschutz...</td>
                        <td className="p-1 text-blue-600">Lärmwand wird erhöht...</td>
                      </tr>
                      <tr>
                        <td className="p-1">002</td>
                        <td className="p-1">Müller (Privat)</td>
                        <td className="p-1">Flächenverlust</td>
                        <td className="p-1 text-blue-600">Entschädigung gem. §...</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            <div className="border-l-2 border-gray-300 ml-4 h-8"></div>

            {/* Schritt 7: Hash der Synopse auf Blockchain */}
            <div className="flex items-start gap-4">
              <div className="bg-indigo-600 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold flex-shrink-0">7</div>
              <div className="flex-grow">
                <div className="font-semibold">Fixierung der Synopse (Unveränderbarkeit)</div>
                <div className="text-sm text-gray-600 mt-1">
                  Bevor das EBA prüft, wird die Synopse per Hash "eingefroren". 
                  Nachträgliche Änderungen an der Erwiderung des VT sind nicht unbemerkt möglich.
                </div>
                <div className="bg-gray-50 p-2 rounded mt-2 text-xs font-mono border border-gray-200">
                  Tx: RegisterSynopse(hash_synopse_v1, count_einwendungen=47)
                </div>
              </div>
            </div>

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

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

import React from 'react';
import { GitBranch, GitMerge, ArrowRight, FileText, AlertTriangle, CheckCircle, Layers } from 'lucide-react';

const PlanExtractionDiagram = () => {
  return (
    <div className="p-6 bg-white rounded-xl shadow-sm border border-gray-200">
      <h3 className="text-xl font-bold text-gray-800 mb-2">Extraktion der Planänderung (§ 76 VwVfG)</h3>
      <p className="text-sm text-gray-600 mb-8">
        Der ursprüngliche Plan (Hauptstrang) bleibt bestehen. Die Änderung wird als „Delta“ extrahiert, 
        separat geprüft und am Ende wieder zur Einheit verschmolzen (Abs. 11).
      </p>

      <div className="relative">
        
        {/* === HAUPTSTRANG (DER BLAUE PFAD) === */}
        <div className="absolute top-0 left-0 w-full h-24 bg-blue-50/50 rounded-lg -z-10 border border-blue-100"></div>
        <div className="flex items-center gap-4 mb-16 relative">
          <div className="w-24 font-bold text-blue-800 text-sm">Hauptplan<br/>(Ursprung)</div>
          
          {/* Node 1: Festgestellter Plan */}
          <div className="flex flex-col items-center">
            <div className="w-12 h-12 bg-blue-600 text-white rounded-lg flex items-center justify-center shadow-lg">
              <FileText size={24} />
            </div>
            <div className="text-xs font-mono mt-1 text-blue-700">PFB_V1.0</div>
          </div>

          {/* Verbindungslinie Haupt */}
          <div className="h-1 flex-grow bg-blue-200 relative">
            {/* Der Punkt, an dem die Änderung abzweigt */}
            <div className="absolute left-1/4 top-1/2 -translate-y-1/2 w-4 h-4 bg-orange-500 rounded-full border-2 border-white z-10"></div>
          </div>

          {/* Node 2: Weiterbau / Bestand */}
          <div className="flex flex-col items-center opacity-50">
            <div className="w-12 h-12 bg-blue-200 text-blue-800 rounded-lg flex items-center justify-center border-2 border-blue-300">
              <Layers size={24} />
            </div>
            <div className="text-xs font-mono mt-1 text-blue-400">Realisierung</div>
          </div>
        </div>


        {/* === DIE EXTRAKTION (DER CHANGE PFAD) === */}
        {/* Verbindungskurve vom Hauptstrang nach unten */}
        <svg className="absolute top-6 left-[calc(8rem+25%)] w-16 h-24 -z-10" style={{ overflow: 'visible' }}>
          <path d="M 0 0 C 0 50, 50 50, 50 80" fill="none" stroke="#f97316" strokeWidth="3" strokeDasharray="6 4" />
          <polygon points="45,75 50,85 55,75" fill="#f97316" />
        </svg>

        <div className="ml-[calc(8rem+25%+3rem)] bg-orange-50 p-4 rounded-xl border-2 border-orange-200 relative">
          <div className="absolute -top-3 left-4 bg-orange-100 text-orange-800 px-2 py-0.5 text-xs font-bold uppercase tracking-wider border border-orange-300 rounded">
            Extrahierter Prozess
          </div>

          <div className="flex items-center gap-6">
            
            {/* Schritt A: Antrag */}
            <div className="text-center">
              <div className="w-10 h-10 bg-white border-2 border-orange-500 text-orange-600 rounded-full flex items-center justify-center mb-2 mx-auto">
                <GitBranch size={18} />
              </div>
              <div className="text-xs font-bold">Antrag §76(1)</div>
              <div className="text-[10px] text-gray-500">Änderung vor<br/>Fertigstellung</div>
            </div>

            <ArrowRight size={20} className="text-orange-300" />

            {/* Schritt B: Check */}
            <div className="text-center">
              <div className="w-10 h-10 bg-white border-2 border-orange-500 text-orange-600 rounded-full flex items-center justify-center mb-2 mx-auto">
                <AlertTriangle size={18} />
              </div>
              <div className="text-xs font-bold">Prüfung</div>
              <div className="text-[10px] text-gray-500">Wesentlichkeit<br/>& Betroffene</div>
            </div>

            <ArrowRight size={20} className="text-orange-300" />

            {/* Schritt C: Beschluss */}
            <div className="text-center">
              <div className="w-10 h-10 bg-orange-500 text-white rounded-full flex items-center justify-center mb-2 mx-auto shadow-md">
                <CheckCircle size={18} />
              </div>
              <div className="text-xs font-bold">Änderungs-<br/>beschluss</div>
              <div className="text-[10px] text-gray-500">Rechtliche<br/>Zulassung</div>
            </div>
          </div>
        </div>

        {/* === MERGE ZURÜCK (DIE EINHEIT) === */}
        {/* Verbindungskurve zurück nach oben */}
        <svg className="absolute top-6 left-[calc(8rem+25%+22rem)] w-16 h-24 -z-10" style={{ overflow: 'visible' }}>
          <path d="M 0 80 C 0 50, 50 50, 50 0" fill="none" stroke="#16a34a" strokeWidth="3" />
          <polygon points="45,5 50,-5 55,5" fill="#16a34a" />
        </svg>

        {/* Das Ergebnis: Die Einheit */}
        <div className="absolute top-0 right-0 flex flex-col items-center">
          <div className="w-12 h-12 bg-gradient-to-br from-blue-600 to-orange-500 text-white rounded-lg flex items-center justify-center shadow-lg border-2 border-white">
            <GitMerge size={24} />
          </div>
          <div className="text-xs font-bold mt-1 text-gray-800">Plan-Einheit</div>
          <div className="text-[10px] text-gray-500 text-center bg-white px-1 rounded border">
            § 76 Abs. 11<br/>(Merge)
          </div>
        </div>

      </div>

      <div className="mt-12 grid grid-cols-2 gap-4 text-xs">
        <div className="bg-blue-50 p-2 rounded border border-blue-100">
          <strong>Hauptstrang (Blue):</strong> Der rechtssichere Bestand. Ohne Änderung läuft dieser weiter (z.B. Bau in unveränderten Abschnitten).
        </div>
        <div className="bg-orange-50 p-2 rounded border border-orange-100">
          <strong>Extraktion (Orange):</strong> Isolierter Scope. Nur die Änderung wird geprüft. Das Risiko kontaminiert nicht den gesamten Plan.
        </div>
      </div>
    </div>
  );
};
### Prozess-Extraktion: Planänderung (§ 76 VwVfG)

Hier wird gezeigt, wie die Planänderung aus dem Hauptstrang (Blau) extrahiert wird und am Ende wieder zu einer rechtlichen Einheit verschmilzt.

```mermaid
flowchart LR
    %% Styles
    classDef main fill:#dbeafe,stroke:#1d4ed8,color:#1e3a8a,stroke-width:2px;
    classDef change fill:#ffedd5,stroke:#f97316,color:#9a3412,stroke-width:2px,stroke-dasharray: 5 5;
    classDef merge fill:#ecfccb,stroke:#4d7c0f,color:#365314,stroke-width:4px;
    
    %% Hauptstrang
    Start((Ursprungs-<br/>Plan)):::main -->|Laufendes Verfahren| Trigger{Änderungs-<br/>bedarf}:::main
    
    %% Der Hauptstrang läuft virtuell weiter/parallel
    Trigger -.->|Unveränderte Teile| Bau[Bauausführung<br/>unveränderter Teile]:::main
    
    %% Die Extraktion (Der Subgraph)
    subgraph Extraction [Extraktion: Planänderungsverfahren]
        direction TB
        Antrag[Antrag §76 Abs.1]:::change
        Pruefung[Prüfung:<br/>Wesentlichkeit?]:::change
        Beteiligung[Beteiligung<br/>Betroffener]:::change
        Beschluss[Änderungs-<br/>beschluss]:::change
        
        Antrag --> Pruefung --> Beteiligung --> Beschluss
    end
    
    %% Verbindungen
    Trigger ==>|Extraktion| Antrag
    
    %% Merge
    Beschluss ==>|Verschmelzung<br/>§ 76 Abs. 11| Einheit((Rechtliche<br/>Einheit)):::merge
    Bau -.-> Einheit
    
    %% Erklärung
    Trigger -.- Note1[Identität gewahrt?<br/>Wenn nein: § 77 Neubau]
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

## Vor dem Start

→ [WorkflowPFV Verfahrensdashboard ansehen](https://buenje.github.io/plan-approval-logic/demo/WorkflowPFV_Demo.html)  
Zeigt Zustandsautomat, Gate-Status und Audit-Trail — so sieht das Ergebnis aus.

**Tool für alle Übungen:** Kein lokales Setup nötig.  
→ [Tag01_Grundlagen.sol direkt in Remix öffnen](https://remix.ethereum.org/#url=https://raw.githubusercontent.com/buenje/plan-approval-logic/main/contracts/learning/Tag01_Grundlagen.sol)  
Contract wird direkt geladen — kein manuelles Suchen nötig.

---

---
Contract direkt in Remix laden:
1. „Load from GitHub" wählen
2. Repository: `buenje/plan-approval-logic`
3. Datei: `WorkflowPFV.t.sol` im Root-Verzeichnis
4. Compiler: Solidity 0.8.x
5. Deployen auf: JavaScript VM

---

## Tag 1 – Setup & Pause‑Schalter
- Klick: `pause()` / `unpause()`; `paused()` lesen (blau).
- Mini‑Edit: `isPaused() external view returns (bool)`.
- Output: 1 Screenshot (Event‑Log) + 1 Satz.
  
→ [Tag01_Grundlagen.sol in Remix öffnen](https://remix.ethereum.org/#url=https://raw.githubusercontent.com/buenje/plan-approval-logic/main/contracts/learning/Tag01_Grundlagen.sol)

## Tag 2 – `require` & Fehlermeldungen
- Provoziere 3 Fehler: nicht berechtigt / pausiert / ungültige id.
- Mini‑Edit: Meldungen vereinheitlichen („nicht berechtigt“, „pausiert“, „ungueltige id“).
- Output: kleine Tabelle „Aufruf → Meldung“ (3 Zeilen).

## Tag 3 – Events mit Parametern
- Mini‑Edit: `actor/approver` als Parameter ergänzen, `indexed` setzen (max. 3 Param.).
- Klick: Im Remix‑Log nach `id` filtern.
- Output: Screenshot + 2 Sätze „warum Parameter/`indexed`“.

## Tag 4 – `enum` & `struct` (klein)
- Lesen: `enum Status`, `struct Entry` (Hash/Status/Actor/Zeit).
- Mini‑Edit: `Rejected(id, reason)` (Event + Funktion, 10–12 Zeilen).
- Klick: `submit → startReview → reject("grund")`.
- Output: letzter Status = Abgelehnt (lesen).

## Tag 5 – Lesen ohne Transaktion
- Mini‑Edit: `getLastStatus(id) external view` (6–8 Zeilen).
- Klick: Vor/Nach Aktionen den letzten Status lesen.
- Output: 2 Screenshots (State & Log).

## Tag 6 – Status‑Türen (Modifier‑Kombi)
- Mini‑Edit: `inStatus(id, Angelegt)` an `startReview`; `inStatus(id, InPruefung)` an `approve`.
- Negativtest: falsche Reihenfolge → „falscher status“.
- Output: 2 Sätze: globaler Schalter ≠ fachlicher Status.

## Tag 7 – Struktur & VS‑Code‑Flow
- Ordner/Imports prüfen, Auto‑Save, Outline, **F2 Rename** üben.
- Mini‑Edit: Dateikopf‑Kommentare (`@title`, `@notice`).
- Output: Commit „chore: structure & docs“.

## Tag 8 – Klon‑Übung (ohne Neuschreiben)
- Datei duplizieren; Benennungen ändern (`Bestaetigt → Freigegeben`), Logik gleich.
- Output: Commit + 2 Sätze „Namen vs. Verhalten“.

## Tag 9 – Fehlerfreundliche UX
- Mini‑Edit: strikte `pause/unpause`‑Meldungen (`schon pausiert` / `nicht pausiert`).
- Klick: Doppelte Aufrufe testen → sauberer Revert.
- Output: Screenshot + 3 häufige Fehlbedienungen.

## Tag 10 – Mapping/History begreifen
- Lesen: Warum `mapping(uint => Entry[])` (Nachschlage + Verlauf).
- Mini‑Edit: `historyLength(id)` / `getEntry(id, idx)` (falls noch nicht).
- Output: 1 Screenshot und 1 Satz Erklärung.

## Tag 11 – Event vs. State (Transfer)
- Erkläre in **2 Sätzen**: *State = Gedächtnis*, *Event = Protokoll*.
- Klick: 1 Aktion mit Event + 1 reiner `view`‑Call.
- Output: 2 Screenshots (Log vs. State).

## Tag 12 – Mini‑Refactor & Kommentare
- 3 unnötige Kommentare weg, 3 **Warum‑Kommentare** rein.
- Optional: 1 Custom Error (`error NotOwner();`).
- Output: Commit + 1 Satz „was lesbarer wurde“.

## Tag 13 – Testliste (manuell, 4 Fälle)
- Zwei Happy‑Paths, zwei Fehlerfälle (pausiert/falscher Status).
- Klick alles durch, Häkchen setzen.
- Output: Foto/Screenshot der Liste.

## Tag 14 – Demo‑Paket
- README „5‑Min‑Demo“ final, 2 Screenshots (Log & State) in `/docs`.
- Output: Commit „feat: demo‑paket“ + kurzer Self‑Check (3 Fragen).
  - Warum steht `require(!paused)` im Modifier **und** gibt es `pause()`?  
  - Warum `address(0)` prüfen?  
  - Warum `enum` statt 0/1/2?

---

## Regeln gegen Vermeidung
- **5‑Min‑Start**; **erster Fehler zuerst**; **Copy→Edit (1–10 Zeilen)**.  
- **Blauer Button = lesen** (kein Chain‑Eintrag), **oranger Button = schreiben**.  
- **Done‑Zettel** statt To‑Do: 1 Satz + Screenshot je Tag.

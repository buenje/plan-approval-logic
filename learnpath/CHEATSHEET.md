# Cheatsheet — Bash & Git
> Für den täglichen Einsatz im Terminal. Keine Vollständigkeit nur was man wirklich braucht.(AI basiert)

---

## Was ist Bash?

Bash ist eine Sprache die direkt mit dem Betriebssystem spricht.
Du tippst einen Befehl — der Computer führt ihn aus.
Kein Compiler, kein Browser, kein Editor nötig. Nur Terminal.

---

## Navigation — wo bin ich, wo gehe ich hin?

```bash
pwd                        # Zeigt aktuellen Ordner (print working directory)
ls                         # Listet Dateien im aktuellen Ordner
ls -la                     # Listet alle Dateien inkl. versteckte

cd /Users/buenje/Documents/plan-approval-logic   # Ordner wechseln
cd ..                      # Einen Ordner zurück
cd ~                       # Zurück zum Home-Ordner
```

---

## Dateien und Ordner

```bash
mkdir ordnername           # Ordner erstellen
mkdir -p a/b/c             # Ordner inkl. Unterordner erstellen

cp quelle ziel             # Datei kopieren
mv quelle ziel             # Datei verschieben oder umbenennen
rm dateiname               # Datei löschen (unwiderruflich!)

find ~ -name "*.sol"       # Alle .sol-Dateien auf dem Mac suchen
cat dateiname              # Inhalt einer Datei anzeigen
```

---

## Git — die 10 Befehle die man täglich braucht

```bash
git status                 # Was hat sich geändert?
git pull                   # Änderungen von GitHub holen
git pull --rebase          # Holen + eigene Commits drüberlegen

git add dateiname          # Datei für Commit vorbereiten
git add .                  # Alle geänderten Dateien vorbereiten

git commit -m "feat: ..." # Änderung festhalten mit Beschreibung
git push                   # Änderungen zu GitHub schicken

git log --oneline          # Commit-Historie kompakt anzeigen
git diff                   # Was hat sich seit letztem Commit geändert?
git stash                  # Änderungen zwischenspeichern (ohne Commit)
```

---

## Commit-Message Konvention

```
feat:     neue Datei oder Funktion
fix:      Fehler behoben
docs:     Dokumentation geändert
refactor: Code umstrukturiert
chore:    Aufräumen, Umbenennen
```

Beispiele:
```
feat: add Tag07 learning contract
fix: correct Remix link in learnpath
docs: update README with demo link
chore: rename contract_final to WorkflowPFV_v1_deployed
```

---

## Typische Fehler und was sie bedeuten

| Fehlermeldung | Bedeutung | Lösung |
|---------------|-----------|--------|
| `fatal: pathspec did not match` | Datei existiert nicht | Pfad prüfen mit `ls` |
| `rejected: fetch first` | GitHub hat neuere Version | `git pull --rebase` |
| `cannot pull: unstaged changes` | Lokale Änderungen ungespeichert | `git stash` dann `git pull` |
| `command not found` | Befehl existiert nicht / Tippfehler | Befehl prüfen |
| `Permission denied` | Keine Rechte für diese Aktion | Mit `sudo` wiederholen (vorsichtig) |

---

## sed — Text in Dateien ersetzen

```bash
sed -i '' 's/alt/neu/g' dateiname
# -i ''     = direkt in Datei schreiben (Mac-Syntax)
# s/alt/neu = ersetze "alt" durch "neu"
# /g        = alle Vorkommen, nicht nur das erste
```

Beispiel:
```bash
sed -i '' 's/bunjeblockchain/buenje/g' demo/WorkflowPFV_Demo.html
```

---

## Nützliche Kombinationen

```bash
# Datei erstellen + sofort pushen
git add dateiname && git commit -m "feat: ..." && git push

# Pull + Push in einem
git pull --rebase && git push

# Ordner erstellen + Datei kopieren
mkdir -p zielordner && cp quelldatei zielordner/
```

---

## Wo lerne ich mehr?

- `man git` — vollständige Git-Dokumentation im Terminal
- `git --help` — Kurzübersicht
- https://ohshitgit.com — was tun wenn git schiefläuft (ehrlich und direkt)

---

*Dieses Cheatsheet ist Teil des 14-Tage-Lernpfads im plan-approval-logic Repository.*

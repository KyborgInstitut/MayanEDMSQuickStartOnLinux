# AGENTS.md — MayanEDMSQuickStartOnLinux

> **Für jeden Agenten, der in diesem Repo arbeitet** — Claude Code, Codex, Grok Build oder ein anderer.
> Lies diese Datei, bevor du eine Datei änderst. Sie ist der Einstieg, nicht das ganze Regelwerk.
>
> *Erzeugt aus `Notizarchiv/werkzeug/repo-netz.json` am 2026-09-22.*
> *Änderungen an den Abschnitten oberhalb der Handmarke gehören dorthin, nicht hierher.*

## Sperrliste — zuerst lesen

**Remote-Lage: GitHub + Forgejo (Dual-Push).** Was hier committet wird, verlässt das Haus.

- **Dieses Repo pusht nach GitHub** (öffentlich) — keine echten Hostnamen, IPs, Passwörter oder Backup-Pfade aus der eigenen Installation.
- **Skripte laufen mit `sudo`.** Änderungen an destruktiven Pfaden (Backup, Restore, Purge) nur mit Test auf einer Wegwerf-Instanz.

## Zweck

Menügeführtes Installations- und Verwaltungsskript für Mayan EDMS 4.10 auf Ubuntu 24.04 mit deutscher Geschäftskonfiguration.

## Wo die Wahrheit liegt

- Installations-/Verwaltungsskript

## Nachbarn

Die Repos liegen als Geschwisterordner unter `~/Documents/GitHub/`. Vollständige Karte:
`../Notizarchiv/REPO-NETZ.md`.

- `../paperless-ngx-quickstart` — Schwesterprojekt „Free tools for free people“

**Nicht die Schnittstelle eines Nachbar-Repos erfinden.** Wenn eine Aufgabe ein anderes Repo
berührt, dort nachsehen — der Pfad steht oben. Was dort die Wahrheit ist, wird hier nicht
nachgebaut und nicht überschrieben.

## Vorgeschichte (optional)

`HISTORIEN.md` im Repo-Wurzelverzeichnis hält fest, was in bisherigen Sitzungen zu diesem Repo
entschieden wurde — Weisungen des Inhabers im Wortlaut, dazu die Commit-Historie. **Die Datei ist
gitignored und bleibt lokal**; sie kann Material aus gesperrten Zonen enthalten.

Fehlt sie oder ist sie alt:

```bash
node ~/Documents/GitHub/Notizarchiv/werkzeug/gen-historien.mjs
```

## Umgangsformen

- **Arbeitssprache ist Deutsch** — Commits, Doku, Kommentare.
- **Ein Thema, ein Commit.** Keine Sammel-Commits über mehrere Belange.
- **Nicht zwei Agenten gleichzeitig in denselben Arbeitsbaum.** Für eine Zweitmeinung einen
  eigenen Worktree oder Branch nehmen.
- **Im Zweifel behalten und nachfragen, statt löschen.**

<!-- ab hier von Hand — wird beim Neuerzeugen nicht angetastet -->

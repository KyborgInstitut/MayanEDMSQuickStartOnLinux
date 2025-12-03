# 🚀 Kyborg Mayan EDMS – Installation, Backup & Restore (Docker Edition)

Dieses Repository enthält eine vollständige, stabile und produktiv erprobte Docker-Installation für **Mayan EDMS**, inklusive:

- 🟢 **Interaktives Installations-Script** (`kyborg-mayan.sh`)
- 🔵 **Cron-taugliches Backup-Script** (`mayan-backup.sh`)
- 🟣 **Vollständiges Restore-Script** (`mayan-restore.sh`)
- 🗄 **Strukturierte Datenablage** unter `/srv/mayan`
- 🐘 **PostgreSQL (externer Container)**
- 🔎 **Elasticsearch**
- ⚡ **Redis Cache**
- ⭐ Vollautomatische Konfiguration & Berechtigungen
- 🔄 Komplette Backup/Restore-Strategie

Die Lösung wurde so entwickelt, dass sie **immer** läuft – selbst nach Reboots, Updates, Migrationen und Desaster-Recovery.

---

# 📁 Ordnerstruktur

Alle Dateien folgen einer klaren Struktur:

/srv/mayan
├── app_data/               # Dateien & Dokumente (sehr wichtig!)
├── staging/                # Staging-Folder
├── watch/                  # Watch-Folder
├── redis_data/
├── elasticsearch_data/
└── docker-compose.yml

/var/lib/mayan_postgres     # PostgreSQL-Datenverzeichnis

/srv/mayan_backups
└── mayan-backup-YYYY-MM-DD_HH-MM-SS.tar.gz

---

# 🛠 Installation

## 1. Script herunterladen & ausführbar machen

```bash
wget https://raw.githubusercontent.com/DEIN_REPO/kyborg-mayan/main/kyborg-mayan.sh
sudo chmod +x kyborg-mayan.sh
~~~

2. Installation starten

~~~ bash
sudo ./kyborg-mayan.sh install
~~~

Der Installer fragt automatisch:
	•	🗝 PostgreSQL + Mayan-Passwort
	•	🌍 Zeitzone
	•	🇩🇪 UI-Sprache
	•	👤 Admin-User
	•	📧 SMTP-Einstellungen (optional)
	•	⚙️ Allowed Hosts
	•	🧰 Debug-Mode

Er generiert anschließend:
	•	docker-compose.yml
	•	alle benötigten Ordner
	•	sämtliche Berechtigungen
	•	startet den gesamten Stack
	•	wartet auf PostgreSQL-Bereitschaft


  🌐 Zugriff auf Mayan EDMS

Nach der Installation erreichbar unter:

http://SERVER-IP/

Admin-Login wird automatisch gesetzt.

💾 Backup

Script installieren

Speichere mayan-backup.sh unter:
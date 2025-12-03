# Mayan EDMS Quick Start on Linux (Ubuntu 24.04 LTS)

Comprehensive management and installation script for Mayan EDMS 4.10 with German business configuration.

## 🎯 Quick Start

```bash
# Download repository
git clone https://github.com/YOUR_USERNAME/MayanEDMSQuickStartOnLinux.git
cd MayanEDMSQuickStartOnLinux

# Run interactive management script
sudo bash kyborg_mayan.sh
```

## 📋 Features

### Menu-Driven Management

The new `kyborg_mayan.sh` provides an interactive menu with:

```
╔════════════════════════════════════════════════════════════╗
║  Mayan EDMS – Management & Installation Script             ║
╠════════════════════════════════════════════════════════════╣
║  Status: Mayan EDMS ist installiert ✓                      ║
╠════════════════════════════════════════════════════════════╣
║  1) Mayan EDMS installieren (Erstinstallation)            ║
║     → Inklusive preTypes Import (optional)                ║
║                                                            ║
║  2) SMB/Scanner-Zugang einrichten                          ║
║     → Samba-Freigabe für Scanner/macOS                     ║
║                                                            ║
║  3) Backup erstellen                                       ║
║     → Sichert Datenbank + Dateien                          ║
║                                                            ║
║  4) Backup-Cronjob einrichten                              ║
║     → Automatische tägliche Backups                        ║
║                                                            ║
║  5) Backup wiederherstellen                                ║
║     → Restore aus Backup-Archiv                            ║
║                                                            ║
║  6) Mayan Status anzeigen                                  ║
║     → Container-Status, Logs, URLs                         ║
║                                                            ║
║  0) Beenden                                                ║
╚════════════════════════════════════════════════════════════╝
```

## 🚀 Option 1: Initial Installation

### What It Does

- ✅ Installs Mayan EDMS 4.10 with all dependencies
- ✅ Configures PostgreSQL 15, Redis 7, Elasticsearch 7.17
- ✅ Sets up proper directory structure and permissions
- ✅ Optionally imports preTypes (273 metadata types, 113 document types, etc.)
- ✅ Interactive configuration (passwords, timezone, SMTP, etc.)

### Installation Steps

1. Run: `sudo bash kyborg_mayan.sh`
2. Choose option **1** (Mayan EDMS installieren)
3. Follow the prompts:
   - Set PostgreSQL/Mayan password (min. 16 chars)
   - Configure timezone (default: Europe/Berlin)
   - Set language (default: de)
   - Create admin user
   - Optional: Configure SMTP for email
   - Optional: Import preTypes

### What Gets Installed

**Docker containers:**
- `mayan_postgres` - PostgreSQL 15.11
- `mayan_redis` - Redis 7-alpine
- `mayan_elasticsearch` - Elasticsearch 7.17.22
- `mayan_app` - Mayan EDMS s4.10

**Directories:**
- `/srv/mayan/` - Main application directory
- `/var/lib/mayan_postgres/` - Database storage
- `/srv/mayan/app_data/` - Mayan application data
- `/srv/mayan/staging/` - Staging folder for imports
- `/srv/mayan/watch/` - Watch folder for automatic imports

### Post-Installation

Access Mayan at: `http://YOUR_SERVER_IP`

If you imported preTypes, follow the post-import steps:
1. Set user passwords: System → Benutzer
2. Assign role permissions: System → Rollen
3. Configure saved searches: Suche → Erweiterte Suche

See: `IMPORT_GUIDE.md` for details

---

## 📁 Option 2: SMB/Scanner Setup

### What It Does

- ✅ Installs and configures Samba
- ✅ Creates SMB shares for Scanner and macOS access
- ✅ Sets up proper permissions and authentication
- ✅ Brother Scanner compatible (ntlmv1-permitted)
- ✅ macOS compatible (fruit/catia VFS modules)

### Setup Process

1. Run: `sudo bash kyborg_mayan.sh`
2. Choose option **2** (SMB/Scanner-Zugang einrichten)
3. Follow the prompts to configure shares

**Creates shares:**
- `mayan_staging` - For manual file drops
- `mayan_watch` - For automatic imports
- `mayan_scanner` - For scanner uploads

### Connecting from Scanner

```
Protocol: SMB/CIFS
Server: YOUR_SERVER_IP
Share: mayan_scanner
Username: [configured during setup]
Password: [configured during setup]
```

---

## 💾 Option 3: Create Backup

### What It Does

- ✅ Creates PostgreSQL dump
- ✅ Backs up all data directories
- ✅ Includes docker-compose.yml
- ✅ Compresses to `.tar.gz`
- ✅ Automatically rotates old backups (keeps 7)

### Creating Backup

1. Run: `sudo bash kyborg_mayan.sh`
2. Choose option **3** (Backup erstellen)
3. Wait for backup to complete

**Backup location:** `/srv/mayan_backups/mayan-backup-YYYY-MM-DD_HH-MM-SS.tar.gz`

### What's Included

- PostgreSQL database dump
- Mayan application data
- Redis data
- Elasticsearch indices
- Staging and watch folders
- Configuration files

---

## ⏰ Option 4: Setup Backup Cronjob

### What It Does

- ✅ Configures automatic scheduled backups
- ✅ Multiple time options (daily, weekly, custom)
- ✅ Logs to `/var/log/mayan_backup.log`
- ✅ Easy to modify or remove

### Setting Up Cronjob

1. Run: `sudo bash kyborg_mayan.sh`
2. Choose option **4** (Backup-Cronjob einrichten)
3. Select schedule:
   - Daily at 02:00
   - Daily at 03:00
   - Daily at 04:00
   - Weekly (Sunday at 02:00)
   - Custom cron schedule

**View cronjob:** `crontab -l`
**View logs:** `tail -f /var/log/mayan_backup.log`

---

## ♻️ Option 5: Restore Backup

### What It Does

- ✅ Lists available backups
- ✅ Stops Mayan containers
- ✅ Restores database
- ✅ Restores all data directories
- ✅ Restarts Mayan

### Restoring Backup

1. Run: `sudo bash kyborg_mayan.sh`
2. Choose option **5** (Backup wiederherstellen)
3. Select backup from list
4. Confirm restore operation
5. Wait for completion

**⚠️ Warning:** This will overwrite current data!

---

## 📊 Option 6: Show Status

### What It Shows

- ✅ Container status (running/stopped)
- ✅ Disk usage statistics
- ✅ Access URLs
- ✅ Recent logs
- ✅ Useful commands

### Viewing Status

1. Run: `sudo bash kyborg_mayan.sh`
2. Choose option **6** (Mayan Status anzeigen)

---

## 📦 preTypes - German Business Configuration

The optional preTypes import provides a comprehensive German business setup:

### Contents

| Type | Count | Description |
|------|-------|-------------|
| Metadata Types | 273 | Invoice fields, GDPR tracking, tax info, etc. |
| Document Types | 113 | Invoices, contracts, HR docs, GDPR forms, etc. |
| Tags | 116 | Status tags, sources, payment states, etc. |
| Cabinets | 100+ | Organized folder structure |
| Workflows | 10 | Invoice processing, GDPR requests, contracts, etc. |
| Users | 9 | Pre-configured users (passwords need to be set) |
| Roles | 15 | Permission roles (permissions need assignment) |
| Searches | 40+ | Pre-defined searches (queries need configuration) |

### Covered Areas

- **Accounting:** Invoices, payments, tax filings, GoBD compliance
- **GDPR/DSGVO:** Data requests, deletion, breaches (72h notification)
- **Contracts:** Management, cancellation tracking, renewal
- **E-commerce:** Shopify, Amazon, eBay, returns, marketplaces
- **HR:** Employment contracts, payroll, sick leave
- **Legal:** Court documents, authorities, deadlines
- **Tax:** UStVA, declarations, audits, OSS
- **Customs:** EUR.1, Intrastat, declarations
- **Insurance:** Policies, claims, processing
- **IT:** Licenses, security, documentation

See `preTypes/README.md` for full details.

---

## 🗂️ Project Structure

```
MayanEDMSQuickStartOnLinux/
├── kyborg_mayan.sh          # Main menu-driven management script
├── mayan_backup.sh          # Standalone backup script
├── mayan_restore.sh         # Standalone restore script
├── mayan_smb.sh             # SMB/Scanner setup script
├── import_preTypes.sh       # PreTypes import script
├── import_cabinets_api.py   # API-based cabinet import
├── IMPORT_GUIDE.md          # PreTypes import guide
├── README.md                # This file
├── LICENSE                  # License information
└── preTypes/                # German business configuration
    ├── README.md            # Detailed preTypes documentation
    ├── 01_metadata_types.json
    ├── 02_document_types.json
    ├── 03_tags.json
    ├── 04_cabinets.json
    ├── 05_workflows.json
    ├── 06_users.json
    ├── 07_roles.json
    ├── 08_document_type_metadata_types.json
    ├── 09_saved_searches.json
    └── generate_users.py    # Helper to generate users with passwords
```

---

## 🔧 Manual Operations

### Access Mayan Container

```bash
cd /srv/mayan
docker compose exec -it mayan_app /bin/bash
```

### View Logs

```bash
cd /srv/mayan
docker compose logs -f mayan_app      # Follow app logs
docker compose logs -f mayan_postgres # Follow database logs
docker compose logs --tail=100        # Last 100 lines (all containers)
```

### Restart Mayan

```bash
cd /srv/mayan
docker compose restart
```

### Stop Mayan

```bash
cd /srv/mayan
docker compose down
```

### Start Mayan

```bash
cd /srv/mayan
docker compose up -d
```

### Update Mayan

```bash
cd /srv/mayan
docker compose pull
docker compose up -d
```

---

## 📋 System Requirements

### Minimum

- Ubuntu 24.04 LTS (also works on 22.04)
- 4 GB RAM
- 20 GB disk space
- Dedicated VM or Proxmox KVM (**NOT LXC!**)

### Recommended

- Ubuntu 24.04 LTS
- 8 GB RAM
- 100 GB disk space (depends on document volume)
- SSD storage

### Ports Used

- `80` - Mayan web interface (HTTP)

---

## 🛡️ Security Notes

### Passwords

- Minimum 16 characters required
- Change default passwords immediately after setup
- Use strong, unique passwords for:
  - PostgreSQL database
  - Mayan admin account
  - SMB shares
  - Additional users

### Firewall

Consider restricting access:

```bash
# Allow only from specific IP
sudo ufw allow from YOUR_IP to any port 80

# Or allow from subnet
sudo ufw allow from 192.168.1.0/24 to any port 80

# Enable firewall
sudo ufw enable
```

### Updates

Keep system updated:

```bash
sudo apt update && sudo apt upgrade -y
```

Update Docker images regularly via menu option or manually.

---

## 🐛 Troubleshooting

### Container Won't Start

Check logs:
```bash
cd /srv/mayan
docker compose logs
```

### Database Connection Errors

Ensure PostgreSQL is ready:
```bash
docker compose logs mayan_postgres | grep "ready to accept connections"
```

### Import Errors

See `IMPORT_GUIDE.md` for detailed troubleshooting of preTypes imports.

### Permission Errors

Reset permissions:
```bash
cd /srv/mayan
sudo chown -R 1001:1001 app_data staging watch
sudo chown -R 999:999 /var/lib/mayan_postgres
sudo chown -R 100:100 redis_data
sudo chown -R 1000:1000 elasticsearch_data
```

### Out of Disk Space

Check usage:
```bash
du -sh /srv/mayan/*
du -sh /var/lib/mayan_postgres
du -sh /srv/mayan_backups
```

Clean old backups:
```bash
# Keep only last 3 backups
ls -1t /srv/mayan_backups/mayan-backup-*.tar.gz | tail -n +4 | xargs rm -f
```

---

## 📝 License

See `LICENSE` file for details.

---

## 🤝 Contributing

Issues and pull requests welcome!

---

## 📚 Documentation Links

- **Mayan EDMS Official Docs:** https://docs.mayan-edms.com/
- **Docker Documentation:** https://docs.docker.com/
- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **GoBD Compliance Info:** https://www.bzst.de/

---

## ✨ Credits

Created for easy deployment of Mayan EDMS with German business requirements.

**Mayan EDMS:** https://www.mayan-edms.com/

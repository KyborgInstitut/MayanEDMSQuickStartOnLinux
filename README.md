# Mayan EDMS Quick Start on Linux (Ubuntu 24.04 LTS)

Comprehensive menu-driven management and installation script for **Mayan EDMS 4.10** with German business configuration (preTypes), automatic diagnostics, and troubleshooting tools.

## 🎯 Quick Start

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/MayanEDMSQuickStartOnLinux.git
cd MayanEDMSQuickStartOnLinux

# Run interactive management script
sudo bash kyborg_mayan.sh
```

**That's it!** The menu-driven script guides you through installation, backup, restore, troubleshooting, and more.

---

## 📋 Features Overview

### 🚀 **Interactive Menu System**

All operations accessible through a single, user-friendly menu:

```
╔════════════════════════════════════════════════════════════╗
║  Mayan EDMS – Management & Installation Script             ║
╠════════════════════════════════════════════════════════════╣
║  Status: Mayan EDMS ist installiert ✓                      ║
╠════════════════════════════════════════════════════════════╣
║  1) Mayan EDMS installieren (Erstinstallation)            ║
║  2) SMB/Scanner-Zugang einrichten                          ║
║  3) Backup erstellen                                       ║
║  4) Backup-Cronjob einrichten                              ║
║  5) Backup wiederherstellen                                ║
║  6) Mayan Status anzeigen                                  ║
║  7) Dokumentquellen konfigurieren                          ║
║  8) Problemlösung & Diagnose                               ║
║  0) Beenden                                                ║
╚════════════════════════════════════════════════════════════╝
```

### ✨ **Key Highlights**

- ✅ **One-command installation** - Complete Mayan EDMS setup in minutes
- ✅ **Production-ready configuration** - All critical fixes pre-applied (Celery broker, worker timeouts)
- ✅ **German business preTypes** - 273 metadata types, 113 document types, workflows, tags
- ✅ **Automatic troubleshooting** - Built-in diagnostic and repair tools
- ✅ **Location independent** - Scripts work from any directory
- ✅ **No user creation needed** - Uses Mayan's default admin user (admin/admin)
- ✅ **Scanner/SMB integration** - Direct scanner-to-Mayan document upload
- ✅ **Automated backups** - Schedule daily/weekly backups with cronjobs
- ✅ **Document sources auto-config** - Watch and staging folders pre-configured

---

## 📖 Detailed Menu Options

### **Option 1: Mayan EDMS installieren** (Initial Installation)

**What it does:**
- Installs Docker and Docker Compose
- Creates Mayan EDMS 4.10 with PostgreSQL 16, Redis 7, Elasticsearch 8.15.2
- **Pre-configures critical fixes:**
  - ✅ Celery broker: `redis://` (not memory://)
  - ✅ Worker timeouts: 300s (Gunicorn), 7200s (Celery)
  - ✅ Proper user context for all commands
- Sets up directory structure with correct permissions
- Creates admin user automatically (username: `admin`, password: `admin`)
- Optional: Imports German business preTypes
- Optional: Configures document sources (watch/staging folders)

**Installation steps:**

1. Run: `sudo bash kyborg_mayan.sh`
2. Choose option **1**
3. Answer prompts:
   - **PostgreSQL password** (min. 16 chars) - Database security
   - **Timezone** (default: Europe/Berlin)
   - **Language** (default: de - German)
   - **SMTP settings** (optional) - For email notifications
   - **preTypes import** (optional) - German business configuration
   - **Document sources** (optional) - Watch/staging folder setup

**Post-installation:**

Access Mayan at: `http://YOUR_SERVER_IP`

**Default login:**
- Username: `admin`
- Password: `admin`
- ⚠️ **Change password immediately after first login!**

**What gets installed:**

| Container | Service | Version |
|-----------|---------|---------|
| mayan_app | Mayan EDMS | 4.10 |
| mayan_postgres | PostgreSQL | 16.11 |
| mayan_redis | Redis | 7-alpine |
| mayan_elasticsearch | Elasticsearch | 8.15.2 |

**Directories created:**

| Path | Purpose | Owner |
|------|---------|-------|
| `/srv/mayan/` | Main installation directory | root |
| `/srv/mayan/app_data/` | Mayan application data | mayan (1001:1001) |
| `/srv/mayan/staging/` | Manual upload folder | mayan (1001:1001) |
| `/srv/mayan/watch/` | Auto-import folder | mayan (1001:1001) |
| `/srv/mayan/postgres_data/` | Database storage | postgres (999:999) |
| `/srv/mayan/redis_data/` | Redis persistence | redis (100:100) |
| `/srv/mayan/elasticsearch_data/` | Search indices | elasticsearch (1000:1000) |
| `/srv/mayan_backups/` | Backup archives | root |

---

### **Option 2: SMB/Scanner-Zugang einrichten** (SMB/Scanner Setup)

**What it does:**
- Installs and configures Samba server
- Creates network shares for document upload
- Configures Brother Scanner compatibility (ntlmv1-permitted)
- Enables macOS file sharing (fruit/catia VFS modules)
- Sets up proper authentication and permissions

**Network shares created:**

| Share Name | Path | Purpose | Delete after import? |
|------------|------|---------|---------------------|
| `mayan_staging` | `/srv/mayan/staging/` | Manual upload via GUI | No |
| `mayan_watch` | `/srv/mayan/watch/` | Automatic import | Yes |
| `mayan_scanner` | `/srv/mayan/watch/` | Scanner direct upload | Yes |

**Scanner configuration example:**

```
Protocol: SMB/CIFS
Server: YOUR_SERVER_IP
Share: mayan_scanner
Path: /
Username: [configured during setup]
Password: [configured during setup]
```

**macOS connection:**

1. Finder → Go → Connect to Server (⌘K)
2. Enter: `smb://YOUR_SERVER_IP/mayan_staging`
3. Login with configured credentials
4. Drag-and-drop PDFs to upload

**Windows connection:**

1. File Explorer → Network
2. `\\YOUR_SERVER_IP\mayan_staging`
3. Enter credentials when prompted

---

### **Option 3: Backup erstellen** (Create Backup)

**What it does:**
- Stops Mayan containers gracefully
- Creates PostgreSQL database dump
- Archives all data directories
- Compresses to `.tar.gz` (typically 50-80% compression)
- Automatically rotates old backups (keeps last 7)
- Restarts Mayan containers

**Backup includes:**
- ✅ PostgreSQL database dump (SQL format)
- ✅ Mayan application data (documents, OCR data, thumbnails)
- ✅ Redis data (cache, Celery queues)
- ✅ Elasticsearch indices (search data)
- ✅ Staging folder contents
- ✅ Watch folder contents
- ✅ `docker-compose.yml` configuration

**Backup location:**
```
/srv/mayan_backups/mayan-backup-YYYY-MM-DD_HH-MM-SS.tar.gz
```

**Manual backup:**
```bash
sudo bash kyborg_mayan.sh
# Choose option 3

# Or run standalone script:
sudo bash mayan_backup.sh
```

**Typical backup sizes:**
- Small installation (< 1000 docs): 1-5 GB
- Medium installation (< 10,000 docs): 10-50 GB
- Large installation (> 10,000 docs): 50+ GB

---

### **Option 4: Backup-Cronjob einrichten** (Setup Backup Cronjob)

**What it does:**
- Configures automatic scheduled backups
- Multiple schedule options available
- Creates log file for backup monitoring
- Easy to modify or remove later

**Schedule options:**

1. **Daily at 02:00** - Most common choice
2. **Daily at 03:00** - Alternative time
3. **Daily at 04:00** - Alternative time
4. **Weekly (Sunday at 02:00)** - For smaller changes
5. **Custom cron schedule** - Advanced users

**Cronjob details:**

```bash
# Example: Daily at 02:00
0 2 * * * /srv/mayan_backups/mayan_backup.sh >> /var/log/mayan_backup.log 2>&1
```

**Monitoring backups:**

```bash
# View backup log
tail -f /var/log/mayan_backup.log

# List all cronjobs
crontab -l

# List backups by date
ls -lht /srv/mayan_backups/

# Check disk space
df -h /srv/
```

**Remove cronjob:**

```bash
crontab -e
# Delete the mayan_backup.sh line
# Save and exit
```

---

### **Option 5: Backup wiederherstellen** (Restore Backup)

**What it does:**
- Lists all available backups with timestamps
- Stops Mayan containers
- Restores PostgreSQL database
- Restores all data directories
- Recreates directory structure
- Restarts Mayan with restored data

**⚠️ Warning:** This overwrites **ALL** current data!

**Restore process:**

1. Run: `sudo bash kyborg_mayan.sh`
2. Choose option **5**
3. Select backup from list:
   ```
   Available backups:
   1) mayan-backup-2024-12-04_03-00-00.tar.gz (5.2G)
   2) mayan-backup-2024-12-03_03-00-00.tar.gz (5.1G)
   3) mayan-backup-2024-12-02_03-00-00.tar.gz (4.9G)
   ```
4. Confirm restore operation
5. Wait for completion (several minutes depending on size)

**What gets restored:**
- ✅ All documents and metadata
- ✅ User accounts and permissions
- ✅ Tags, cabinets, workflows
- ✅ Search indices
- ✅ System settings
- ✅ Document sources configuration

**Best practices:**
- Test restores regularly
- Keep backups on separate storage
- Document backup/restore procedures
- Verify restored installation works

---

### **Option 6: Mayan Status anzeigen** (Show Status)

**What it shows:**
- Container status (running/stopped/unhealthy)
- CPU and memory usage per container
- Disk space usage
- Access URL and port
- Recent log entries (last 30 lines)
- Useful management commands

**Example output:**

```
Container Status:
mayan_app        running (healthy)    8m ago
mayan_postgres   running (healthy)    8m ago
mayan_redis      running              8m ago
mayan_elasticsearch running           8m ago

Disk Usage:
/srv/mayan               12G
/var/lib/mayan_postgres  2.5G
/srv/mayan_backups       15G

Access:
URL: http://192.168.1.100
Login: admin / admin

Recent Logs:
[2024-12-04 10:23:45] Celery worker ready
[2024-12-04 10:23:47] Gunicorn listening on 0.0.0.0:8000
[2024-12-04 10:24:12] Document uploaded: invoice_2024.pdf
```

**Quick status check:**

```bash
# Via menu
sudo bash kyborg_mayan.sh
# Choose option 6

# Manual checks
cd /srv/mayan
docker compose ps                    # Container status
docker compose logs -f mayan_app     # Follow logs
docker stats --no-stream             # Resource usage
```

---

### **Option 7: Dokumentquellen konfigurieren** (Configure Document Sources)

**What it does:**
- Automatically configures watch and staging folders in Mayan GUI
- Runs Python script via Django shell
- Creates document sources with proper settings
- No manual GUI configuration needed

**Document sources created:**

| Source Type | Path in Container | Host Path | Purpose |
|-------------|-------------------|-----------|---------|
| **Watch Folder** | `/watch_folder/` | `/srv/mayan/watch/` | Automatic import, files deleted after |
| **Staging Folder** | `/staging_folder/` | `/srv/mayan/staging/` | Manual upload, files preserved |

**Configuration details:**

```python
Watch Folder:
- Enabled: Yes
- Delete after: Yes (files removed after successful import)
- Interval: Check every 60 seconds
- Recursive: No (only root folder)
- Document type: Uses default or prompts user

Staging Folder:
- Enabled: Yes
- Delete after: No (files remain for re-import if needed)
- Accessible via: Setup → Sources → Staging folder
```

**Usage after configuration:**

**Watch Folder (automatic):**
```bash
# Copy document to watch folder
sudo cp invoice.pdf /srv/mayan/watch/

# Mayan automatically:
# 1. Detects the file (within 60 seconds)
# 2. Imports the document
# 3. Performs OCR
# 4. Deletes the file
# 5. Document appears in Mayan GUI
```

**Staging Folder (manual):**
```bash
# Copy document to staging folder
sudo cp contract.pdf /srv/mayan/staging/

# In Mayan GUI:
# 1. Go to: Setup → Sources → Staging folder
# 2. Select: contract.pdf
# 3. Choose document type
# 4. Click: Upload
# 5. File remains in staging folder
```

**Via SMB/Network share:**
- Connect to `\\SERVER\mayan_watch` or `\\SERVER\mayan_staging`
- Drag and drop files
- Documents import automatically (watch) or appear for selection (staging)

**Verification:**

After configuration, verify in Mayan GUI:
1. Login → Setup → Sources → Document sources
2. You should see:
   - "Watch Folder" (enabled)
   - "Staging Folder" (enabled)

**Troubleshooting:**

If sources don't appear:
```bash
# Check container is running
docker compose ps mayan_app

# Re-run configuration
sudo bash kyborg_mayan.sh
# Choose option 7
```

---

### **Option 8: Problemlösung & Diagnose** (Troubleshooting & Diagnostics)

**Complete diagnostic and repair submenu** with 5 specialized tools to fix common issues:

```
╔════════════════════════════════════════════════════════════╗
║  Problemlösung & Diagnose                                  ║
╠════════════════════════════════════════════════════════════╣
║  1) Celery Broker reparieren (KRITISCH)                   ║
║  2) Worker-Timeouts beheben                               ║
║  3) Worker-Diagnose ausführen                             ║
║  4) Konfiguration verifizieren & Import testen            ║
║  5) Alle Diagnosen & Reparaturen (komplett)              ║
║  0) Zurück zum Hauptmenü                                  ║
╚════════════════════════════════════════════════════════════╝
```

#### **8.1) Celery Broker reparieren** (CRITICAL FIX)

**Problem:** Celery using `memory://` instead of `redis://`

**Symptoms:**
- Documents upload but never appear in Mayan
- Tasks disappear after container restart
- No document processing (OCR, conversion, etc.)

**What it fixes:**
- Updates `docker-compose.yml` with correct Celery settings:
  ```yaml
  MAYAN_CELERY_BROKER_URL: redis://mayan_redis:6379/1
  MAYAN_CELERY_RESULT_BACKEND: redis://mayan_redis:6379/1
  ```
- Backs up original configuration
- Restarts containers with new settings
- Verifies fix was successful

**When to use:**
- After upgrading Mayan
- If documents won't import
- After manual docker-compose.yml edits

**Script:** `fix_celery_broker.sh`

---

#### **8.2) Worker-Timeouts beheben**

**Problem:** Workers killed mid-processing

**Symptoms:**
- Error: `WORKER TIMEOUT` in logs
- Large PDFs (>5 MB) fail to import
- OCR processing fails on multi-page documents
- Workers restart during processing

**What it fixes:**
- Increases Gunicorn timeout: 120s → 300s (5 minutes)
- Increases Celery task time limit: 3600s → 7200s (2 hours)
- Increases soft time limit: 3300s → 6900s (1h 55min)
- Clears stuck Celery tasks
- Restarts workers with new settings

**Timeout settings:**

| Component | Before | After | Purpose |
|-----------|--------|-------|---------|
| Gunicorn | 120s | 300s | Web request timeout |
| Celery hard limit | 3600s | 7200s | Task termination |
| Celery soft limit | 3300s | 6900s | Graceful shutdown warning |

**When to use:**
- WORKER TIMEOUT errors
- Large file import failures
- OCR processing hangs
- Multi-page document issues

**Script:** `fix_worker_timeouts.sh`

---

#### **8.3) Worker-Diagnose ausführen**

**Comprehensive worker diagnostics** - Shows system health and identifies issues

**What it checks:**

1. **Celery Worker Status**
   - Worker processes running
   - Active tasks
   - Queue lengths
   - Registered tasks

2. **Celery Queues**
   - Queue names and task counts
   - Stuck tasks
   - Failed tasks

3. **OCR Dependencies**
   - Tesseract (OCR engine)
   - LibreOffice (Office document conversion)
   - Poppler (PDF utilities)
   - ImageMagick (image processing)
   - Ghostscript (PDF rendering)

4. **Elasticsearch Health**
   - Cluster status (green/yellow/red)
   - Index count
   - Document count
   - Disk space

5. **Container Resources**
   - CPU usage per container
   - Memory usage
   - Disk I/O
   - Network traffic

6. **Recent Errors**
   - Last 50 error messages
   - Critical issues
   - Warnings

**Example output:**

```
✓ Celery Worker: 4 workers active
✓ OCR Tools: All dependencies installed
✓ Elasticsearch: Green (healthy)
⚠ High memory usage: mayan_app (75%)
✗ Stuck tasks: 2 tasks in queue > 1 hour

Recommendations:
1. Increase memory allocation
2. Run: Option 8.2 (Worker-Timeouts beheben)
3. Clear stuck tasks
```

**When to use:**
- Before reporting issues
- After installation (verify setup)
- Regular health checks
- Performance troubleshooting

**Script:** `diagnose_workers.sh`

---

#### **8.4) Konfiguration verifizieren & Import testen**

**Verifies configuration and tests document import capability**

**What it checks:**

1. **docker-compose.yml Settings**
   - Celery broker URL
   - Result backend
   - Timeout settings
   - Environment variables

2. **Container Environment**
   - Running environment variables
   - Configuration applied correctly

3. **Supervisor Processes**
   - Gunicorn (web server)
   - Celery worker
   - Celery beat (scheduler)

4. **Document Sources**
   - Sources configured in database
   - Source paths accessible
   - Permissions correct

5. **Upload Folders**
   - Files in staging folder
   - Files in watch folder
   - File permissions (mayan:mayan)

6. **Test Import**
   - Creates test document
   - Copies to staging folder
   - Verifies visibility
   - Checks permissions

**Example output:**

```
[1/8] Checking docker-compose.yml
✓ MAYAN_GUNICORN_TIMEOUT: 300
✓ MAYAN_CELERY_TASK_TIME_LIMIT: 7200
✓ MAYAN_CELERY_BROKER_URL: redis://mayan_redis:6379/1

[2/8] Checking container environment
✓ All settings applied correctly

[3/8] Checking worker processes
✓ gunicorn: RUNNING
✓ celery_worker: RUNNING
✓ celery_beat: RUNNING

[4/8] Checking document sources
Total sources: 2
  - Watch Folder (enabled)
  - Staging Folder (enabled)

[5/8] Creating test document
✓ Test file copied successfully
✓ Permissions: mayan:mayan (1001:1001)

Recommendations:
✓ Configuration is correct
✓ Ready for document import
```

**When to use:**
- After fresh installation
- Before importing documents
- After configuration changes
- Troubleshooting import failures

**Script:** `verify_and_test_import.sh`

---

#### **8.5) Alle Diagnosen & Reparaturen (komplett)**

**Runs all diagnostic and repair tools sequentially**

**Execution order:**

1. **Worker-Diagnose** (8.3)
   - Identify all issues first

2. **Celery Broker reparieren** (8.1)
   - Fix critical broker issue

3. **Worker-Timeouts beheben** (8.2)
   - Increase timeout settings

4. **Konfiguration verifizieren** (8.4)
   - Verify all fixes applied
   - Test import capability

**When to use:**
- After upgrading Mayan
- Existing installation with issues
- Complete health check
- "Fix everything" option

**Duration:** 5-10 minutes depending on container restart times

---

## 📦 preTypes - German Business Configuration

**Optional import** during installation providing comprehensive German business setup.

### What's Included

| Type | Count | Files | Status |
|------|-------|-------|--------|
| **Metadata Types** | 273 | `01_metadata_types.json` | ✅ Auto-imported |
| **Document Types** | 113 | `02_document_types.json` | ✅ Auto-imported |
| **Tags** | 116 | `03_tags.json` | ✅ Auto-imported |
| **Workflows** | 10 | `05_workflows.json` | ✅ Auto-imported |
| **Roles** | 15 | `07_roles.json` | ✅ Auto-imported (need permissions) |
| **Metadata Mappings** | 1000+ | `08_document_type_metadata_types.json` | ✅ Auto-imported |
| **Cabinets** | 100+ | `04_cabinets_DISABLED.json` | ❌ Manual setup required |
| **Saved Searches** | 40+ | `09_saved_searches_DISABLED.json` | ❌ Manual setup required |
| **Users** | - | `06_users_DISABLED.json` | ❌ Disabled (use default admin) |

### Business Areas Covered

**Accounting & Finance:**
- Invoice processing (incoming/outgoing)
- Payment tracking
- Tax filings (UStVA, declarations)
- Bank statements
- GoBD compliance documentation

**GDPR/DSGVO Compliance:**
- Data access requests
- Deletion requests
- Data breach reporting (72-hour notification)
- Processing records (Verarbeitungsverzeichnis)
- Consent management

**Contracts & Legal:**
- Contract lifecycle management
- Cancellation tracking
- Renewal reminders
- Court documents
- Authority correspondence

**E-Commerce:**
- Marketplace documents (Amazon, eBay, Shopify)
- Returns processing
- Shipping documents
- Platform invoices

**Human Resources:**
- Employment contracts
- Payroll documents
- Sick leave tracking
- Personnel files

**Tax & Customs:**
- UStVA (VAT returns)
- OSS (One-Stop-Shop) filings
- Customs declarations
- EUR.1 certificates
- Intrastat reports

**Insurance:**
- Policy management
- Claims processing
- Correspondence

**IT & Security:**
- Software licenses
- Security documentation
- IT contracts

### Post-Import Tasks

After importing preTypes, complete these steps in Mayan GUI:

**1. Assign Role Permissions**
```
System → Roles → [Select Role] → Permissions
Assign appropriate permissions for each role
```

**2. Create Users** (if needed beyond admin)
```
System → Users → Create user
Assign roles to users
```

**3. Configure Workflows** (optional)
```
System → Workflows → [Select Workflow]
Review states and transitions
Customize if needed
```

**4. Setup Cabinets** (manual)
```
Cabinets → Create cabinet
Build folder structure based on your needs
Reference: preTypes/04_cabinets_DISABLED.json
```

**5. Create Saved Searches** (manual)
```
Search → Advanced search
Define search criteria
Click: Save this search
```

### Documentation

- **Full preTypes guide:** `preTypes/README.md`
- **Import guide:** `IMPORT_GUIDE.md`
- **GoBD documentation:** `preTypes/GOBD_VERFAHRENSDOKUMENTATION.md`
- **Manual setup:** `preTypes/MANUAL_SETUP_GUIDE.md`

---

## 🗂️ Project Structure

```
MayanEDMSQuickStartOnLinux/
│
├── kyborg_mayan.sh                    # 🎯 Main menu-driven script
│
├── 📝 Installation & Configuration
│   ├── configure_sources.py           # Document sources auto-config
│   └── setup_sources.sh               # Sources setup wrapper
│
├── 💾 Backup & Restore
│   ├── mayan_backup.sh                # Backup creation
│   └── mayan_restore.sh               # Backup restoration
│
├── 🔧 Troubleshooting Tools
│   ├── diagnose_workers.sh            # Worker diagnostics
│   ├── fix_celery_broker.sh           # Fix Celery broker (CRITICAL)
│   ├── fix_worker_timeouts.sh         # Fix timeout errors
│   └── verify_and_test_import.sh      # Config verification & import test
│
├── 📡 Network & Integration
│   └── mayan_smb.sh                   # SMB/Scanner setup
│
├── 📦 preTypes Import
│   ├── import_preTypes.sh             # Automated import script
│   ├── import_cabinets_api.py         # Cabinet import (API method)
│   └── preTypes/                      # German business config
│       ├── 01_metadata_types.json     # 273 metadata fields
│       ├── 02_document_types.json     # 113 document types
│       ├── 03_tags.json               # 116 tags
│       ├── 05_workflows.json          # 10 workflows
│       ├── 07_roles.json              # 15 roles
│       ├── 08_document_type_metadata_types.json  # Mappings
│       ├── 04_cabinets_DISABLED.json  # Cabinet structure (manual)
│       ├── 09_saved_searches_DISABLED.json  # Searches (manual)
│       ├── 06_users_DISABLED.json     # Users (disabled)
│       ├── generate_users.py          # User generation helper
│       ├── README.md                  # Detailed preTypes docs
│       ├── MANUAL_SETUP_GUIDE.md      # Manual setup instructions
│       └── GOBD_VERFAHRENSDOKUMENTATION.md  # GoBD compliance
│
└── 📚 Documentation
    ├── README.md                      # This file
    ├── CHANGELOG.md                   # Version history
    ├── IMPORT_GUIDE.md                # preTypes import guide
    ├── TROUBLESHOOTING.md             # Common issues & solutions
    ├── SOURCES_GUIDE.md               # Document sources guide
    ├── PORTABLE_INSTALLATION.md       # Location independence
    └── VERSION_2.1_SUMMARY.md         # Version 2.1 updates
```

---

## 🔧 System Requirements

### Minimum Requirements

| Component | Specification |
|-----------|---------------|
| **OS** | Ubuntu 24.04 LTS (also 22.04) |
| **RAM** | 4 GB |
| **Disk** | 20 GB |
| **CPU** | 2 cores |
| **Environment** | Dedicated VM or Proxmox KVM |

⚠️ **Not supported:** LXC containers (Docker-in-Docker issues)

### Recommended Requirements

| Component | Specification |
|-----------|---------------|
| **OS** | Ubuntu 24.04 LTS |
| **RAM** | 8 GB |
| **Disk** | 100 GB SSD |
| **CPU** | 4 cores |
| **Backup** | Separate storage for backups |

### Ports Used

| Port | Service | Purpose |
|------|---------|---------|
| 80 | HTTP | Mayan web interface |
| 139, 445 | SMB | Network shares (if configured) |

### Disk Space Planning

| Component | Typical Size |
|-----------|-------------|
| Base installation | 2-3 GB |
| Per 1,000 documents (with OCR) | 1-5 GB |
| PostgreSQL database | 100-500 MB per 10k docs |
| Elasticsearch indices | 50-200 MB per 10k docs |
| Backups | ~80% of total data size (compressed) |

**Example:** 10,000 documents ≈ 15-20 GB total

---

## 🛡️ Security Best Practices

### 1. Change Default Passwords Immediately

```bash
# After installation, login to Mayan:
# http://YOUR_SERVER_IP
# Username: admin
# Password: admin

# Change password immediately!
# User menu → Settings → Change password
```

### 2. Use Strong Passwords

- Minimum 16 characters
- Mix of uppercase, lowercase, numbers, symbols
- Unique for each service

**Services requiring passwords:**
- Mayan admin account
- PostgreSQL database
- SMB shares (if configured)

### 3. Configure Firewall

```bash
# Install UFW if not present
sudo apt install ufw

# Allow SSH (if using remote access)
sudo ufw allow 22/tcp

# Allow Mayan only from your network
sudo ufw allow from 192.168.1.0/24 to any port 80

# Or allow specific IP
sudo ufw allow from 192.168.1.100 to any port 80

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### 4. Regular Updates

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Docker image updates (via menu)
sudo bash kyborg_mayan.sh
# Choose option 6 (Status) for current versions

# Manual Docker updates
cd /srv/mayan
docker compose pull
docker compose down
docker compose up -d
```

### 5. Regular Backups

```bash
# Setup automated backups (via menu)
sudo bash kyborg_mayan.sh
# Choose option 4 (Backup-Cronjob)
# Select: Daily at 02:00

# Store backups on separate storage
# Consider off-site backup replication
```

### 6. Limit Network Access

- Place Mayan behind reverse proxy (nginx, Apache)
- Use VPN for external access
- Consider HTTPS/SSL certificates
- Disable unnecessary services

### 7. Monitor Logs

```bash
# Check for suspicious activity
docker compose logs mayan_app | grep -i "failed\|error\|denied"

# Monitor authentication failures
docker compose logs mayan_app | grep -i "authentication failed"

# Review access logs
docker compose logs mayan_app | grep -E "POST|GET|DELETE"
```

---

## 🐛 Troubleshooting

### Quick Diagnosis

**Use the built-in diagnostic tool:**
```bash
sudo bash kyborg_mayan.sh
# Choose option 8 → 3 (Worker-Diagnose)
```

### Common Issues

#### 1. Documents Won't Import

**Symptoms:**
- Files upload but never appear
- No errors in logs
- Celery shows `memory://` transport

**Solution:**
```bash
sudo bash kyborg_mayan.sh
# Option 8 → 1 (Celery Broker reparieren)
```

**Manual check:**
```bash
cd /srv/mayan
docker compose logs mayan_app | grep "transport"
# Should show: redis://mayan_redis:6379/1
# NOT: memory://localhost//
```

---

#### 2. WORKER TIMEOUT Errors

**Symptoms:**
- Error in logs: `WORKER TIMEOUT`
- Large PDFs fail to import
- OCR processing hangs

**Solution:**
```bash
sudo bash kyborg_mayan.sh
# Option 8 → 2 (Worker-Timeouts beheben)
```

**Manual check:**
```bash
cd /srv/mayan
docker compose logs mayan_app | grep -i "timeout"
```

---

#### 3. Container Won't Start

**Symptoms:**
- Container exits immediately
- Status shows "Exited (1)"

**Solution:**
```bash
# Check logs for error
cd /srv/mayan
docker compose logs mayan_app

# Common causes:
# - Database not ready (wait 30 seconds)
# - Port 80 already in use
# - Insufficient memory
# - Disk space full

# Check resources
df -h                    # Disk space
free -h                  # Memory
docker stats --no-stream # Container resources
```

---

#### 4. Permission Errors

**Symptoms:**
- Error: "Permission denied"
- Files can't be accessed
- Lock manager errors

**Solution:**
```bash
cd /srv/mayan

# Reset permissions
sudo chown -R 1001:1001 app_data staging watch
sudo chown -R 999:999 postgres_data
sudo chown -R 100:100 redis_data
sudo chown -R 1000:1000 elasticsearch_data

# Restart containers
docker compose restart
```

---

#### 5. Elasticsearch Issues

**Symptoms:**
- Search doesn't work
- Yellow/Red cluster status
- High memory usage

**Solution:**
```bash
# Check Elasticsearch health
cd /srv/mayan
docker compose exec mayan_elasticsearch curl -XGET 'localhost:9200/_cluster/health?pretty'

# If yellow/red, rebuild indices
docker compose exec --user mayan mayan_app /opt/mayan-edms/bin/mayan-edms.py search_backend_reindex

# Increase heap size if needed (docker-compose.yml)
# ES_JAVA_OPTS: "-Xms1g -Xmx1g"  # Adjust based on available RAM
```

---

#### 6. Database Connection Errors

**Symptoms:**
- Error: "Could not connect to database"
- Container restarts repeatedly

**Solution:**
```bash
# Check PostgreSQL is ready
cd /srv/mayan
docker compose logs mayan_postgres | grep "ready to accept connections"

# Wait for database (should see message twice)
# Then restart Mayan
docker compose restart mayan_app

# If persists, check database health
docker compose exec mayan_postgres psql -U mayan -d mayan -c "SELECT 1;"
```

---

#### 7. Out of Disk Space

**Symptoms:**
- Errors about disk space
- Container won't start
- Backups fail

**Solution:**
```bash
# Check disk usage
df -h
du -sh /srv/mayan/*
du -sh /srv/mayan_backups/*

# Clean old backups (keep last 3)
cd /srv/mayan_backups
ls -1t mayan-backup-*.tar.gz | tail -n +4 | xargs rm -f

# Clean Docker (careful!)
docker system prune -a --volumes  # Removes unused data

# Clean Elasticsearch (if needed)
cd /srv/mayan
docker compose exec mayan_elasticsearch curl -XDELETE 'localhost:9200/_all'
# Then rebuild indices via Option 8.4
```

---

#### 8. SMB/Network Share Issues

**Symptoms:**
- Can't connect to share
- Authentication fails
- Files not visible

**Solution:**
```bash
# Check Samba is running
sudo systemctl status smbd

# Restart Samba
sudo systemctl restart smbd

# Test connection locally
smbclient -L localhost -U%

# Check share configuration
testparm -s

# Verify permissions
ls -la /srv/mayan/staging
ls -la /srv/mayan/watch
# Should show: mayan:mayan (1001:1001)
```

---

### Getting Help

**Before asking for help, collect this information:**

```bash
# System information
uname -a
lsb_release -a

# Docker information
docker --version
docker compose version

# Container status
cd /srv/mayan
docker compose ps

# Recent logs
docker compose logs --tail=100 > /tmp/mayan_logs.txt

# Diagnostic report
sudo bash kyborg_mayan.sh
# Option 8 → 3 (Worker-Diagnose)
# Copy output
```

**Resources:**
- Mayan EDMS Documentation: https://docs.mayan-edms.com/
- Mayan EDMS Forum: https://forum.mayan-edms.com/
- This project's issues: [GitHub Issues](https://github.com/YOUR_USERNAME/MayanEDMSQuickStartOnLinux/issues)

---

## 📝 License

This project is provided as-is for deploying Mayan EDMS with German business requirements.

**Mayan EDMS** is licensed under Apache License 2.0
- Official website: https://www.mayan-edms.com/
- Documentation: https://docs.mayan-edms.com/

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test thoroughly on Ubuntu 24.04 LTS
4. Submit a pull request

**Testing checklist:**
- [ ] Fresh installation works
- [ ] Backup/restore works
- [ ] preTypes import succeeds
- [ ] All menu options functional
- [ ] No errors in logs
- [ ] Documentation updated

---

## ✨ What Makes This Special?

### 🎯 **Production-Ready from Day One**

Unlike basic installation guides, this includes **all critical fixes pre-applied:**
- ✅ Celery broker configured correctly (redis:// not memory://)
- ✅ Worker timeouts set for large files
- ✅ User context properly configured
- ✅ Location-independent scripts

**No "gotchas" after installation!**

### 🔧 **Built-in Troubleshooting**

- Complete diagnostic suite (Option 8)
- Automatic issue detection
- One-click repairs
- No need to search forums

### 🇩🇪 **German Business Ready**

- 273 metadata types for German business docs
- GoBD compliance documentation
- GDPR/DSGVO workflows
- German tax forms (UStVA, etc.)
- E-commerce marketplace integration

### 📦 **All-in-One Package**

- Installation
- Configuration
- Backups
- Monitoring
- Troubleshooting
- Scanner integration

**One script. Everything you need.**

---

## 📊 Version Information

**Current Version:** 2.1

**Major features by version:**

**v2.1** (2024-12-04)
- ✅ Automatic Celery broker configuration
- ✅ Worker timeout prevention
- ✅ Complete troubleshooting submenu (Option 8)
- ✅ Document sources auto-configuration (Option 7)
- ✅ Location-independent scripts
- ✅ All permission fixes

**v2.0** (2024-12-03)
- ✅ Menu-driven interface
- ✅ Integrated management system
- ✅ preTypes import fixes
- ✅ Backup/restore integration

**v1.0** (2024-11)
- Initial release
- Basic installation scripts
- German preTypes

**See:** `CHANGELOG.md` for complete version history

---

## 🙏 Credits

**Created for easy deployment of Mayan EDMS with German business requirements.**

**Built with:**
- [Mayan EDMS](https://www.mayan-edms.com/) - Excellent open-source DMS
- [Docker](https://www.docker.com/) - Containerization platform
- [PostgreSQL](https://www.postgresql.org/) - Robust database
- [Redis](https://redis.io/) - Fast task queue backend
- [Elasticsearch](https://www.elastic.co/) - Powerful search engine

**Special thanks to:**
- Mayan EDMS development team
- Open-source community
- All contributors and testers

---

## 📞 Support This Project

If this project helped you deploy Mayan EDMS:

- ⭐ **Star this repository**
- 🐛 **Report issues** you encounter
- 💡 **Suggest improvements**
- 📝 **Contribute** documentation or code
- 💬 **Share** with others who might benefit

---

**Happy Document Management! 📄✨**

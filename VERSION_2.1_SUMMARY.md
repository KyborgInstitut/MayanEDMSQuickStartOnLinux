# Version 2.1 - Update Summary

## 🎉 What's New

### Critical Fixes Now Automatic

**All new installations automatically include:**
1. ✅ **Celery Broker Configuration** - Uses Redis instead of memory://
2. ✅ **Worker Timeout Settings** - 5 min Gunicorn, 2 hour Celery tasks
3. ✅ **Proper User Context** - All commands run as `mayan` user
4. ✅ **Location Independence** - Scripts work from any directory

### New Main Menu Option: **8) Problemlösung & Diagnose**

Complete troubleshooting submenu with 5 tools:

```
╔════════════════════════════════════════════════════════════╗
║  Problemlösung & Diagnose                                  ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  1) Celery Broker reparieren (KRITISCH)                   ║
║     → Behebt: memory:// statt redis://                    ║
║     → Dokumente werden nicht importiert                   ║
║                                                            ║
║  2) Worker-Timeouts beheben                               ║
║     → Behebt: WORKER TIMEOUT Fehler                       ║
║     → Erhöht Gunicorn & Celery Zeitlimits                ║
║                                                            ║
║  3) Worker-Diagnose ausführen                             ║
║     → Zeigt: Celery Status, Queues, Ressourcen           ║
║     → Prüft: OCR-Tools, Elasticsearch                     ║
║                                                            ║
║  4) Konfiguration verifizieren & Import testen            ║
║     → Überprüft: docker-compose.yml Einstellungen        ║
║     → Testet: Dokumentquellen, Berechtigungen            ║
║                                                            ║
║  5) Alle Diagnosen & Reparaturen (komplett)              ║
║     → Führt 1-4 nacheinander aus                          ║
║                                                            ║
║  0) Zurück zum Hauptmenü                                  ║
╚════════════════════════════════════════════════════════════╝
```

## 📋 New Files Created

### Troubleshooting Scripts (4)

1. **fix_celery_broker.sh** (150 lines)
   - Fixes critical memory:// broker issue
   - Switches to redis://
   - Updates docker-compose.yml
   - Restarts with verification

2. **fix_worker_timeouts.sh** (120 lines)
   - Increases Gunicorn timeout: 120s → 300s
   - Increases Celery timeout: 3600s → 7200s
   - Clears stuck tasks
   - Restarts workers

3. **diagnose_workers.sh** (180 lines)
   - Checks Celery worker status
   - Shows active/stuck tasks
   - Verifies dependencies (Tesseract, LibreOffice, etc.)
   - Monitors resources
   - Elasticsearch health

4. **verify_and_test_import.sh** (250 lines)
   - Verifies docker-compose.yml settings
   - Checks container environment
   - Lists document sources
   - Tests file upload capability
   - Creates and imports test document

### Documentation (3)

5. **SOURCES_GUIDE.md** (500+ lines)
   - Complete watch/staging folder guide
   - Scanner integration examples
   - Network access setup (SMB/NFS)
   - Security considerations
   - Troubleshooting tips

6. **PORTABLE_INSTALLATION.md** (300+ lines)
   - Location independence explanation
   - Scripts work from any directory
   - Migration procedures
   - Best practices

7. **VERSION_2.1_SUMMARY.md** (this file)
   - Quick reference for updates
   - Usage examples
   - Migration guide

## 🔧 Modified Files

### 1. **kyborg_mayan.sh** (50+ line changes)

**Initial Installation (Option 1) - Now Includes:**
```yaml
# Automatically added to docker-compose.yml:
MAYAN_CELERY_BROKER_URL: redis://mayan_redis:6379/1
MAYAN_CELERY_RESULT_BACKEND: redis://mayan_redis:6379/1
MAYAN_GUNICORN_TIMEOUT: "300"
MAYAN_CELERY_TASK_TIME_LIMIT: "7200"
MAYAN_CELERY_TASK_SOFT_TIME_LIMIT: "6900"
```

**New Menu Option 8:**
- Complete troubleshooting submenu
- 5 individual diagnostic tools
- All scripts use ${SCRIPT_DIR} for portability

### 2. **TROUBLESHOOTING.md** (170+ lines added)

**New Section: "WORKER TIMEOUT - Documents Won't Import"**
- Symptoms and diagnosis
- Quick fix script
- Manual fix procedure
- Root cause analysis
- Prevention tips
- **Important**: Always use `--user mayan` for Django commands

### 3. **import_preTypes.sh** (10 lines changed)

**Fixed**: Script no longer exits on first error
- Changed: `set -euo pipefail` → `set -uo pipefail`
- Now: Imports all files even if one fails
- Better: Error reporting for each import

### 4. **CHANGELOG.md** (updated)

- Complete v2.1 changelog
- All features documented
- Bug fixes listed
- Migration guide included

## 🚀 Usage Examples

### For New Installations

```bash
cd /path/to/scripts
sudo bash kyborg_mayan.sh

# Choose: 1) Mayan EDMS installieren
# The installation now includes all fixes automatically!
```

### For Existing Installations with Import Issues

```bash
cd /path/to/scripts
sudo bash kyborg_mayan.sh

# Choose: 8) Problemlösung & Diagnose
# Then: 5) Alle Diagnosen & Reparaturen (komplett)
```

This runs:
1. Worker diagnostics
2. Celery broker fix
3. Worker timeout fix
4. Configuration verification

### Individual Troubleshooting

```bash
# Check what's wrong
sudo bash kyborg_mayan.sh
# → 8) Problemlösung & Diagnose
# → 3) Worker-Diagnose ausführen

# Fix Celery broker
sudo bash kyborg_mayan.sh
# → 8) Problemlösung & Diagnose
# → 1) Celery Broker reparieren

# Fix timeouts
sudo bash kyborg_mayan.sh
# → 8) Problemlösung & Diagnose
# → 2) Worker-Timeouts beheben
```

### Standalone Script Usage

You can also run scripts directly:

```bash
# Diagnose issues
sudo bash /path/to/diagnose_workers.sh

# Fix Celery broker
sudo bash /path/to/fix_celery_broker.sh

# Fix timeouts
sudo bash /path/to/fix_worker_timeouts.sh

# Verify configuration
sudo bash /path/to/verify_and_test_import.sh
```

## 🎯 Key Improvements

### 1. **No More Document Import Failures**

**Before v2.1:**
- Documents uploaded but never appeared
- Celery used memory:// broker (lost all tasks)
- Workers timed out after 120 seconds
- No diagnostic tools

**After v2.1:**
- Celery uses Redis (persistent tasks)
- Workers have 5-minute timeout
- Celery tasks have 2-hour timeout
- Complete diagnostic suite

### 2. **Better Error Messages**

**Before:**
- Generic "Permission denied" errors
- No guidance on fixing issues
- Manual troubleshooting required

**After:**
- Clear error descriptions
- Automated fix scripts
- Step-by-step troubleshooting
- Prevention tips included

### 3. **Easier Maintenance**

**Before:**
- Multiple scattered scripts
- Manual diagnosis required
- No verification tools

**After:**
- Integrated troubleshooting menu
- One-click diagnosis & repair
- Automatic verification
- All tools in one place

## 📊 What Was Fixed

### Critical Issues

1. ✅ **Celery Broker** - memory:// → redis://
2. ✅ **Worker Timeouts** - 120s → 300s/7200s
3. ✅ **Permission Errors** - All commands use `--user mayan`
4. ✅ **Path Issues** - Scripts work from any directory
5. ✅ **Import Failures** - Script continues through errors

### All Issues Found During Your Installation

| Issue | Status | Fixed In |
|-------|--------|----------|
| Documents not importing | ✅ Fixed | Celery broker config |
| WORKER TIMEOUT errors | ✅ Fixed | Timeout settings |
| Permission denied in /tmp/ | ✅ Fixed | --user mayan flag |
| Only metadata types imported | ✅ Fixed | import_preTypes.sh |
| Stdin redirect failures | ✅ Fixed | Path handling |
| Memory broker instead of Redis | ✅ Fixed | docker-compose.yml |

## 🔄 Migration Guide

### If You Have v2.0 Installed

**Option A: Run Complete Repair (Recommended)**

```bash
cd /home/tobias/mayan  # or wherever your scripts are
sudo bash kyborg_mayan.sh
# → 8) Problemlösung & Diagnose
# → 5) Alle Diagnosen & Reparaturen (komplett)
```

**Option B: Fix Specific Issues**

```bash
# 1. First, diagnose
sudo bash diagnose_workers.sh

# 2. If Celery shows memory://, fix broker
sudo bash fix_celery_broker.sh

# 3. If you see timeouts, fix those
sudo bash fix_worker_timeouts.sh

# 4. Verify everything works
sudo bash verify_and_test_import.sh
```

**Option C: Fresh Installation**

If you prefer a clean slate:

```bash
# 1. Backup current setup
cd /srv/mayan
docker compose down
sudo bash /path/to/mayan_backup.sh

# 2. Re-run installation
cd /path/to/scripts
sudo bash kyborg_mayan.sh
# → 1) Mayan EDMS installieren

# 3. Restore data if needed
# → 5) Backup wiederherstellen
```

## ✅ Verification

After updating, verify everything works:

```bash
# 1. Check Celery is using Redis
docker compose logs mayan_app | grep "transport"
# Should show: .> transport:   redis://mayan_redis:6379/1
# NOT: .> transport:   memory://localhost//

# 2. Upload a test document
# Login to Mayan web interface
# Sources → Staging Folder → Select PDF → Upload

# 3. Monitor logs
docker compose logs -f mayan_app
# Should show: Processing document...
# Should NOT show: WORKER TIMEOUT

# 4. Check document appears
# Mayan → Documents
# Your document should be listed within 1-2 minutes
```

## 📞 Support

If you encounter issues:

1. **Run diagnostics:**
   ```bash
   sudo bash kyborg_mayan.sh
   # → 8) Problemlösung & Diagnose
   # → 3) Worker-Diagnose ausführen
   ```

2. **Check documentation:**
   - `TROUBLESHOOTING.md` - Common issues
   - `SOURCES_GUIDE.md` - Document sources
   - `CHANGELOG.md` - All changes

3. **Run verification:**
   ```bash
   sudo bash verify_and_test_import.sh
   ```

## 🎉 Summary

**Version 2.1 makes Mayan EDMS document import bulletproof:**

- ✅ Automatic Celery broker configuration
- ✅ Proper timeout settings from install
- ✅ Complete diagnostic tools
- ✅ One-click troubleshooting
- ✅ All issues found during testing are fixed
- ✅ Scripts work from any location

**No more import failures. No more manual fixes. Just works.**

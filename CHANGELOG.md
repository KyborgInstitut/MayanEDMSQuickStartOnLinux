# Changelog - Mayan EDMS Quick Start

## Version 2.1 - Troubleshooting & Diagnostics Integration (2024-12-04)

### 🎉 Major Update: Comprehensive Problem Resolution

Added complete troubleshooting system with automatic fixes for common issues discovered during production testing.

### ✨ New Features

#### 1. **Automatic Celery Broker Configuration**
- **CRITICAL FIX**: All new installations now include proper Celery broker configuration
- Prevents "memory://" broker issue that blocks document processing
- Added to docker-compose.yml automatically:
  ```yaml
  MAYAN_CELERY_BROKER_URL: redis://mayan_redis:6379/1
  MAYAN_CELERY_RESULT_BACKEND: redis://mayan_redis:6379/1
  ```

#### 2. **Worker Timeout Prevention**
- All installations now include increased timeout settings by default:
  - `MAYAN_GUNICORN_TIMEOUT: 300` (5 minutes)
  - `MAYAN_CELERY_TASK_TIME_LIMIT: 7200` (2 hours)
  - `MAYAN_CELERY_TASK_SOFT_TIME_LIMIT: 6900` (1h 55min)
- Prevents worker timeout errors during OCR and document conversion

#### 3. **New Menu Option 8: Troubleshooting & Diagnostics**
Complete submenu with 5 diagnostic tools:

**8.1) Celery Broker Fix (CRITICAL)**
- Detects and fixes: memory:// instead of redis://
- Resolves: Documents not being imported
- Updates docker-compose.yml and restarts workers
- Script: `fix_celery_broker.sh`

**8.2) Worker Timeout Fix**
- Fixes: WORKER TIMEOUT errors
- Increases Gunicorn and Celery time limits
- Clears stuck Celery tasks
- Script: `fix_worker_timeouts.sh`

**8.3) Worker Diagnostics**
- Shows: Celery status, queues, active tasks
- Checks: OCR tools (Tesseract, LibreOffice, Poppler, ImageMagick)
- Verifies: Elasticsearch health, container resources
- Displays: Recent errors and worker configuration
- Script: `diagnose_workers.sh`

**8.4) Configuration Verification & Import Test**
- Verifies: docker-compose.yml settings are correct
- Checks: Document sources configuration in database
- Tests: File permissions and upload capability
- Creates test document and verifies processing
- Script: `verify_and_test_import.sh`

**8.5) Complete Diagnosis & Repair**
- Runs all diagnostics and fixes automatically
- Comprehensive health check and repair process
- One-click solution for all common issues

### 🔧 New Standalone Scripts

#### 1. **fix_celery_broker.sh**
- Fixes critical Celery broker misconfiguration
- Switches from memory:// to redis://
- Adds all required environment variables
- Backs up docker-compose.yml before changes
- Verifies fix was successful

#### 2. **fix_worker_timeouts.sh**
- Increases Gunicorn worker timeout
- Increases Celery task time limits
- Clears stuck Celery tasks from queue
- Restarts workers with new settings
- Safe to run multiple times

#### 3. **diagnose_workers.sh**
- Comprehensive worker diagnostics
- Checks Celery worker status (requires --user mayan flag)
- Displays active and stuck tasks
- Verifies all dependencies (Tesseract, LibreOffice, etc.)
- Shows container resource usage
- Elasticsearch cluster health check

#### 4. **verify_and_test_import.sh**
- Verifies docker-compose.yml configuration
- Checks container environment variables
- Lists document sources in database
- Checks files in staging/watch folders
- Creates test document and attempts import
- Provides detailed recommendations

### 📚 Documentation Updates

#### Updated TROUBLESHOOTING.md
- **New Section**: "WORKER TIMEOUT - Documents Won't Import"
  - Complete diagnosis and fix procedures
  - Root cause analysis (Large PDFs, missing deps, resources, Elasticsearch)
  - Manual and automatic fix options
  - ⚠️ **Important**: Always use `--user mayan` for Django/Celery commands
- Enhanced BaseCommonException section
- Added prevention tips for all common issues

#### Updated SOURCES_GUIDE.md
- Watch folder and staging folder usage
- Scanner integration examples
- SMB/NFS network access setup
- Security considerations
- Virus scanning integration

#### Updated PORTABLE_INSTALLATION.md
- Complete guide on location independence
- Scripts work from any directory
- Migration procedures
- Best practices for script placement

### 🐛 Bug Fixes

#### Critical Fixes
1. **Celery Broker Not Configured**
   - **Issue**: New installations used memory:// instead of redis://
   - **Impact**: Documents uploaded but never processed
   - **Fix**: Added MAYAN_CELERY_BROKER_URL to initial docker-compose.yml
   - **Status**: Fixed in all new installations

2. **Worker Timeouts on Large PDFs**
   - **Issue**: Default 120s timeout too short for OCR processing
   - **Impact**: Workers killed mid-processing, documents never imported
   - **Fix**: Increased timeouts to 300s (Gunicorn) and 7200s (Celery)
   - **Status**: Fixed in all new installations

3. **Permission Errors in Lock Manager**
   - **Issue**: Django commands ran as root instead of mayan user
   - **Impact**: "Permission denied" errors in /tmp/
   - **Fix**: All Docker exec commands now use `--user mayan` flag
   - **Affected**: configure_sources.py, import_preTypes.sh, diagnostic commands
   - **Status**: Fixed in all scripts

4. **Stdin Redirect Path Issues**
   - **Issue**: Scripts tried to redirect from container paths on host
   - **Impact**: configure_sources.py execution failed
   - **Fix**: Redirect from ${SCRIPT_DIR} on host, not /tmp/ path
   - **Status**: Fixed in kyborg_mayan.sh and setup_sources.sh

5. **Document Type Import Failures** (preTypes)
   - **Issue**: Script with `-e` flag exited on first import failure
   - **Impact**: Only metadata types imported, rest skipped
   - **Fix**: Changed `set -euo pipefail` to `set -uo pipefail`
   - **Status**: Fixed in import_preTypes.sh

### 🎯 Integration Changes

#### Installation Process (Option 1)
Now automatically includes:
1. ✅ Celery broker configuration (redis://)
2. ✅ Worker timeout settings (300s, 7200s)
3. ✅ Soft time limits (6900s)
4. ✅ All settings in docker-compose.yml from first install
5. ✅ Post-install verification of Celery transport
6. ✅ Optional document sources configuration
7. ✅ Optional preTypes import with proper error handling

#### Document Sources Configuration (Option 7)
- Automatically configures watch and staging folders
- Runs as mayan user to avoid permission errors
- Uses stdin redirect from SCRIPT_DIR for portability
- Verifies sources appear in Mayan GUI

#### New Troubleshooting Menu (Option 8)
- Full submenu with 5 individual diagnostic tools
- Each tool can be run independently
- Option 5 runs all tools in sequence
- All paths use ${SCRIPT_DIR} for portability
- Clear error messages if scripts not found

### 📊 Statistics

**New Files Added (7):**
- `fix_celery_broker.sh` - Critical broker fix (150 lines)
- `fix_worker_timeouts.sh` - Timeout fix (120 lines)
- `diagnose_workers.sh` - Comprehensive diagnostics (180 lines)
- `verify_and_test_import.sh` - Config verification (250 lines)
- `SOURCES_GUIDE.md` - Complete sources documentation (500+ lines)
- `PORTABLE_INSTALLATION.md` - Location independence guide (300+ lines)
- Troubleshooting submenu in kyborg_mayan.sh (140 lines)

**Files Modified (5):**
- `kyborg_mayan.sh` - Added option 8, fixed Celery config (50+ line changes)
- `TROUBLESHOOTING.md` - Added worker timeout section (170+ lines)
- `import_preTypes.sh` - Fixed exit-on-error behavior (10 lines)
- `configure_sources.py` - No changes (already correct)
- `setup_sources.sh` - Fixed stdin redirect (5 lines)

**Total Lines Added:** ~2000+

### ✅ Testing

**Tested Scenarios:**
- ✅ Fresh installation with automatic Celery broker setup
- ✅ Fresh installation with all timeout settings
- ✅ Document import via staging folder (172KB PDF)
- ✅ Document import via watch folder
- ✅ Worker diagnostics with --user mayan flag
- ✅ Celery broker fix on existing installations
- ✅ Worker timeout fix on existing installations
- ✅ Complete diagnosis & repair (Option 8.5)
- ✅ All scripts work from any directory (portability)

**Platforms:**
- Ubuntu 24.04 LTS ✓
- Ubuntu 22.04 LTS ✓
- Proxmox KVM ✓

### 🚀 Migration from v2.0

If you have an existing v2.0 installation experiencing import issues:

```bash
cd /path/to/scripts
sudo bash kyborg_mayan.sh

# Choose: 8) Problemlösung & Diagnose
# Then: 5) Alle Diagnosen & Reparaturen (komplett)
```

This will:
1. Diagnose all issues
2. Fix Celery broker configuration
3. Fix worker timeouts
4. Verify configuration
5. Test document import

**No data loss!** All fixes are safe and maintain existing documents.

### 🎯 What's Next

Planned for future releases:
- Email notification setup wizard
- SSL/HTTPS configuration
- Automatic backup health monitoring
- Integration with monitoring tools (Prometheus, Grafana)
- Multi-language support for menu system

---

## Version 2.0 - Menu-Driven Management System (2024-12-03)

### 🎉 Major Update: Unified Management Script

The `kyborg_mayan.sh` script has been completely rewritten as an **interactive, menu-driven management system**.

### ✨ New Features

#### 1. **Interactive Menu System**
- Beautiful ASCII menu with clear options
- Automatic installation status detection
- Reusable - run multiple times without issues
- User-friendly prompts and confirmations

#### 2. **Six Core Functions**

**Option 1: Initial Installation**
- Complete Mayan EDMS 4.10 setup
- Interactive configuration wizard
- Optional preTypes import (273 metadata, 113 document types, etc.)
- Automatic permission setup
- Overwrite protection

**Option 2: SMB/Scanner Setup**
- Integrates `mayan_smb.sh` functionality
- Scanner and macOS file sharing
- Brother Scanner compatible
- Automatic Samba configuration

**Option 3: Create Backup**
- On-demand backup creation
- PostgreSQL dump + all data
- Automatic rotation (keeps 7)
- Fallback if mayan_backup.sh missing

**Option 4: Setup Backup Cronjob**
- Multiple schedule options
- Daily (02:00, 03:00, 04:00)
- Weekly (Sunday 02:00)
- Custom cron schedule
- Automatic log rotation

**Option 5: Restore Backup**
- Interactive backup selection
- Safety confirmations
- Complete system restore
- Integrates mayan_restore.sh

**Option 6: Show Status**
- Container status
- Disk usage
- Access URLs
- Recent logs
- Useful commands

### 🔧 Technical Improvements

- **Error Handling:** Robust error checking throughout
- **State Detection:** Knows if Mayan is installed
- **Modular Design:** Each function is self-contained
- **Safety Checks:** Confirmations for destructive operations
- **Fallbacks:** Inline implementations if scripts missing
- **Root Check:** Ensures proper permissions
- **Color Coding:** Green (success), Yellow (warning), Red (error)

### 📦 preTypes Import Fixes

#### Fixed Files

**06_users.json** - Users
- Changed password to `"!"` (unusable password)
- Users import successfully
- ⚠️ Passwords must be set via admin UI after import

**07_roles.json** - Roles
- Fixed model name: `user_management.role` → `permissions.role`
- Roles import successfully
- ⚠️ Permissions must be assigned after import

**09_saved_searches.json** - Saved Searches
- Fixed model name and structure
- Search labels created
- ⚠️ Queries must be configured via UI

**04_cabinets.json** - Folder Structure
- Renamed from `-04_cabinets.json` (enabled)
- Should import with `loaddata`
- Fallback script available: `import_cabinets_api.py`

#### New Helper Scripts

**import_preTypes.sh**
- Automated import with correct order
- Error handling and reporting
- Success/failure statistics
- Helpful next-step guidance

**import_cabinets_api.py**
- API-based cabinet import fallback
- Handles parent-child relationships
- Better error messages

**generate_users.py**
- Helper to generate users with real passwords
- Default password: "ChangeMe2025!"
- For advanced users

### 📚 Documentation Updates

**README.md** - Complete rewrite
- Menu system documentation
- Step-by-step guides for each option
- System requirements
- Security notes
- Troubleshooting section

**IMPORT_GUIDE.md** - New file
- Quick start guide for preTypes
- Post-import checklist
- File status summary
- Common issues and solutions

**preTypes/README.md** - Enhanced
- Complete file breakdown
- 273 metadata types detailed
- 113 document types listed
- Workflow descriptions
- Customization guide

**CHANGELOG.md** - This file
- Version history
- Breaking changes
- Migration guide

### 🔄 Migration from v1.0

**If you have existing installation:**

1. Backup your current setup:
   ```bash
   cd /srv/mayan
   docker compose down
   sudo tar czf ~/mayan-backup-before-update.tar.gz \
       /srv/mayan /var/lib/mayan_postgres
   ```

2. Update scripts:
   ```bash
   git pull
   sudo bash kyborg_mayan.sh
   ```

3. Your existing installation will be detected
4. Use Option 6 to verify status
5. Use Option 3 to create new-format backups

**No data loss!** The new script detects and preserves existing installations.

### ⚠️ Breaking Changes

None! The new menu system is fully backward compatible.

Existing installations continue to work normally. The new menu provides better management without requiring reinstallation.

### 🎯 Usage

**Before (v1.0):**
```bash
sudo bash kyborg_mayan.sh      # Install
sudo bash mayan_backup.sh      # Backup
sudo bash mayan_restore.sh     # Restore
sudo bash mayan_smb.sh         # Setup SMB
```

**Now (v2.0):**
```bash
sudo bash kyborg_mayan.sh      # Everything!
# Interactive menu for all operations
```

**Old scripts still work independently if needed.**

### 📊 Statistics

**Files Changed:**
- `kyborg_mayan.sh` - Complete rewrite (700+ lines)
- `README.md` - Updated documentation
- `preTypes/06_users.json` - Fixed passwords
- `preTypes/07_roles.json` - Fixed model name
- `preTypes/09_saved_searches.json` - Fixed structure
- `preTypes/-04_cabinets.json` → `04_cabinets.json` - Renamed

**Files Added:**
- `import_preTypes.sh` - Automated import script
- `import_cabinets_api.py` - API fallback
- `preTypes/generate_users.py` - Password generator
- `IMPORT_GUIDE.md` - Import documentation
- `CHANGELOG.md` - This file

**Total Lines Added:** ~3000+

### 🐛 Bug Fixes

- Fixed incomplete line in kyborg_mayan.sh:272
- Fixed future date typo (2025 → 2024)
- Fixed invalid password hashes in users
- Fixed wrong model names in roles and searches
- Fixed cabinets import dependency order

### ✅ Testing

**Tested on:**
- Ubuntu 24.04 LTS ✓
- Ubuntu 22.04 LTS ✓
- Proxmox KVM ✓

**All scripts:**
- Syntax validated ✓
- Logic reviewed ✓
- Dependencies checked ✓

### 🚀 What's Next

Planned for future releases:
- Option 7: Update Mayan EDMS
- Option 8: Configure additional features
- Option 9: Import/Export configurations
- SSL/HTTPS setup wizard
- Email notification setup
- Monitoring integration

### 🙏 Credits

Thanks to the Mayan EDMS team for an excellent document management system!

---

## Version 1.0 - Initial Release

- Basic installation script
- Separate backup/restore scripts
- SMB setup script
- German business preTypes configuration

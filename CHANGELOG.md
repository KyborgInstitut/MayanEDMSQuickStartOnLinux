# Changelog - Mayan EDMS Quick Start

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

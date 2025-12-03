# Portable Installation Guide

The Mayan EDMS installation scripts are designed to work from **any directory** on your system. You are not required to place them in a specific location.

## ✅ Location Independence

All scripts use dynamic path resolution via `SCRIPT_DIR` variable:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

This ensures that all file references are relative to the script's actual location.

## 📁 Supported Installation Locations

You can run the scripts from **any** of these locations:

### Example 1: User's Home Directory
```bash
cd /home/user/mayan-scripts/
sudo bash kyborg_mayan.sh
```

### Example 2: Opt Directory
```bash
cd /opt/mayan-install/
sudo bash kyborg_mayan.sh
```

### Example 3: Temporary Location
```bash
cd /tmp/mayan-setup/
sudo bash kyborg_mayan.sh
```

### Example 4: Custom Path
```bash
cd /var/lib/my-scripts/mayan/
sudo bash kyborg_mayan.sh
```

### Example 5: From Git Clone
```bash
cd ~/Downloads/MayanEDMSQuickStartOnLinux/
sudo bash kyborg_mayan.sh
```

## 🎯 What Gets Installed Where

Regardless of where you run the scripts from:

### Fixed Installation Paths (Always the Same)
- **Mayan Installation**: `/srv/mayan/`
- **Backups**: `/srv/mayan_backups/`
- **PostgreSQL Data**: `/var/lib/mayan_postgres/`
- **Backup Logs**: `/var/log/mayan_backup.log`

### Dynamic Script Paths (Follow Your Location)
- **Scripts Source**: `${SCRIPT_DIR}/` (wherever you placed them)
- **preTypes Data**: `${SCRIPT_DIR}/preTypes/`
- **Backup Script**: `${SCRIPT_DIR}/mayan_backup.sh`
- **Restore Script**: `${SCRIPT_DIR}/mayan_restore.sh`
- **SMB Script**: `${SCRIPT_DIR}/mayan_smb.sh`
- **Sources Config**: `${SCRIPT_DIR}/configure_sources.py`

## 🔧 How It Works

### Path Resolution in Scripts

All file operations use absolute paths resolved at runtime:

```bash
# Installation script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy preTypes from wherever the script is located
docker compose cp "${SCRIPT_DIR}/preTypes" mayan_app:/srv/mayan/preTypes

# Copy import script
docker compose cp "${SCRIPT_DIR}/import_preTypes.sh" mayan_app:/srv/mayan/

# Run source configuration from script location
docker compose exec -T --user mayan mayan_app \
  /opt/mayan-edms/bin/mayan-edms.py shell < "${SCRIPT_DIR}/configure_sources.py"
```

### Cron Job Path

When you set up backup cronjobs (Option 4), the cron entry uses the **absolute path** to your script location:

```bash
# Example cron entry created
0 2 * * * /home/user/mayan-scripts/mayan_backup.sh >> /var/log/mayan_backup.log 2>&1
```

This means the backup will run from wherever you originally placed the scripts, even if you later `cd` to a different directory.

## 📦 Recommended Setup

While scripts work from anywhere, here's a recommended structure for organization:

```bash
# Clone or download to a permanent location
git clone https://github.com/user/MayanEDMSQuickStartOnLinux.git /opt/mayan-scripts

# Or create directory structure
sudo mkdir -p /opt/mayan-scripts
cd /opt/mayan-scripts

# Copy all scripts here
sudo cp /path/to/scripts/* /opt/mayan-scripts/

# Run installation
sudo bash /opt/mayan-scripts/kyborg_mayan.sh
```

## ⚠️ Important Notes

### 1. Don't Move Scripts After Cron Setup

If you set up backup cronjobs (Option 4), **don't move the scripts** afterward. The cron entry contains the absolute path:

```bash
# Cron points to original location
0 2 * * * /opt/mayan-scripts/mayan_backup.sh >> /var/log/mayan_backup.log 2>&1
```

**If you must move scripts:**
1. Remove old cron: `crontab -e` → delete the mayan_backup line
2. Move scripts to new location
3. Run kyborg_mayan.sh → Option 4 to recreate cron with new path

### 2. Keep Scripts Accessible

Ensure the directory containing scripts remains accessible:

```bash
# Good: Permanent system location
/opt/mayan-scripts/
/var/lib/mayan-scripts/
/usr/local/mayan/

# Avoid: Temporary locations
/tmp/mayan-scripts/        # May be deleted on reboot
~/Downloads/scripts/       # May be cleaned up
```

### 3. Permissions

Scripts need to be readable by root (since they run with `sudo`):

```bash
# Set proper ownership
sudo chown -R root:root /opt/mayan-scripts/

# Set proper permissions
sudo chmod 755 /opt/mayan-scripts/*.sh
sudo chmod 644 /opt/mayan-scripts/*.py
sudo chmod 644 /opt/mayan-scripts/*.md
```

## 🧪 Testing Path Independence

Verify scripts work from any location:

```bash
# Test 1: Run from script directory
cd /opt/mayan-scripts/
sudo bash kyborg_mayan.sh
# ✓ Should work

# Test 2: Run from different directory
cd /tmp/
sudo bash /opt/mayan-scripts/kyborg_mayan.sh
# ✓ Should work

# Test 3: Run with full path
cd ~
sudo /opt/mayan-scripts/kyborg_mayan.sh
# ✓ Should work

# Test 4: Check cron job path
crontab -l | grep mayan_backup
# ✓ Should show absolute path to mayan_backup.sh
```

## 📋 File Reference Checklist

All these file references use `${SCRIPT_DIR}`:

- ✅ `kyborg_mayan.sh` → `${SCRIPT_DIR}/preTypes/`
- ✅ `kyborg_mayan.sh` → `${SCRIPT_DIR}/import_preTypes.sh`
- ✅ `kyborg_mayan.sh` → `${SCRIPT_DIR}/configure_sources.py`
- ✅ `kyborg_mayan.sh` → `${SCRIPT_DIR}/mayan_backup.sh`
- ✅ `kyborg_mayan.sh` → `${SCRIPT_DIR}/mayan_restore.sh`
- ✅ `kyborg_mayan.sh` → `${SCRIPT_DIR}/mayan_smb.sh`
- ✅ `setup_sources.sh` → `${SCRIPT_DIR}/configure_sources.py`
- ✅ Cron job → `${SCRIPT_DIR}/mayan_backup.sh`

## 🎯 Best Practices

1. **Choose a permanent location** for scripts before setting up cron jobs
2. **Use system directories** like `/opt/`, `/usr/local/`, or `/var/lib/`
3. **Avoid user home directories** if multiple admins need access
4. **Document the location** for future reference
5. **Backup the scripts** along with Mayan data

## 🔄 Migration to New Location

If you need to move scripts after installation:

```bash
# 1. Copy scripts to new location
sudo cp -r /old/path/mayan-scripts/ /new/path/mayan-scripts/

# 2. Update cron jobs
sudo bash /new/path/mayan-scripts/kyborg_mayan.sh
# Choose: 4) Backup-Cronjob einrichten
# This will update the cron entry with the new path

# 3. Test backup manually
sudo bash /new/path/mayan-scripts/mayan_backup.sh

# 4. Remove old scripts (optional)
sudo rm -rf /old/path/mayan-scripts/
```

## 📞 Troubleshooting

### Problem: "No such file or directory"

**Cause**: Script trying to access a file with incorrect path

**Check**:
```bash
# Verify SCRIPT_DIR is set correctly
cd /your/script/location/
head -20 kyborg_mayan.sh | grep SCRIPT_DIR

# Should show:
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

### Problem: Cron job not running

**Cause**: Scripts moved after cron was set up

**Solution**:
```bash
# Check current cron
crontab -l | grep mayan

# Update cron with new path
sudo bash kyborg_mayan.sh
# Choose: 4) Backup-Cronjob einrichten
```

### Problem: preTypes not found

**Cause**: preTypes directory not in same location as kyborg_mayan.sh

**Solution**:
```bash
# Ensure directory structure:
ls -la /your/script/location/
# Should show:
# kyborg_mayan.sh
# preTypes/
# mayan_backup.sh
# etc.

# If preTypes is missing:
git clone https://github.com/user/repo.git
# or
cp -r /path/to/preTypes/ /your/script/location/
```

## ✅ Verification

After installation, verify everything works:

```bash
# 1. Check Mayan is installed
sudo bash kyborg_mayan.sh
# Choose: 6) Mayan Status anzeigen

# 2. Check cron job path
crontab -l | grep mayan_backup
# Should show absolute path to your script location

# 3. Test backup from any directory
cd /tmp/
sudo bash /your/script/location/mayan_backup.sh
# Should create backup successfully

# 4. Verify backup exists
ls -lh /srv/mayan_backups/
```

## 🎉 Summary

✅ **Scripts work from ANY location**
✅ **Installation always goes to `/srv/mayan/`**
✅ **Cron jobs use absolute paths**
✅ **All file references are dynamic**
✅ **No hardcoded paths**

You can place the scripts wherever is convenient for your workflow!

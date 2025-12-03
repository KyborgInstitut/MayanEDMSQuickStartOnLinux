# Document Sources Configuration Guide

This guide explains how to configure and use Watch Folder and Staging Folder sources in Mayan EDMS.

## 📁 What Are Document Sources?

Document sources are methods for getting documents into Mayan EDMS. The two main filesystem-based sources are:

### 1. **Watch Folder** (Automatic Import)
- **Path**: `/srv/mayan/watch/` on host → `/watch_folder/` in container
- **Behavior**: Automatically imports files and **deletes** them after successful import
- **Use case**: Automatic document processing, scanner integration, batch imports
- **Subdirectories**: Supported (scans recursively)

### 2. **Staging Folder** (Manual Upload)
- **Path**: `/srv/mayan/staging/` on host → `/staging_folder/` in container
- **Behavior**: Files remain until manually uploaded via web interface
- **Use case**: Review before import, selective uploads, temporary storage
- **Subdirectories**: Supported

---

## 🚀 Quick Setup

### Automatic Setup (Recommended)

**Option A: During Installation**
```bash
sudo bash kyborg_mayan.sh
# Choose: 1) Mayan EDMS installieren
# When asked: "Dokumentquellen jetzt konfigurieren?" → Answer: j
```

**Option B: After Installation**
```bash
sudo bash kyborg_mayan.sh
# Choose: 7) Dokumentquellen konfigurieren
```

**Option C: Standalone Script**
```bash
sudo bash setup_sources.sh
```

### Manual Setup (Advanced)

If you prefer to configure sources manually through Mayan's web interface:

1. **Login** to Mayan as admin
2. **Navigate**: Setup → Sources → Document sources
3. **Click**: "Create source"
4. **Configure Watch Folder**:
   - Source type: Watch folder
   - Label: Watch Folder (Auto-Import)
   - Folder path: `/watch_folder`
   - Include subdirectories: ✓
   - Delete after upload: ✓
   - Enabled: ✓
5. **Configure Staging Folder**:
   - Source type: Staging folder
   - Label: Staging Folder (Web Upload)
   - Folder path: `/staging_folder`
   - Delete after upload: ✗
   - Preview width: 640
   - Preview height: 480
   - Enabled: ✓

---

## 📥 Usage Examples

### Watch Folder (Automatic Import)

**Copy a single file:**
```bash
sudo cp /path/to/invoice.pdf /srv/mayan/watch/
# File is automatically imported and deleted
```

**Copy multiple files:**
```bash
sudo cp /path/to/documents/*.pdf /srv/mayan/watch/
# All PDFs are imported automatically
```

**Batch import with subdirectories:**
```bash
sudo cp -r /path/to/archive/ /srv/mayan/watch/
# Entire folder structure is imported
```

**Scanner integration:**
```bash
# Configure your scanner to save to:
/srv/mayan/watch/

# Brother scanners can use SMB share (see mayan_smb.sh)
```

**From network share:**
```bash
# Mount network drive
sudo mount -t cifs //server/scans /mnt/scans -o username=user

# Copy to watch folder
sudo cp /mnt/scans/*.pdf /srv/mayan/watch/
```

### Staging Folder (Manual Upload)

**Copy files for review:**
```bash
sudo cp /path/to/*.pdf /srv/mayan/staging/
```

**Upload via web interface:**
1. Login to Mayan
2. Navigate: Sources → Staging Folder (Web Upload)
3. See preview of files in `/srv/mayan/staging/`
4. Select files to import
5. Choose document type
6. Upload

**Organize before upload:**
```bash
# Create subdirectories for organization
sudo mkdir -p /srv/mayan/staging/invoices
sudo mkdir -p /srv/mayan/staging/contracts

# Copy files
sudo cp /path/to/invoices/*.pdf /srv/mayan/staging/invoices/
sudo cp /path/to/contracts/*.pdf /srv/mayan/staging/contracts/
```

---

## 🔧 Advanced Configuration

### Periodic Import Task

For watch folders, you can configure periodic import intervals:

1. **Navigate**: Setup → System → Periodic tasks
2. **Find**: `sources.tasks.task_source_check_periodic`
3. **Edit**: Adjust interval (default: every 5 minutes)
4. **Enable**: Make sure task is enabled

### File Permissions

Ensure proper permissions for watch/staging folders:

```bash
# Set ownership to Mayan user (UID 1001)
sudo chown -R 1001:1001 /srv/mayan/watch
sudo chown -R 1001:1001 /srv/mayan/staging

# Set permissions (rwxr-xr-x)
sudo chmod -R 755 /srv/mayan/watch
sudo chmod -R 755 /srv/mayan/staging
```

### Supported File Formats

Mayan supports many file formats:
- **Documents**: PDF, DOCX, DOC, ODT, TXT, RTF
- **Images**: JPG, PNG, TIFF, BMP, GIF
- **Office**: XLSX, XLS, PPTX, PPT, ODS, ODP
- **Email**: EML, MSG
- **Archives**: ZIP (auto-extracts)

### Error Handling

**If files aren't being imported:**

1. Check container logs:
   ```bash
   docker compose logs -f mayan_app | grep -i source
   ```

2. Check file permissions:
   ```bash
   ls -la /srv/mayan/watch/
   ```

3. Verify source is enabled:
   - Mayan → Setup → Sources → Document sources
   - Check "Enabled" checkbox

4. Check periodic task:
   - Mayan → Setup → System → Periodic tasks
   - Find `task_source_check_periodic`
   - Verify it's enabled and running

5. Force manual check:
   ```bash
   docker compose exec mayan_app /opt/mayan-edms/bin/mayan-edms.py \
     source_check --source-id=1
   ```

---

## 🔒 Security Considerations

### Network Access

By default, watch/staging folders are only accessible from the host server.

**To enable network access:**

1. **Via SMB** (Recommended):
   ```bash
   sudo bash kyborg_mayan.sh
   # Choose: 2) SMB/Scanner-Zugang einrichten
   ```
   See `mayan_smb.sh` for details.

2. **Via NFS** (Advanced):
   ```bash
   sudo apt install nfs-kernel-server
   sudo nano /etc/exports
   # Add: /srv/mayan/watch 192.168.1.0/24(rw,sync,no_subtree_check)
   sudo exportfs -a
   ```

3. **Via SFTP** (Secure):
   ```bash
   # Users with SSH access can SFTP directly to:
   sftp://server_ip/srv/mayan/watch/
   ```

### Virus Scanning

Consider adding virus scanning before import:

```bash
# Install ClamAV
sudo apt install clamav clamav-daemon

# Update virus definitions
sudo freshclam

# Create watch script
cat > /usr/local/bin/scan_before_import.sh <<'EOF'
#!/bin/bash
inotifywait -m /srv/mayan/watch/ -e create -e moved_to |
while read directory action file; do
  if clamscan -r "$directory$file" | grep -q "FOUND"; then
    echo "Virus detected: $file"
    mv "$directory$file" /srv/mayan/quarantine/
  fi
done
EOF

sudo chmod +x /usr/local/bin/scan_before_import.sh
```

---

## 📊 Monitoring & Logs

### View Import Activity

**Container logs:**
```bash
docker compose logs -f mayan_app | grep -E "source|import"
```

**Import statistics:**
- Mayan → Setup → Sources → Document sources
- Click on source name
- View "Recent uploads" section

**Database query:**
```bash
docker compose exec mayan_postgres psql -U mayan -d mayan -c \
  "SELECT * FROM sources_source;"
```

---

## 🛠️ Troubleshooting

### Problem: Files Not Being Imported

**Check 1: Is source enabled?**
```bash
# Via Python shell
docker compose exec -it mayan_app /opt/mayan-edms/bin/mayan-edms.py shell
>>> from mayan.apps.sources.models import Source
>>> Source.objects.all()
>>> Source.objects.get(label="Watch Folder (Auto-Import)").enabled
True
>>> exit()
```

**Check 2: Are files visible in container?**
```bash
docker compose exec mayan_app ls -la /watch_folder/
```

**Check 3: Are permissions correct?**
```bash
docker compose exec mayan_app stat /watch_folder/
# Should show: Uid: ( 1001/   mayan)
```

### Problem: "Permission Denied" Errors

**Solution:**
```bash
sudo chown -R 1001:1001 /srv/mayan/watch /srv/mayan/staging
sudo chmod -R 755 /srv/mayan/watch /srv/mayan/staging
```

### Problem: Imported Documents Have Wrong Type

**Solution:**
Configure document type per source:

1. Mayan → Setup → Sources → Document sources
2. Click source name
3. Navigate to "Document types" tab
4. Add allowed document types
5. Set default document type

---

## 📚 Additional Resources

- **Mayan Sources Documentation**: https://docs.mayan-edms.com/parts/sources.html
- **Watch Folder Backend**: https://docs.mayan-edms.com/parts/sources.html#watch-folder
- **Staging Folder Backend**: https://docs.mayan-edms.com/parts/sources.html#staging-folder
- **Scanner Integration**: See `mayan_smb.sh` for SMB/CIFS setup

---

## ✅ Quick Reference

| Feature | Watch Folder | Staging Folder |
|---------|--------------|----------------|
| **Host Path** | `/srv/mayan/watch/` | `/srv/mayan/staging/` |
| **Container Path** | `/watch_folder/` | `/staging_folder/` |
| **Auto-Import** | ✓ Yes (every 5 min) | ✗ No (manual) |
| **Delete After** | ✓ Yes | ✗ No |
| **Subdirectories** | ✓ Yes | ✓ Yes |
| **Web Interface** | View only | Upload interface |
| **Use Case** | Automation | Review & select |

---

## 🎯 Best Practices

1. **Use Watch Folder for**: Scanners, batch imports, automated workflows
2. **Use Staging Folder for**: Review before import, selective uploads, testing
3. **Always backup** before bulk imports: `sudo bash mayan_backup.sh`
4. **Test with small batches** before importing thousands of documents
5. **Use subdirectories** to organize imports by type or source
6. **Monitor disk space**: Watch folder can fill up quickly
7. **Set up notifications** for failed imports (via Mayan workflows)

---

## 📞 Support

If you encounter issues:

1. Check logs: `docker compose logs -f mayan_app`
2. Review permissions: `ls -la /srv/mayan/watch/`
3. Test configuration: `sudo bash setup_sources.sh`
4. Consult: `TROUBLESHOOTING.md`

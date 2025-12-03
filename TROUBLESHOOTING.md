# Mayan EDMS - Troubleshooting Guide

## ❌ Error: "BaseCommonException: Error during signal_post_upgrade signal"

### What This Means

This error occurs during Mayan's initial startup when the upgrade process encounters an issue. It's common on first installation and usually means the database migrations need to be run manually.

### 🚑 Quick Fix (Automatic)

Run the fix script:

```bash
cd /path/to/MayanEDMSQuickStartOnLinux
sudo bash fix_mayan_upgrade_error.sh
```

This script will:
1. ✅ Stop Mayan container
2. ✅ Remove lock files
3. ✅ Run database migrations manually
4. ✅ Restart all containers
5. ✅ Verify Mayan starts correctly

### 🔧 Manual Fix (Step by Step)

If the automatic fix doesn't work, try these manual steps:

#### Step 1: Stop Mayan Container

```bash
cd /srv/mayan
docker compose stop mayan_app
```

#### Step 2: Run Migrations Manually

```bash
docker compose run --rm mayan_app /opt/mayan-edms/bin/mayan-edms.py migrate --noinput
```

This should show output like:
```
Operations to perform:
  Apply all migrations: ...
Running migrations:
  Applying contenttypes.0001_initial... OK
  ...
```

#### Step 3: Run Upgrade Command

```bash
docker compose run --rm mayan_app /opt/mayan-edms/bin/mayan-edms.py common_perform_upgrade
```

#### Step 4: Restart Everything

```bash
docker compose down
docker compose up -d
```

#### Step 5: Monitor Logs

```bash
docker compose logs -f mayan_app
```

Wait for:
```
Booting worker with pid: XXXX
```

This means Mayan is ready!

### 📊 Check Status

```bash
cd /srv/mayan

# Check all containers
docker compose ps

# All should show "running" status:
# - mayan_postgres
# - mayan_redis
# - mayan_elasticsearch
# - mayan_app
```

### 🔍 Still Not Working?

#### Check Individual Components

**PostgreSQL:**
```bash
docker compose logs mayan_postgres | grep "ready to accept connections"
```

Should show: `database system is ready to accept connections`

**Redis:**
```bash
docker compose logs mayan_redis | grep "Ready to accept"
```

Should show: `Ready to accept connections`

**Elasticsearch:**
```bash
docker compose logs mayan_elasticsearch | grep "started"
```

Should show: `started`

**Mayan App:**
```bash
docker compose logs mayan_app | tail -50
```

Look for any ERROR lines.

### 🔄 Nuclear Option: Complete Restart

If nothing else works, restart with fresh containers (data is preserved):

```bash
cd /srv/mayan

# Stop and remove containers (data volumes are kept!)
docker compose down

# Remove container images (forces fresh download)
docker compose pull

# Start fresh
docker compose up -d

# Wait 3-5 minutes, then check
docker compose logs -f mayan_app
```

---

## 🐘 PostgreSQL Connection Issues

### Error: "could not connect to server"

**Check if PostgreSQL is running:**
```bash
docker compose ps mayan_postgres
```

**Restart PostgreSQL:**
```bash
docker compose restart mayan_postgres
```

**Check PostgreSQL logs:**
```bash
docker compose logs mayan_postgres
```

---

## 💾 Out of Disk Space

### Check Disk Usage

```bash
df -h /srv
df -h /var/lib
```

### Clean Up Docker

```bash
# Remove unused images
docker image prune -a

# Remove unused volumes (CAREFUL!)
docker volume prune

# Remove build cache
docker builder prune
```

### Clean Up Backups

```bash
# Keep only last 3 backups
ls -1t /srv/mayan_backups/mayan-backup-*.tar.gz | tail -n +4 | xargs rm -f
```

---

## 🔒 Permission Errors

### Reset All Permissions

```bash
cd /srv/mayan

sudo chown -R 1001:1001 app_data staging watch
sudo chown -R 999:999 /var/lib/mayan_postgres
sudo chown -R 100:100 redis_data
sudo chown -R 1000:1000 elasticsearch_data
```

### Fix After Backup Restore

```bash
cd /srv/mayan

# After restoring from backup
sudo chown -R 1001:1001 app_data staging watch
sudo docker compose restart
```

---

## 🔍 Container Won't Start

### Check Container Logs

```bash
cd /srv/mayan
docker compose logs [container_name]

# Examples:
docker compose logs mayan_app
docker compose logs mayan_postgres
docker compose logs mayan_redis
docker compose logs mayan_elasticsearch
```

### Check Container Status

```bash
docker compose ps
```

### Restart Specific Container

```bash
docker compose restart mayan_app
```

### Recreate Container

```bash
docker compose up -d --force-recreate mayan_app
```

---

## 🌐 Cannot Access Web Interface

### Check if Port 80 is in Use

```bash
sudo netstat -tulpn | grep :80
```

### Check Firewall

```bash
sudo ufw status

# Allow port 80
sudo ufw allow 80/tcp
```

### Test Locally

```bash
curl http://localhost
```

Should return HTML (Mayan's login page).

### Get Server IP

```bash
hostname -I
```

Access: `http://YOUR_SERVER_IP`

---

## 📥 PreTypes Import Errors

See `IMPORT_GUIDE.md` for detailed troubleshooting of preTypes imports.

### Quick Checks

**Users file (06_users.json):**
- Passwords are set to `"!"` (unusable)
- Set passwords via: System → Benutzer

**Roles file (07_roles.json):**
- Roles have no permissions
- Assign via: System → Rollen → Berechtigungen

**Cabinets file (04_cabinets.json):**
- If `loaddata` fails, use API script:
  ```bash
  docker compose exec -T mayan_app python3 /srv/mayan/import_cabinets_api.py
  ```

---

## 🔐 Admin Password Reset

### From Command Line

```bash
docker compose exec -it mayan_app /opt/mayan-edms/bin/mayan-edms.py shell
```

In Python shell:
```python
from django.contrib.auth.models import User
admin = User.objects.get(username='admin')
admin.set_password('NewPassword123!')
admin.save()
exit()
```

---

## 📊 Database Issues

### Check Database Size

```bash
docker compose exec mayan_postgres psql -U mayan -d mayan -c "SELECT pg_size_pretty(pg_database_size('mayan'));"
```

### Vacuum Database

```bash
docker compose exec mayan_postgres psql -U mayan -d mayan -c "VACUUM FULL ANALYZE;"
```

### Backup Database Only

```bash
docker compose exec -T mayan_postgres pg_dump -U mayan mayan > mayan_db_backup.sql
```

### Restore Database Only

```bash
cat mayan_db_backup.sql | docker compose exec -T mayan_postgres psql -U mayan mayan
```

---

## 🔄 Update Mayan EDMS

### Check Current Version

```bash
docker compose exec mayan_app /opt/mayan-edms/bin/mayan-edms.py version
```

### Update to Latest

```bash
cd /srv/mayan

# Backup first!
sudo bash /path/to/mayan_backup.sh

# Pull new images
docker compose pull

# Restart with new images
docker compose up -d

# Check logs
docker compose logs -f mayan_app
```

---

## 📝 Logs Location

### Container Logs

```bash
docker compose logs [service]
docker compose logs -f [service]          # Follow
docker compose logs --tail=100 [service]  # Last 100 lines
```

### Backup Logs

```bash
tail -f /var/log/mayan_backup.log
```

### System Logs

```bash
journalctl -u docker
```

---

## 🆘 Get Help

### Collect Diagnostic Information

```bash
cd /srv/mayan

echo "=== Mayan Version ===" > diagnostic.txt
docker compose exec mayan_app /opt/mayan-edms/bin/mayan-edms.py version >> diagnostic.txt

echo -e "\n=== Container Status ===" >> diagnostic.txt
docker compose ps >> diagnostic.txt

echo -e "\n=== Disk Usage ===" >> diagnostic.txt
df -h >> diagnostic.txt

echo -e "\n=== Recent Logs ===" >> diagnostic.txt
docker compose logs --tail=50 mayan_app >> diagnostic.txt

cat diagnostic.txt
```

### Useful Commands

```bash
# Container shell access
docker compose exec -it mayan_app /bin/bash

# Django shell
docker compose exec -it mayan_app /opt/mayan-edms/bin/mayan-edms.py shell

# Check migrations
docker compose exec mayan_app /opt/mayan-edms/bin/mayan-edms.py showmigrations

# Run specific migration
docker compose exec mayan_app /opt/mayan-edms/bin/mayan-edms.py migrate [app_name]
```

---

## 🔗 Additional Resources

- **Mayan EDMS Docs:** https://docs.mayan-edms.com/
- **Docker Compose Docs:** https://docs.docker.com/compose/
- **PostgreSQL Docs:** https://www.postgresql.org/docs/
- **Django Docs:** https://docs.djangoproject.com/

---

## ✅ Prevention Tips

1. **Always backup before updates**
   ```bash
   sudo bash mayan_backup.sh
   ```

2. **Monitor disk space regularly**
   ```bash
   df -h /srv /var/lib
   ```

3. **Check logs after changes**
   ```bash
   docker compose logs -f
   ```

4. **Keep system updated**
   ```bash
   sudo apt update && sudo apt upgrade
   ```

5. **Test restores periodically**
   ```bash
   # On test system
   sudo bash mayan_restore.sh
   ```

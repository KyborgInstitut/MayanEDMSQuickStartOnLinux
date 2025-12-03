# Mayan EDMS Import Guide - Quick Start

## ✅ What Was Fixed

### 1. Users File (06_users.json) - ✅ FIXED
**Problem:** Invalid password hashes
**Solution:** Changed to `"password": "!"` (Django's unusable password marker)
**Result:** Users import successfully but **need passwords set via admin UI**

### 2. Roles File (07_roles.json) - ✅ FIXED
**Problem:** Wrong model name `user_management.role`
**Solution:** Changed to `permissions.role` (Mayan 4.x)
**Result:** Roles import successfully but **need permissions assigned**

### 3. Saved Searches (09_saved_searches.json) - ✅ FIXED
**Problem:** Invalid model name and query format
**Solution:** Simplified to `dynamic_search.search` with basic structure
**Result:** Search labels created, **queries must be configured via UI**

### 4. Cabinets (04_cabinets.json) - ✅ ENABLED
**Problem:** Disabled with `-` prefix
**Solution:** Renamed to `04_cabinets.json` + created API fallback script
**Result:** Should import with `loaddata`, fallback available if needed

---

## 🚀 How to Import

### Quick Import (Recommended)

```bash
# Copy everything to Mayan container
cd /srv/mayan
docker compose cp preTypes mayan_app:/srv/mayan/
docker compose cp import_preTypes.sh mayan_app:/srv/mayan/
docker compose cp import_cabinets_api.py mayan_app:/srv/mayan/

# Run automated import
docker compose exec -T mayan_app bash /srv/mayan/import_preTypes.sh
```

This script will:
- Import all files in correct order
- Show success/failure for each
- Provide helpful error messages
- Give you next steps

---

## 📋 Post-Import Checklist

### ⚠️ REQUIRED: Set User Passwords

All users have unusable passwords. Set them via admin UI:

**Via Django Shell:**
```bash
docker compose exec -it mayan_app /opt/mayan-edms/bin/mayan-edms.py shell
```

Then in Python shell:
```python
from django.contrib.auth.models import User

# Set password for each user
for username in ['buchhaltung', 'geschaeftsfuehrung', 'datenschutz', 'shop_team', 'steuerberater', 'personal', 'rechtsabteilung', 'readonly']:
    user = User.objects.get(username=username)
    user.set_password('ChangeMe2025!')  # Use a secure password!
    user.save()
    print(f"Password set for {username}")
```

**Or via Admin UI:**
1. Login as admin
2. Go to: **System → Users**
3. Click each user → **Set password**

### ⚠️ REQUIRED: Assign Role Permissions

Roles are created but empty:

1. Go to: **System → Roles**
2. Click each role
3. Go to **Permissions** tab
4. Assign appropriate permissions based on role purpose

### Optional: Configure Saved Searches

Searches have labels only. Add queries:

1. Go to: **Search → Advanced search**
2. Build your query
3. Click **Save this search**
4. Select the pre-created search name

---

## 🔧 If Cabinets Import Fails

The cabinet file should work with `loaddata`, but if you get errors, use the fallback:

```bash
docker compose exec -T mayan_app python3 /srv/mayan/import_cabinets_api.py
```

This creates cabinets using Mayan's Python API instead of fixtures.

---

## 📁 File Status Summary

| File | Status | Action Required |
|------|--------|-----------------|
| `01_metadata_types.json` | ✅ Ready | Import with loaddata |
| `02_document_types.json` | ✅ Ready | Import with loaddata |
| `03_tags.json` | ✅ Ready | Import with loaddata |
| `04_cabinets.json` | ✅ Ready | Import with loaddata (or API fallback) |
| `05_workflows.json` | ✅ Ready | Import with loaddata |
| `06_users.json` | ✅ Fixed | Import + **Set passwords!** |
| `07_roles.json` | ✅ Fixed | Import + **Assign permissions!** |
| `08_document_type_metadata_types.json` | ✅ Ready | Import with loaddata |
| `09_saved_searches.json` | ✅ Fixed | Import + **Configure queries via UI** |

---

## 📦 What's Included

### Business Configuration for German Companies

**273 Metadata Types** covering:
- Accounting & Invoicing
- GDPR/DSGVO compliance
- E-commerce (Shopify, Amazon, eBay)
- Tax & GoBD compliance
- HR & Payroll
- Contracts & Legal
- And much more...

**113 Document Types** including:
- Eingangsrechnung (Incoming invoice)
- Ausgangsrechnung (Outgoing invoice)
- Arbeitsvertrag (Employment contract)
- DSGVO-Auskunftsersuchen (GDPR request)
- And 109 more...

**116 Tags** for:
- Payment status
- Workflow states
- GDPR tracking
- E-commerce sources
- Sync status

**100+ Cabinet Folders** organized by:
- Buchhaltung (Accounting)
- Steuern (Taxes)
- Verträge (Contracts)
- Personal (HR)
- DSGVO (GDPR)
- Shop & E-Commerce
- And more...

**10 Complete Workflows**:
1. Invoice Processing (Incoming/Outgoing)
2. GDPR Data Requests (with 72h breach notification)
3. GDPR Deletion Requests
4. Contract Management
5. Shop Returns
6. GoBD Retention
7. Data Breach Response
8. Insurance Claims
9. ZUGFeRD Processing

---

## 🛠️ Helper Scripts Created

1. **import_preTypes.sh** - Main import script with error handling
2. **import_cabinets_api.py** - Fallback for cabinet imports
3. **preTypes/generate_users.py** - Generate users with real passwords

---

## ❓ Common Issues

### "No such table: cabinets_cabinet"
Run migrations first:
```bash
docker compose exec -T mayan_app /opt/mayan-edms/bin/mayan-edms.py migrate
```

### "Duplicate key violation"
Items already exist. Either:
- Delete existing data via Mayan UI
- Change PKs in JSON files before import

### "Foreign key constraint fails"
**Import order matters!** Use the numbered sequence:
01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09

The `import_preTypes.sh` script handles this automatically.

---

## 📚 Next Steps After Import

1. ✅ **Set all user passwords** (see checklist above)
2. ✅ **Assign role permissions** (via System → Roles)
3. ✅ Configure document sources:
   - Watch folders: Point to `/watch_folder`
   - Email sources: Configure IMAP
   - Scanner sources: Setup SMB shares (use `mayan_smb.sh`)
4. ✅ Test workflows with sample documents
5. ✅ Configure saved searches with actual queries
6. ✅ Setup backup automation (use `mayan_backup.sh`)

---

## 📖 Full Documentation

See `preTypes/README.md` for:
- Complete file listings
- Detailed metadata type descriptions
- Workflow state diagrams
- Customization guide
- Troubleshooting

---

## 🎉 You're Ready!

Your Mayan EDMS instance is now configured with a comprehensive German business setup!

**Default Admin Credentials** (from kyborg_mayan.sh):
- Username: As configured during installation
- Password: As set during installation

**Test the Setup:**
1. Login to Mayan: `http://YOUR_SERVER_IP`
2. Check: System → Document Types (should see 113 types)
3. Check: System → Metadata Types (should see 273 types)
4. Check: Tags (should see 116 tags)
5. Check: Cabinets (should see folder structure)
6. Check: Workflows (should see 10 workflows)

Good luck! 🚀

# Mayan EDMS preTypes Configuration Files

Comprehensive German business configuration for Mayan EDMS 4.10.

## Overview

This directory contains pre-configured types, workflows, tags, and structures for a German business environment, covering:
- Accounting & Invoicing
- Contracts & Legal
- GDPR/DSGVO compliance
- E-commerce (Shopify, Amazon, eBay, etc.)
- Tax & GoBD compliance
- HR & Payroll
- And much more...

## File Status

### ✅ Ready to Import (Tested)

| File | Description | Count |
|------|-------------|-------|
| `01_metadata_types.json` | Metadata field definitions | 273 types |
| `02_document_types.json` | Document categories | 113 types |
| `03_tags.json` | Status and category tags | 116 tags |
| `04_cabinets.json` | Folder hierarchy | 100+ cabinets |
| `05_workflows.json` | Business workflows with states | 10 workflows |
| `08_document_type_metadata_types.json` | Document ↔ Metadata mappings | 246 mappings |

### ⚠️ Fixed but Requires Manual Configuration

| File | Description | Status |
|------|-------------|--------|
| `06_users.json` | User accounts | Passwords set to `!` (unusable) - **Must set via admin UI** |
| `07_roles.json` | Permission roles | Created but **no permissions assigned** |
| `09_saved_searches.json` | Pre-defined searches | Labels only - **Queries must be configured via UI** |

### 🗑️ Old/Disabled Versions (Keep for Reference)

- `06_users_DISABLED.json` - Original with invalid password hashes
- `07_roles_DISABLED.json` - Original with wrong model name
- `09_saved_searches_DISABLED.json` - Original with invalid query format

## Quick Start

### Option 1: Automated Import (Recommended)

Copy files to Mayan container and run import script:

```bash
# From project root directory
docker compose cp preTypes mayan_app:/srv/mayan/
docker compose cp import_preTypes.sh mayan_app:/srv/mayan/
docker compose cp import_cabinets_api.py mayan_app:/srv/mayan/

# Run import
docker compose exec -T mayan_app /srv/mayan/import_preTypes.sh
```

### Option 2: Manual Import

```bash
# Enter Mayan container
docker compose exec -it mayan_app /bin/bash

# Navigate to preTypes directory
cd /srv/mayan/preTypes

# Import in order:
/opt/mayan-edms/bin/mayan-edms.py loaddata 01_metadata_types.json
/opt/mayan-edms/bin/mayan-edms.py loaddata 02_document_types.json
/opt/mayan-edms/bin/mayan-edms.py loaddata 03_tags.json
/opt/mayan-edms/bin/mayan-edms.py loaddata 04_cabinets.json
/opt/mayan-edms/bin/mayan-edms.py loaddata 05_workflows.json
/opt/mayan-edms/bin/mayan-edms.py loaddata 06_users.json
/opt/mayan-edms/bin/mayan-edms.py loaddata 07_roles.json
/opt/mayan-edms/bin/mayan-edms.py loaddata 08_document_type_metadata_types.json
/opt/mayan-edms/bin/mayan-edms.py loaddata 09_saved_searches.json
```

### Option 3: Cabinets via API (If loaddata fails)

```bash
docker compose cp import_cabinets_api.py mayan_app:/srv/mayan/
docker compose exec -T mayan_app python3 /srv/mayan/import_cabinets_api.py
```

## Post-Import Configuration

### 1. Set User Passwords ⚠️ REQUIRED

All users are created with unusable passwords (`!`). Set them via admin UI:

```bash
# OR use Django shell:
docker compose exec -it mayan_app /bin/bash
/opt/mayan-edms/bin/mayan-edms.py shell

# In Python shell:
from django.contrib.auth.models import User
user = User.objects.get(username='buchhaltung')
user.set_password('YourSecurePassword123!')
user.save()
```

**Default users created:**
- `buchhaltung` - Accounting team
- `geschaeftsfuehrung` - Management
- `datenschutz` - Data protection officer
- `shop_team` - E-commerce team
- `steuerberater` - Tax consultant (external)
- `personal` - HR department
- `rechtsabteilung` - Legal department
- `steuerpruefer_2025` - Tax auditor (inactive)
- `readonly` - Read-only access

### 2. Assign Role Permissions ⚠️ REQUIRED

Roles are created but have no permissions. Assign via:
- **UI:** System → Roles → [Select Role] → Permissions tab
- Configure per role based on business needs

**Roles created:**
- Administrator
- Buchhaltung - Vollzugriff / Nur Lesen
- Geschäftsführung
- Datenschutzbeauftragter
- Shop-Team
- Steuerberater (extern)
- Personal-Abteilung
- Rechtsabteilung
- Steuerprüfer (temporär)
- Nur Lesen (global)
- Vertragsmanagement
- Projektleiter
- IT-Sicherheit
- Zoll und Export

### 3. Configure Saved Searches (Optional)

Saved searches are created with labels only. Configure queries via UI:
- Navigate to: **Search → Advanced search**
- Build your query
- Click **Save this search** and select the pre-created name

## Generate Users with Passwords

If you want to generate users with actual passwords instead of unusable ones:

```bash
# Inside Mayan container:
cd /srv/mayan/preTypes
python3 generate_users.py > 06_users_with_passwords.json

# This creates users with password: "ChangeMe2025!"
# Import:
/opt/mayan-edms/bin/mayan-edms.py loaddata 06_users_with_passwords.json
```

## File Details

### 01_metadata_types.json - 273 Metadata Types

**Categories:**
- **Invoice/Accounting** (1-30): Invoice numbers, dates, amounts, VAT, payment info
- **Shipping** (50-58): Tracking, carrier, delivery status
- **Contracts** (100-115): Contract details, terms, cancellation dates
- **Legal** (150-157): Case numbers, authorities, deadlines
- **HR/Payroll** (200-215): Employee data, salaries, sick leave
- **Tax** (250-265): Tax years, types, amounts, audit info
- **E-commerce** (300-339): Shop orders, marketplace IDs, returns
- **Accounting Software** (400-407): DATEV, Lexoffice, sevDesk integration
- **ZUGFeRD/XRechnung** (450-454): E-invoicing standards
- **GDPR/DSGVO** (500-518): Data protection, consent, breaches
- **Data Breaches** (550-559): Incident tracking (72h requirement)
- **GoBD** (600-607): German tax compliance
- **Retention** (650-658): Archiving and legal holds
- **Accounting Periods** (700-702): Year/month/quarter
- **Customs** (750-758): MRN, EUR.1, tariff numbers
- **Insurance** (800-810): Policies, claims
- **Software Licenses** (850-858): License keys, seats, costs
- **Projects** (900-907): Project management
- **Medical** (950-956): Patient records, prescriptions
- **Property** (980-983): Real estate documents
- **General** (990-995): Comments, references, migration

### 02_document_types.json - 113 Document Types

**Categories:**
- **Invoicing** (1-10): Incoming/outgoing invoices, credit notes, delivery notes
- **Contracts** (20-28): Various contract types, NDAs, wills
- **HR** (30-38): Employment contracts, payroll, sick leave
- **Tax** (40-48): Tax returns, VAT filings, audits
- **E-commerce** (50-54): Shop orders, returns, marketplace statements
- **GDPR** (60-67): Data subject requests, breach notifications
- **Legal** (70-74): Court documents, registry extracts
- **Corporate** (80-83): Company documents, resolutions
- **Insurance** (90-92): Policies, claims
- **Customs** (100-103): Customs declarations, Intrastat
- **IT** (110-113): Software licenses, security reports
- **Medical** (120-122): Medical records, prescriptions
- **Property** (130-132): Land registry, energy certificates
- **Certificates** (140-142): Birth certificates, diplomas
- **Correspondence** (150-151): General correspondence, archived emails
- **Media** (160-162): Photos, model releases, KSK reports
- **Projects** (170-172): Project documentation, research
- **Marketing** (180-181): Campaigns, promotional materials
- **Inventory** (190-191): Stock counts, price lists
- **GoBD** (200-201): Compliance documentation

### 03_tags.json - 116 Tags

**Categories:**
- **Status** (1-6): Urgent, open, in progress, done, postponed, review required
- **Payment** (10-17): Paid, unpaid, overdue, part-paid, dunning, discount
- **Accounting** (20-23): Booked, export ready, errors, review
- **E-invoicing** (30-34): ZUGFeRD, XRechnung, OCR status
- **GoBD** (40-47): Archived, retention expired, legal hold, tax audit
- **GDPR** (50-59): Personal data, consent, anonymized, requests
- **Contracts** (60-64): Active, cancelled, expired, renewal pending
- **Sources** (70-79): Shopify, Amazon, eBay, DATEV, email, scan
- **Sync** (80-83): Success, pending, error, manual
- **Returns** (90-93): Open, completed, refunded
- **International** (100-104): OSS, EU, third country, reverse charge
- **Customs** (110-113): EUR.1, preferential proof, Intrastat
- **Company** (120-123): GmbH, GbR, Private, Holding
- **Deadlines** (130-133): Critical, 7 days, 30 days, met
- **Signatures** (140-143): Required, digital, original, copy
- **Approvals** (150-152): Tax consultant, auditor, compliance-critical
- **Years** (200-206): 2024, 2025, 2026, Q1-Q4
- **KSK** (210-212): Art social insurance fund reporting

### 04_cabinets.json - 100+ Folder Structure

**Main Cabinets:**
- **Buchhaltung** (1-7): Accounting (incoming/outgoing invoices, statements, etc.)
- **Steuern** (10-15): Taxes (VAT, returns, assessments, audits, OSS)
- **Verträge** (20-28): Contracts (service, rent, supplier, customer, AV, insurance, licenses)
- **Personal** (30-36): HR (contracts, payroll, sick leave, vacation, certificates)
- **Gesellschaft** (40-44): Corporate (founding docs, resolutions, registry)
- **DSGVO** (50-57): GDPR (AV contracts, consents, requests, breaches, TOM)
- **Shop** (60-67): E-commerce (marketplaces, returns, payment providers)
- **Rechtsfälle** (70-74): Legal cases (ongoing, closed, inheritance, dunning)
- **Zoll** (80-84): Customs (EUR.1, declarations, Intrastat, product data)
- **IT** (90-94): IT (licenses, maintenance, pentests, documentation)
- **Versicherungen** (100-104): Insurance (liability, legal, cyber, claims)
- **Privat** (110-115): Private (personal docs, medical, property, vehicles, inheritance)
- **Projekte** (120-122): Projects (ongoing, completed)
- **GoBD** (130-132): Compliance (procedures, protocols)
- **Steuerprüfung** (200-201): Tax audits (2024, 2025)

### 05_workflows.json - 10 Workflows

1. **Rechnungseingang** (Invoice incoming): OCR → Review → Approval → Payment → Archive
2. **Rechnungsausgang** (Invoice outgoing): Created → Sent → Dunning levels → Paid/Written off
3. **DSGVO-Auskunftsersuchen** (GDPR data request): Received → Identity check → Data collection → Response (30 days + extension)
4. **DSGVO-Löschantrag** (GDPR deletion): Received → Identity check → Retention check → Delete/Reject/Anonymize
5. **Vertragsmanagement** (Contract management): Draft → Review → Negotiation → Signed → Active → Cancellation
6. **Shop-Retoure** (Shop return): Registered → Received → Inspection → Refund/Exchange
7. **GoBD-Aufbewahrung** (GoBD retention): Captured → Archived → Retention → Legal hold → Deletion approval
8. **Datenschutzvorfall** (Data breach): Detected → Assessment → Notification to authority (72h!) → Affected persons notified
9. **Versicherungsschaden** (Insurance claim): Reported → Documented → Submitted → Processed → Settled/Rejected
10. **ZUGFeRD-Verarbeitung** (ZUGFeRD processing): PDF received → Detected → Extracted → Validated → Accounting

### 08_document_type_metadata_types.json - 246 Mappings

Links metadata types to document types with required/optional flags.

**Examples:**
- **Eingangsrechnung** (Incoming invoice): invoice_number (required), invoice_date (required), amount_gross (required), supplier_name (required), plus 25 optional fields
- **Arbeitsvertrag** (Employment contract): employee_name (required), employee_id (optional), employment_start (required), etc.
- **DSGVO-Auskunftsersuchen** (GDPR request): affected_person (required), request_date (required), deadline (required), etc.

## Troubleshooting

### Import Errors

**"No such table: cabinets_cabinet"**
- Run migrations first: `/opt/mayan-edms/bin/mayan-edms.py migrate`

**"Duplicate key violation"**
- Items already exist. Delete existing data or change PKs in JSON files

**"Foreign key constraint fails"**
- Import order matters! Follow the numbered sequence (01 → 02 → 03 → ...)

### Cabinets Not Importing

If `loaddata` fails for cabinets, use the API script:
```bash
docker compose exec -T mayan_app python3 /srv/mayan/import_cabinets_api.py
```

### Users Can't Login

Users are created with unusable passwords (`!`). Set passwords via:
- Admin UI: System → Users → Edit User → Set Password
- Django shell (see Post-Import Configuration section)

## Customization

### Modify Before Import

Edit JSON files to match your business:
- Change company-specific terms
- Add/remove metadata types
- Modify folder structure
- Adjust workflow states

### Export Your Changes

After customizing in Mayan UI:
```bash
docker compose exec -T mayan_app /bin/bash
/opt/mayan-edms/bin/mayan-edms.py dumpdata metadata.metadatatype --indent 2 > my_metadata_types.json
/opt/mayan-edms/bin/mayan-edms.py dumpdata documents.documenttype --indent 2 > my_document_types.json
# etc.
```

## Support

For Mayan EDMS documentation: https://docs.mayan-edms.com/

For script issues: Check the GitHub repository README

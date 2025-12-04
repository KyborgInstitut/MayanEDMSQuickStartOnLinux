# preTypes_en - English International Business Types

This directory contains simplified English preTypes for **international business use**.

## 📦 What's Included

| Type | Count | File | Description |
|------|-------|------|-------------|
| **Metadata Types** | 20 | `01_metadata_types.json` | Common business metadata fields |
| **Document Types** | 20 | `02_document_types.json` | International business documents |
| **Tags** | 20 | `03_tags.json` | Status and category tags |
| **Roles** | 5 | `07_roles.json` | Basic organizational roles |

## 📋 Metadata Types (20)

### Financial
- Document Date
- Document Number
- Amount
- Currency (default: USD)
- Due Date
- Payment Status
- Reference Number

### Parties
- Customer Name
- Vendor Name
- Employee Name
- Employee ID

### Contracts
- Contract Number
- Start Date
- End Date

### Organization
- Department
- Project Name
- Category

### General
- Status (default: Active)
- Priority (default: Normal)
- Notes

## 📄 Document Types (20)

### Financial Documents
1. **Invoice - Incoming** - Vendor invoices to pay
2. **Invoice - Outgoing** - Customer invoices sent
3. **Purchase Order** - Orders to vendors
4. **Sales Order** - Customer orders received
5. **Receipt** - Payment receipts
6. **Quote** - Price quotations
7. **Tax Document** - Tax forms and filings
8. **Financial Statement** - Financial reports
9. **Bank Statement** - Bank account statements

### Contracts & Agreements
10. **Contract** - General contracts
11. **Agreement** - Business agreements
12. **Employment Contract** - Employee contracts

### Human Resources
13. **Payroll Document** - Salary and payroll
14. **Employment Contract** - HR contracts

### Operations
15. **Report** - Business reports
16. **Correspondence** - Letters and emails
17. **Meeting Minutes** - Meeting notes
18. **Proposal** - Business proposals
19. **Delivery Note** - Shipping documents
20. **Shipping Document** - Logistics documents

### Insurance
21. **Insurance Document** - Insurance policies and claims

## 🏷️ Tags (20)

### Status Tags
- Urgent 🔴
- Pending 🟡
- Completed 🟢
- Approved 🔵
- Rejected 🔴
- In Progress 🟡

### Payment Status
- Paid 🟢
- Unpaid 🔴
- Overdue 🔴

### Classification
- Confidential 🖤
- Internal 🔵
- External 🟢

### Document State
- Draft 🔘
- Final 🟢
- Archived 🔘
- For Review 🟣

### Priority
- High Priority 🔴
- Low Priority 🔵

### Party Type
- Customer 🔵
- Vendor 🟠

## 👥 Roles (5)

1. **Administrator** - Full system access
2. **Manager** - Department management
3. **Accountant** - Financial documents
4. **Employee** - Basic access
5. **Viewer** - Read-only access

**Note:** Roles are created without permissions. Assign permissions after import via:
```
System → Roles → [Role Name] → Permissions
```

## 🆚 Comparison: English vs German preTypes

| Feature | English (preTypes_en) | German (preTypes) |
|---------|----------------------|-------------------|
| **Focus** | International business | German business (GoBD, GDPR, tax) |
| **Metadata Types** | 20 essential | 273 comprehensive |
| **Document Types** | 20 common | 113 specialized |
| **Tags** | 20 universal | 116 German-specific |
| **Workflows** | Not included | 10 German workflows |
| **Complexity** | Simple | Comprehensive |
| **Use Case** | General business | German regulatory compliance |

## 🚀 Usage

### During Installation

The bilingual installer will ask:

```
Which language for preTypes?

  1) English - International business types
  2) German - German business types (GoBD, GDPR, tax)

Choose / Wählen [1-2]:
```

Select **1** for English preTypes.

### Manual Import

```bash
cd /srv/mayan
docker compose exec -T mayan_app /opt/mayan-edms/bin/mayan-edms.py loaddata /srv/mayan/preTypes/01_metadata_types.json
docker compose exec -T mayan_app /opt/mayan-edms/bin/mayan-edms.py loaddata /srv/mayan/preTypes/02_document_types.json
docker compose exec -T mayan_app /opt/mayan-edms/bin/mayan-edms.py loaddata /srv/mayan/preTypes/03_tags.json
docker compose exec -T mayan_app /opt/mayan-edms/bin/mayan-edms.py loaddata /srv/mayan/preTypes/07_roles.json
```

## ✅ Post-Import Steps

1. **Assign Role Permissions**
   ```
   System → Roles → [Select Role] → Permissions
   ```

2. **Link Metadata to Document Types**
   ```
   System → Document Types → [Select Type] → Metadata
   ```

3. **Create Users** (optional)
   ```
   System → Users → Create user
   ```

4. **Setup Cabinets** (optional)
   ```
   Cabinets → Create cabinet
   ```

## 🌍 Customization

This is a **starter set** for international business. You can:

- Add more metadata types for your industry
- Create additional document types
- Add custom tags
- Define workflows via GUI
- Extend roles and permissions

## 📚 Additional Resources

- **Mayan Documentation:** https://docs.mayan-edms.com/
- **Main README:** `../README.md`
- **Installation Guide:** `../IMPORT_GUIDE.md`
- **Troubleshooting:** `../TROUBLESHOOTING.md`

## 💡 When to Use

**Use English preTypes if you:**
- Run an international business
- Don't need German regulatory compliance
- Want a simple starting point
- Prefer English terminology

**Use German preTypes if you:**
- Operate in Germany
- Need GoBD compliance
- Require GDPR/DSGVO workflows
- Handle German tax forms (UStVA, etc.)

---

**Need more?** The German preTypes (`../preTypes/`) include 273 metadata types covering:
- GoBD accounting compliance
- GDPR data protection
- German tax forms
- E-commerce platforms (Amazon.de, eBay.de)
- German legal requirements

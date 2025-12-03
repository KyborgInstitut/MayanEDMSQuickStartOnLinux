# Manual Setup Guide

This guide explains how to manually configure features that cannot be imported via JSON fixtures.

## 📁 Cabinets (Folder Structure)

**Why manual?** Cabinets use MPTT (Modified Preorder Tree Traversal) for hierarchical folder structures. The required tree fields (`lft`, `rght`, `tree_id`, `level`) must be calculated automatically and cannot be imported via JSON.

### Recommended Folder Structure

Based on `04_cabinets_DISABLED.json`, here's the suggested cabinet hierarchy:

```
📁 Buchhaltung (Accounting)
  ├── 📁 Eingangsrechnungen (Incoming Invoices)
  ├── 📁 Ausgangsrechnungen (Outgoing Invoices)
  ├── 📁 Gutschriften (Credits)
  └── 📁 Kassenberichte (Cash Reports)

📁 Verträge (Contracts)
  ├── 📁 Aktiv (Active)
  ├── 📁 Abgelaufen (Expired)
  ├── 📁 Gekündigt (Terminated)
  └── 📁 AV-Verträge DSGVO (GDPR DPA)

📁 Personal (HR)
  ├── 📁 Arbeitsverträge (Employment Contracts)
  ├── 📁 Gehaltsabrechnungen (Payslips)
  ├── 📁 Urlaubsanträge (Leave Requests)
  └── 📁 Abmahnungen (Warnings)

📁 Steuern (Taxes)
  ├── 📁 Umsatzsteuer (VAT)
  ├── 📁 Jahresabschlüsse (Annual Financial Statements)
  ├── 📁 Betriebsprüfung (Tax Audits)
  └── 📁 Bescheide (Tax Notices)

📁 Versicherungen (Insurance)
  ├── 📁 Betriebshaftpflicht (Business Liability)
  ├── 📁 Krankenversicherung (Health Insurance)
  ├── 📁 Sozialversicherung (Social Insurance)
  └── 📁 Schadensmeldungen (Claims)

📁 Kunden (Customers)
  ├── 📁 Verträge (Contracts)
  ├── 📁 Korrespondenz (Correspondence)
  └── 📁 Beschwerden (Complaints)

📁 Lieferanten (Suppliers)
  ├── 📁 Verträge (Contracts)
  ├── 📁 Lieferscheine (Delivery Notes)
  └── 📁 Qualitätssicherung (QC)

📁 DSGVO (GDPR)
  ├── 📁 Auskunftsanfragen (Access Requests)
  ├── 📁 Löschanträge (Deletion Requests)
  ├── 📁 Einwilligungen (Consents)
  └── 📁 Datenpannen (Data Breaches)

📁 Shop / E-Commerce
  ├── 📁 Shopify
  ├── 📁 Amazon
  ├── 📁 Retouren (Returns)
  └── 📁 OSS-Verkäufe (OSS Sales)

📁 Behörden (Authorities)
  ├── 📁 Finanzamt (Tax Office)
  ├── 📁 Gewerbeamt (Trade Office)
  ├── 📁 IHK (Chamber of Commerce)
  └── 📁 Gerichte (Courts)
```

### How to Create Cabinets

1. **Login** to Mayan EDMS as admin
2. **Navigate**: Sidebar → **Cabinets**
3. **Create parent cabinet**:
   - Click **"Create cabinet"**
   - Enter: `Buchhaltung`
   - Click **Save**
4. **Create subcabinets**:
   - Click on the parent cabinet (`Buchhaltung`)
   - Click **"Create child cabinet"**
   - Enter: `Eingangsrechnungen`
   - Click **Save**
5. **Repeat** for all folders in the structure above

### Tips

- Start with top-level folders (Buchhaltung, Verträge, Personal, etc.)
- Then create subfolders within each parent
- You can always reorganize later by dragging documents between cabinets
- Cabinets are like folders - documents can be in multiple cabinets

---

## 🔍 Saved Searches

**Why manual?** Saved searches require query definitions (filters, field selections, sorting) that depend on your specific metadata configuration and cannot be predefined in JSON.

### Recommended Saved Searches

Based on `09_saved_searches_DISABLED.json`:

#### 📋 **Accounting Searches**
1. **Offene Eingangsrechnungen** (Open Incoming Invoices)
   - Filter: Document Type = "Eingangsrechnung"
   - Filter: Metadata "Status" = "Offen"

2. **Überfällige Rechnungen** (Overdue Invoices)
   - Filter: Document Type = "Eingangsrechnung"
   - Filter: Metadata "Fälligkeitsdatum" < Today

3. **Skonto noch möglich** (Cash Discount Still Possible)
   - Filter: Document Type = "Eingangsrechnung"
   - Filter: Metadata "Skonto-Datum" > Today

4. **Rechnungen ohne Buchung** (Invoices Without Booking)
   - Filter: Document Type = "Eingangsrechnung"
   - Filter: Metadata "Gebucht" = "Nein"

#### 📝 **Contract Searches**
5. **Verträge - Kündigung prüfen** (Contracts - Check Termination)
   - Filter: Document Type contains "Vertrag"
   - Filter: Metadata "Kündigungsfrist" within next 60 days

6. **Verträge - Aktiv** (Active Contracts)
   - Filter: Document Type contains "Vertrag"
   - Filter: Metadata "Status" = "Aktiv"

7. **AV-Verträge (DSGVO)** (GDPR DPA Contracts)
   - Filter: Document Type = "AV-Vertrag (Auftragsverarbeitung DSGVO)"

#### 🔒 **GDPR Searches**
8. **DSGVO - Auskunft ausstehend** (GDPR - Pending Access Request)
   - Filter: Document Type = "DSGVO Auskunftsanfrage"
   - Filter: Metadata "Status" = "Offen"

9. **DSGVO - Löschung durchzuführen** (GDPR - Deletion to Perform)
   - Filter: Document Type = "DSGVO Löschantrag"
   - Filter: Metadata "Status" = "Zu bearbeiten"

10. **Datenschutzvorfälle** (Data Breaches)
    - Filter: Document Type = "Datenpanne"

11. **Einwilligungen widerrufen** (Consents Revoked)
    - Filter: Document Type = "Einwilligung"
    - Filter: Metadata "Status" = "Widerrufen"

#### 📊 **GoBD Compliance Searches**
12. **GoBD - Löschbare Dokumente** (GoBD - Deletable Documents)
    - Filter: Metadata "GoBD Aufbewahrungsfrist" < Today
    - Filter: Metadata "GoBD Rechtssperre" = "Nein"

13. **GoBD - Rechtssperre aktiv** (GoBD - Legal Hold Active)
    - Filter: Metadata "GoBD Rechtssperre" = "Ja"

14. **GoBD - Aufbewahrung abgelaufen** (GoBD - Retention Expired)
    - Filter: Metadata "GoBD Aufbewahrungsfrist" < Today

15. **Steuerprüfung relevant** (Tax Audit Relevant)
    - Filter: Tags contain "Steuerprüfung"

#### 🛒 **E-Commerce Searches**
16. **Shop - Offene Retouren** (Open Returns)
    - Filter: Document Type = "Retourenschein"
    - Filter: Metadata "Status" = "Offen"

17. **Shop - Sync-Fehler** (Shop Sync Errors)
    - Filter: Tags contain "Sync-Fehler"

18. **Shopify Bestellungen** (Shopify Orders)
    - Filter: Metadata "Shop-Plattform" = "Shopify"

19. **Amazon Bestellungen** (Amazon Orders)
    - Filter: Metadata "Shop-Plattform" = "Amazon"

20. **OSS-pflichtige Verkäufe** (OSS-liable Sales)
    - Filter: Tags contain "OSS"

#### ⏰ **Deadline Searches**
21. **Fristen - Kritisch (7 Tage)** (Deadlines - Critical 7 days)
    - Filter: Metadata "Frist" within next 7 days

22. **Fristen - 30 Tage** (Deadlines - 30 days)
    - Filter: Metadata "Frist" within next 30 days

### How to Create Saved Searches

1. **Login** to Mayan EDMS as admin
2. **Navigate**: Sidebar → **Search** → **Advanced search**
3. **Configure search**:
   - Select search scope (usually "Documents")
   - Add filters (Document Type, Metadata fields, Tags, Dates, etc.)
   - Test the search by clicking **Search**
4. **Save search**:
   - If results are correct, click **"Save this search"**
   - Enter a descriptive name (e.g., "Offene Eingangsrechnungen")
   - Click **Save**
5. **Access saved searches**: Sidebar → **Search** → **Saved searches**

### Tips

- Start with the most frequently needed searches
- Test each search thoroughly before saving
- Use descriptive names in German if your team prefers it
- Saved searches can be edited or deleted later
- You can share saved searches with specific user roles

---

## ✅ What Was Successfully Imported

The following were imported successfully and are ready to use:

- ✅ **273 Metadata Types** - Custom fields for documents
- ✅ **113 Document Types** - Categories for your documents
- ✅ **116 Tags** - Labels for organization
- ✅ **10 Workflows** (169 objects) - Automation processes with states
- ✅ **9 Users** - Team members (passwords need to be set)
- ✅ **15 Roles** - Permission groups (need permission assignment)
- ✅ **215 Mappings** - Links between document types and metadata

---

## 🎯 Next Steps

1. **Set user passwords**: System → Users → Edit each user → Set password
2. **Assign role permissions**: System → Roles → Edit each role → Permissions tab
3. **Create cabinets**: Follow the folder structure above
4. **Create saved searches**: Start with your most important searches
5. **Test workflows**: Upload a test document and verify workflow automation
6. **Configure scanner/upload**: Setup watch folder or scanner integration

---

## 📚 Additional Resources

- **Mayan EDMS Documentation**: https://docs.mayan-edms.com/
- **Cabinets Guide**: https://docs.mayan-edms.com/parts/cabinets.html
- **Search Guide**: https://docs.mayan-edms.com/parts/search.html
- **Workflows Guide**: https://docs.mayan-edms.com/parts/workflows.html

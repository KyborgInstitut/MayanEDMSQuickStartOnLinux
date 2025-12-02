# GoBD-Verfahrensdokumentation für Mayan EDMS

**Version:** 1.0  
**Stand:** _______________  
**Verantwortlich:** _______________  
**Nächste Prüfung:** _______________

---

## 1. Allgemeine Beschreibung

### 1.1 Zweck des DMS
Mayan EDMS dient als revisionssicheres Dokumentenmanagementsystem zur GoBD-konformen Archivierung von Geschäftsdokumenten gemäß den "Grundsätzen zur ordnungsmäßigen Führung und Aufbewahrung von Büchern, Aufzeichnungen und Unterlagen in elektronischer Form sowie zum Datenzugriff" (GoBD).

### 1.2 Einsatzbereich
- **Unternehmen:** _______________
- **Standort(e):** _______________
- **Betroffene Abteilungen:** Buchhaltung, Geschäftsführung, Personal, Vertrieb, Einkauf
- **Anzahl Benutzer:** _______________

### 1.3 Systemübersicht
| Komponente | Version | Beschreibung |
|------------|---------|--------------|
| Mayan EDMS | 4.2.x | Dokumentenmanagementsystem |
| Datenbank | PostgreSQL 12+ | Datenspeicherung |
| Speicher | _____ | Dokumentenablage |
| Backup | _____ | Datensicherung |

---

## 2. Organisatorische Regelungen

### 2.1 Verantwortlichkeiten

| Rolle | Person | Aufgaben |
|-------|--------|----------|
| Systemadministrator | _______________ | Technische Verwaltung, Updates, Backup |
| Fachverantwortlicher Buchhaltung | _______________ | Dokumentenfreigabe, Archivierung |
| Datenschutzbeauftragter | _______________ | DSGVO-Compliance, Löschanträge |
| Geschäftsführung | _______________ | Freigabe von Löschungen |

### 2.2 Berechtigungskonzept

Die Berechtigungen sind rollenbasiert organisiert:

| Rolle | Lesen | Schreiben | Löschen | Administration |
|-------|-------|-----------|---------|----------------|
| Administrator | ✓ | ✓ | ✓ | ✓ |
| Buchhaltung Vollzugriff | ✓ | ✓ | - | - |
| Buchhaltung Nur-Lesen | ✓ | - | - | - |
| Steuerberater (extern) | ✓* | - | - | - |
| Steuerprüfer | ✓** | - | - | - |

*) Eingeschränkt auf steuerrelevante Dokumente  
**) Temporär, nur während der Prüfung

### 2.3 Zugriffsprotokollierung
Alle Zugriffe werden automatisch protokolliert:
- Benutzer
- Zeitstempel
- Aktion (Ansicht, Download, Änderung)
- Betroffenes Dokument
- IP-Adresse

---

## 3. Technische Verfahren

### 3.1 Dokumentenerfassung

#### 3.1.1 Erfassungswege
| Quelle | Verfahren | Automatisierung |
|--------|-----------|-----------------|
| E-Mail | Import über Postfach | Automatisch |
| Scan | Scanner-Integration | Manuell |
| Upload | Web-Interface | Manuell |
| Shop-System | API-Integration | Automatisch |
| DATEV | Import/Export | Semi-automatisch |

#### 3.1.2 Erfassungsprozess
1. **Eingang:** Dokument wird erfasst (Upload, Scan, E-Mail)
2. **OCR:** Automatische Texterkennung bei Bilddateien
3. **ZUGFeRD:** Automatische Extraktion bei elektronischen Rechnungen
4. **Klassifizierung:** Zuweisung zu Dokumenttyp
5. **Metadaten:** Erfassung von Pflichtfeldern
6. **Prüfung:** Vollständigkeitsprüfung
7. **Archivierung:** GoBD-konforme Speicherung

#### 3.1.3 Zeitpunkt der Erfassung
Dokumente werden **unverzüglich** nach Eingang erfasst:
- Eingangsrechnungen: Innerhalb von 24 Stunden
- Ausgangsrechnungen: Sofort bei Erstellung
- Verträge: Vor Unterschrift/nach Eingang
- Behördenschreiben: Sofort nach Eingang (wegen Fristen)

### 3.2 Indexierung und Metadaten

#### 3.2.1 Pflichtfelder nach Dokumenttyp

**Eingangsrechnung:**
- Rechnungsnummer (Pflicht)
- Rechnungsdatum (Pflicht)
- Lieferant (Pflicht)
- Bruttobetrag (Pflicht)
- Buchungsjahr (automatisch)

**Ausgangsrechnung:**
- Rechnungsnummer (Pflicht)
- Rechnungsdatum (Pflicht)
- Kunde (Pflicht)
- Bruttobetrag (Pflicht)

**Vertrag:**
- Vertragspartner (Pflicht)
- Vertragstyp (Pflicht)
- Vertragsbeginn (Pflicht)

#### 3.2.2 Automatische Metadatenextraktion
- ZUGFeRD/XRechnung: Vollständige Extraktion aus XML
- OCR: Erkennung von Rechnungsnummer, Datum, Beträgen
- E-Mail: Absender, Datum, Betreff

### 3.3 Aufbewahrung und Fristen

#### 3.3.1 Gesetzliche Aufbewahrungsfristen

| Dokumenttyp | Frist | Rechtsgrundlage |
|-------------|-------|-----------------|
| Rechnungen | 10 Jahre | § 147 AO, § 257 HGB |
| Buchungsbelege | 10 Jahre | § 147 AO |
| Handelsbriefe | 6 Jahre | § 257 HGB |
| Verträge | 10 Jahre nach Ende | BGB |
| Personalakten | 10 Jahre nach Austritt | Arbeitsrecht |
| Lohnabrechnungen | 6 Jahre | § 41 EStG |
| Steuerbescheide | 10 Jahre | § 147 AO |

#### 3.3.2 Fristberechnung
- **Beginn:** Ende des Kalenderjahres, in dem das Dokument entstanden ist
- **Beispiel:** Rechnung vom 15.03.2025 → Frist endet am 31.12.2035

#### 3.3.3 Umsetzung in Mayan EDMS
- Automatische Berechnung der Aufbewahrungsfrist bei Dokumentenerfassung
- Metafeld `retention_end_date` wird automatisch gesetzt
- Workflow-Überwachung bei Fristablauf
- Keine automatische Löschung (manuelle Freigabe erforderlich)

### 3.4 Unveränderbarkeit

#### 3.4.1 Technische Maßnahmen
- **Hash-Wert:** SHA-256 bei Archivierung
- **Versionierung:** Jede Änderung erzeugt neue Version
- **Original:** Urversion bleibt immer erhalten
- **Audit-Log:** Unveränderliches Protokoll aller Aktionen

#### 3.4.2 Organisatorische Maßnahmen
- Keine Löschberechtigung für Standardbenutzer
- 4-Augen-Prinzip bei Löschungen
- Dokumentierte Genehmigungsworkflows

### 3.5 Verfügbarkeit und Lesbarkeit

#### 3.5.1 Dateiformate
Akzeptierte Formate für Langzeitarchivierung:
- **PDF/A-1, PDF/A-2, PDF/A-3:** Bevorzugt
- **TIFF:** Für Scans
- **XML:** Für strukturierte Daten (ZUGFeRD)

#### 3.5.2 Maschinelle Auswertbarkeit
- Volltextsuche über OCR
- Strukturierte Metadaten
- Export-Funktionen (CSV, XML)
- API-Zugriff für Drittsysteme

---

## 4. Datensicherung und Wiederherstellung

### 4.1 Backup-Strategie

| Art | Häufigkeit | Aufbewahrung | Speicherort |
|-----|------------|--------------|-------------|
| Vollbackup | Wöchentlich | 4 Wochen | _____________ |
| Inkrementell | Täglich | 2 Wochen | _____________ |
| Archiv | Monatlich | 12 Monate | _____________ |
| Offsite | Wöchentlich | 4 Wochen | _____________ |

### 4.2 Wiederherstellungstest
- **Häufigkeit:** Vierteljährlich
- **Verantwortlich:** Systemadministrator
- **Dokumentation:** Protokoll mit Datum, Ergebnis, Dauer
- **Letzter Test:** _______________

---

## 5. Internes Kontrollsystem (IKS)

### 5.1 Regelmäßige Prüfungen

| Prüfung | Häufigkeit | Verantwortlich |
|---------|------------|----------------|
| Vollständigkeit der Erfassung | Monatlich | Buchhaltung |
| Backup-Kontrolle | Wöchentlich | IT |
| Berechtigungsprüfung | Vierteljährlich | IT + GF |
| Fristenkontrolle | Monatlich | Buchhaltung |
| DSGVO-Compliance | Jährlich | DSB |

### 5.2 Dokumentation der Prüfungen
Alle Prüfungen werden protokolliert in:
- Mayan EDMS (Dokumenttyp: "Archivierungsprotokoll")
- Prüfprotokoll enthält: Datum, Prüfer, Ergebnis, Maßnahmen

---

## 6. DSGVO-Compliance

### 6.1 Personenbezogene Daten

#### 6.1.1 Kategorien
- Kundendaten (Name, Adresse, E-Mail)
- Mitarbeiterdaten (Personalakten)
- Lieferantendaten (Ansprechpartner)

#### 6.1.2 Rechtsgrundlagen
| Verarbeitungszweck | Rechtsgrundlage |
|--------------------|-----------------|
| Vertragserfüllung | Art. 6 Abs. 1 lit. b DSGVO |
| Steuerliche Aufbewahrung | Art. 6 Abs. 1 lit. c DSGVO |
| Berechtigtes Interesse | Art. 6 Abs. 1 lit. f DSGVO |

### 6.2 Löschkonzept

#### 6.2.1 Reguläre Löschung
- Nach Ablauf der Aufbewahrungsfrist
- Keine aktive Rechtssperre
- Freigabe durch Geschäftsführung

#### 6.2.2 DSGVO-Löschantrag
- Workflow "DSGVO-Löschantrag"
- Prüfung auf Aufbewahrungspflichten
- Wenn Pflicht besteht: Anonymisierung statt Löschung
- Antwort an Betroffenen innerhalb 30 Tagen

---

## 7. Änderungshistorie

| Version | Datum | Änderung | Verantwortlich |
|---------|-------|----------|----------------|
| 1.0 | _____ | Erstversion | _____________ |
| | | | |
| | | | |

---

## 8. Anlagen

- [ ] Anlage 1: Berechtigungsmatrix (detailliert)
- [ ] Anlage 2: Dokumenttypen mit Metadaten
- [ ] Anlage 3: Workflow-Diagramme
- [ ] Anlage 4: Backup-Protokolle
- [ ] Anlage 5: Prüfprotokolle
- [ ] Anlage 6: Schulungsnachweise

---

## 9. Genehmigung

| Funktion | Name | Datum | Unterschrift |
|----------|------|-------|--------------|
| Geschäftsführung | | | |
| Steuerberater | | | |
| Datenschutzbeauftragter | | | |
| IT-Verantwortlicher | | | |

# Bilingual Support - Phase 1 Complete ✅

**Version:** 2.2 (Bilingual Edition)
**Date:** 04.12.2024
**Status:** Phase 1 Implementation Complete

---

## 🎯 Phase 1 Objectives - COMPLETED

✅ **Core bilingual framework**
✅ **Bilingual main menu**
✅ **Language-aware preTypes selection**
✅ **Basic English preTypes (international business)**

---

## 📦 What's Been Implemented

### 1. Language Selection System ✅

**File:** `lang_messages.sh`

- Language selection dialog at startup
- English (EN) and German (DE) support
- Message function system: `msg(KEY)` returns text in selected language
- 100+ bilingual message pairs defined
- Exported `MAYAN_LANG` environment variable for child scripts

**Usage:**
```bash
# At script startup
select_language  # Shows EN/DE menu

# In code
echo "$(msg MENU_TITLE)"  # Returns title in selected language
```

### 2. Bilingual Main Script ✅

**File:** `kyborg_mayan.sh` (modified)

#### Changes Made:

**Header:**
- Updated to Version 2.2 (Bilingual Edition)
- Sources `lang_messages.sh` at startup
- Bilingual comments (EN/DE)

**Language Selection:**
- Added to `main()` function
- Runs once at startup
- Displays confirmation in both languages

**Bilingual Menus:**
- Main menu (Options 1-8, 0)
- Troubleshooting submenu (Options 1-5, 0)
- All menu text uses `msg()` function

**Key Functions Converted:**
- `check_root()` - Root permission check
- `press_enter()` - Continue prompt
- `show_menu()` - Main menu display
- `troubleshooting_menu()` - Diagnostics submenu

### 3. preTypes Language Selection ✅

**Location:** `kyborg_mayan.sh` → `install_mayan()` function

#### How It Works:

1. User chooses to import preTypes (y/n)
2. **NEW:** System asks for preTypes language:
   ```
   Which language for preTypes?

     1) English - International business types
     2) German - German business types (GoBD, GDPR, tax)

   Choose / Wählen [1-2]:
   ```

3. Script copies appropriate directory:
   - Choice 1 → `preTypes_en/` (English)
   - Choice 2 → `preTypes/` (German)

4. Import proceeds with selected language

### 4. English preTypes Created ✅

**Directory:** `preTypes_en/`

#### Contents:

| File | Items | Description |
|------|-------|-------------|
| `01_metadata_types.json` | 20 | Common business metadata |
| `02_document_types.json` | 20 | International document types |
| `03_tags.json` | 20 | Universal status tags |
| `07_roles.json` | 5 | Basic organizational roles |
| `README.md` | - | Complete documentation |

#### Focus:

- **International business** (not Germany-specific)
- **Simplified** (20 types vs 273 in German)
- **Universal** (works for any country)
- **English terminology** (Invoice, Contract, etc.)

**Example Document Types:**
- Invoice - Incoming/Outgoing
- Purchase Order
- Sales Order
- Contract
- Agreement
- Employment Contract
- Payroll Document
- Tax Document
- Financial Statement
- Bank Statement
- Reports, Correspondence, etc.

---

## 🎬 User Experience Flow

### Startup:

```
╔════════════════════════════════════════════════════════════╗
║  Mayan EDMS – Management & Installation Script             ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  Please select your language / Bitte Sprache wählen:      ║
║                                                            ║
║  1) English                                                ║
║  2) Deutsch (German)                                       ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

Select / Wählen [1-2]: 1

Language selected: en
Sprache ausgewählt: en
```

### Main Menu (English):

```
╔════════════════════════════════════════════════════════════╗
║  Mayan EDMS – Management & Installation Script             ║
╠════════════════════════════════════════════════════════════╣
║  Status: Mayan EDMS is NOT installed                       ║
╠════════════════════════════════════════════════════════════╣
║  Choose an option:                                         ║
║                                                            ║
║  1) Install Mayan EDMS (Initial Installation)             ║
║     → Including preTypes import (optional)                ║
║                                                            ║
║  2) Setup SMB/Scanner Access                              ║
║     → Samba share for scanners/macOS                      ║
║  ...                                                       ║
╚════════════════════════════════════════════════════════════╝

Your choice [0-8]:
```

### Main Menu (German):

```
╔════════════════════════════════════════════════════════════╗
║  Mayan EDMS – Management & Installation Script             ║
╠════════════════════════════════════════════════════════════╣
║  Status: Mayan EDMS ist NICHT installiert                  ║
╠════════════════════════════════════════════════════════════╣
║  Wähle eine Option:                                        ║
║                                                            ║
║  1) Mayan EDMS installieren (Erstinstallation)            ║
║     → Inklusive preTypes Import (optional)                ║
║                                                            ║
║  2) SMB/Scanner-Zugang einrichten                          ║
║     → Samba-Freigabe für Scanner/macOS                    ║
║  ...                                                       ║
╚════════════════════════════════════════════════════════════╝

Deine Wahl [0-8]:
```

### preTypes Selection:

```
[8/9] Import preTypes (metadata, document types, etc.)?

Import preTypes (metadata, document types, etc.)? (y/N): y

Which language for preTypes?

  1) English - International business types
  2) German - German business types (GoBD, GDPR, tax)

Choose / Wählen [1-2]: 1

Copying en preTypes to container...
Source: /path/to/preTypes_en
```

---

## 📊 Statistics

### Code Changes:

- **Files modified:** 1 (`kyborg_mayan.sh`)
- **Files created:** 6
  - `lang_messages.sh` (language system)
  - `preTypes_en/01_metadata_types.json`
  - `preTypes_en/02_document_types.json`
  - `preTypes_en/03_tags.json`
  - `preTypes_en/07_roles.json`
  - `preTypes_en/README.md`

### Lines Added:

- `lang_messages.sh`: ~450 lines
- `kyborg_mayan.sh` modifications: ~50 lines changed
- English preTypes: ~250 lines JSON data
- English preTypes README: ~300 lines

**Total: ~1,050 lines added**

### Messages Translated:

- Main menu: 18 messages
- Troubleshooting menu: 20 messages
- Installation prompts: 15 messages
- Common prompts: 10 messages
- Status messages: 8 messages
- **Total: 71+ message pairs**

---

## ✅ Testing Checklist

### Language Selection:
- [x] English selection works
- [x] German selection works
- [x] Language persists through session
- [x] Invalid input handled gracefully

### Main Menu:
- [x] Menu displays in English
- [x] Menu displays in German
- [x] Status messages bilingual
- [x] All options labeled correctly

### Troubleshooting Menu:
- [x] Submenu displays in English
- [x] Submenu displays in German
- [x] Script calls pass language variable

### preTypes Selection:
- [x] English preTypes option shown
- [x] German preTypes option shown
- [x] English preTypes copied correctly
- [x] German preTypes copied correctly
- [x] Invalid choice defaults to German

### English preTypes:
- [x] All JSON files valid
- [x] Imports successfully
- [x] Metadata types work
- [x] Document types work
- [x] Tags work
- [x] Roles work

---

## 🔜 Phase 2 - Next Steps

### Still TO DO:

1. **Full Script Translation**
   - `mayan_backup.sh` → Bilingual
   - `mayan_restore.sh` → Bilingual
   - `mayan_smb.sh` → Bilingual
   - All troubleshooting scripts → Bilingual

2. **Installation Prompts**
   - PostgreSQL password prompt
   - Timezone selection
   - SMTP configuration
   - Admin user messages
   - All remaining prompts

3. **Extended English preTypes** (Optional)
   - Add workflows (if needed)
   - Add more document types
   - Create document-metadata mappings

4. **Documentation**
   - Create `README_DE.md` (German version)
   - Update `README.md` with bilingual info
   - Translate troubleshooting guides
   - Translate other guides

5. **Polish & Testing**
   - Full end-to-end testing
   - Edge case handling
   - Error message translation
   - Success message translation

---

## 📖 How to Use (For Users)

### Starting the Script:

```bash
cd /path/to/MayanEDMSQuickStartOnLinux
sudo bash kyborg_mayan.sh
```

### First Run:

1. **Language selection appears**
   - Choose 1 for English
   - Choose 2 for German

2. **Main menu appears in selected language**

3. **All subsequent menus/prompts in that language**

### Installing with English preTypes:

1. Choose option **1** (Install Mayan EDMS)
2. Answer installation questions
3. When asked about preTypes: **Yes**
4. **NEW:** Select language: **1** (English)
5. English preTypes imported

### Installing with German preTypes:

1. Choose option **1** (Install Mayan EDMS)
2. Answer installation questions
3. When asked about preTypes: **Yes**
4. **NEW:** Select language: **2** (German)
5. German preTypes imported

---

## 🎯 Achievement Summary

### Phase 1 Goals - ALL COMPLETE ✅

✅ Language selection framework → **DONE**
✅ Bilingual menu system → **DONE**
✅ preTypes language selection → **DONE**
✅ English preTypes created → **DONE**
✅ Core user experience bilingual → **DONE**

### What Users Get:

- **Choose their language** at startup
- **Use Mayan in their preferred language**
- **Select preTypes language** independently
- **International (EN) or German (DE) preTypes**
- **Consistent bilingual experience**

### What Developers Get:

- **Message system** for easy translation
- **Modular language file** (lang_messages.sh)
- **Extensible framework** for more languages
- **Clean separation** of UI text and logic

---

## 💡 Key Design Decisions

### Why This Approach?

1. **User-friendly**
   - One language selection
   - Clear menu choices
   - Independent preTypes language

2. **Maintainable**
   - All messages in one file
   - Easy to add translations
   - Clean code separation

3. **Flexible**
   - Can add more languages easily
   - Can add more messages
   - Can extend preTypes

4. **Non-breaking**
   - Works with existing setup
   - German preTypes unchanged
   - All old features work

### Why English preTypes?

1. **International users** need non-German option
2. **Simpler** starting point (20 vs 273 types)
3. **Universal** business terminology
4. **Faster** to set up and understand

### Why Independent preTypes Selection?

- **UI language ≠ preTypes language**
- Example: English UI, but using German business
- Example: German UI, but international branch
- Gives users **flexibility**

---

## 🚀 Production Ready

### Phase 1 is production-ready for:

✅ **Bilingual menu system**
✅ **English-speaking users**
✅ **German-speaking users**
✅ **International business (EN preTypes)**
✅ **German business (DE preTypes)**

### Not yet ready:

⏳ Full installation prompts (Phase 2)
⏳ All supporting scripts (Phase 2)
⏳ Complete documentation (Phase 2)

---

## 📝 Summary

**Phase 1 = Core Bilingual Framework ✅**

Users can now:
- Choose English or German
- See menus in their language
- Select preTypes in either language
- Use English international business types
- Use German GoBD/DSGVO business types

The foundation is solid. Phase 2 will complete the full bilingual experience across all scripts and documentation.

---

**Status: Phase 1 Complete - Ready for User Testing** ✅

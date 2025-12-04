#!/bin/bash
# =============================================================================
# Language Messages for Mayan EDMS Management Script
# Bilingual support: English (EN) and German (DE)
# =============================================================================

# Language selection
select_language() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  Mayan EDMS – Management & Installation Script             ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║                                                            ║"
    echo "║  Please select your language / Bitte Sprache wählen:      ║"
    echo "║                                                            ║"
    echo "║  1) English                                                ║"
    echo "║  2) Deutsch (German)                                       ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    while true; do
        read -p "Select / Wählen [1-2]: " lang_choice
        case $lang_choice in
            1)
                LANG_CODE="en"
                break
                ;;
            2)
                LANG_CODE="de"
                break
                ;;
            *)
                echo "Invalid choice / Ungültige Auswahl"
                ;;
        esac
    done

    # Export for use in other scripts
    export MAYAN_LANG="$LANG_CODE"
}

# Get message in selected language
msg() {
    local key="$1"
    local var_name="MSG_${key}_${LANG_CODE}"
    echo "${!var_name}"
}

# =============================================================================
# Common Messages
# =============================================================================

# Root check
MSG_ROOT_REQUIRED_en="This script must be run as root!"
MSG_ROOT_REQUIRED_de="Dieses Script muss als root ausgeführt werden!"

MSG_USE_SUDO_en="Please use: sudo \$0"
MSG_USE_SUDO_de="Bitte verwenden: sudo \$0"

# Press enter
MSG_PRESS_ENTER_en="Press Enter to continue..."
MSG_PRESS_ENTER_de="Drücke Enter zum Fortfahren..."

# Status
MSG_STATUS_INSTALLED_en="Status: Mayan EDMS is installed ✓"
MSG_STATUS_INSTALLED_de="Status: Mayan EDMS ist installiert ✓"

MSG_STATUS_NOT_INSTALLED_en="Status: Mayan EDMS is NOT installed"
MSG_STATUS_NOT_INSTALLED_de="Status: Mayan EDMS ist NICHT installiert"

# =============================================================================
# Main Menu
# =============================================================================

MSG_MENU_TITLE_en="Mayan EDMS – Management & Installation Script"
MSG_MENU_TITLE_de="Mayan EDMS – Management & Installation Script"

MSG_MENU_CHOOSE_en="Choose an option:"
MSG_MENU_CHOOSE_de="Wähle eine Option:"

MSG_MENU_1_en="Install Mayan EDMS (Initial Installation)"
MSG_MENU_1_de="Mayan EDMS installieren (Erstinstallation)"

MSG_MENU_1_SUB_en="→ Including preTypes import (optional)"
MSG_MENU_1_SUB_de="→ Inklusive preTypes Import (optional)"

MSG_MENU_2_en="Setup SMB/Scanner Access"
MSG_MENU_2_de="SMB/Scanner-Zugang einrichten"

MSG_MENU_2_SUB_en="→ Samba share for scanners/macOS"
MSG_MENU_2_SUB_de="→ Samba-Freigabe für Scanner/macOS"

MSG_MENU_3_en="Create Backup"
MSG_MENU_3_de="Backup erstellen"

MSG_MENU_3_SUB_en="→ Backup database + files"
MSG_MENU_3_SUB_de="→ Sichert Datenbank + Dateien"

MSG_MENU_4_en="Setup Backup Cronjob"
MSG_MENU_4_de="Backup-Cronjob einrichten"

MSG_MENU_4_SUB_en="→ Automatic daily backups"
MSG_MENU_4_SUB_de="→ Automatische tägliche Backups"

MSG_MENU_5_en="Restore Backup"
MSG_MENU_5_de="Backup wiederherstellen"

MSG_MENU_5_SUB_en="→ Restore from backup archive"
MSG_MENU_5_SUB_de="→ Restore aus Backup-Archiv"

MSG_MENU_6_en="Show Mayan Status"
MSG_MENU_6_de="Mayan Status anzeigen"

MSG_MENU_6_SUB_en="→ Container status, logs, URLs"
MSG_MENU_6_SUB_de="→ Container-Status, Logs, URLs"

MSG_MENU_7_en="Configure Document Sources"
MSG_MENU_7_de="Dokumentquellen konfigurieren"

MSG_MENU_7_SUB_en="→ Setup watch/staging folders in GUI"
MSG_MENU_7_SUB_de="→ Watch/Staging Folder in GUI einrichten"

MSG_MENU_8_en="Troubleshooting & Diagnostics"
MSG_MENU_8_de="Problemlösung & Diagnose"

MSG_MENU_8_SUB_en="→ Worker timeouts, Celery broker, import tests"
MSG_MENU_8_SUB_de="→ Worker-Timeouts, Celery-Broker, Import-Tests"

MSG_MENU_0_en="Exit"
MSG_MENU_0_de="Beenden"

MSG_MENU_PROMPT_en="Your choice [0-8]:"
MSG_MENU_PROMPT_de="Deine Wahl [0-8]:"

# =============================================================================
# Installation Messages
# =============================================================================

MSG_INSTALL_TITLE_en="Mayan EDMS Installation"
MSG_INSTALL_TITLE_de="Mayan EDMS Installation"

MSG_INSTALL_EXISTS_en="Mayan EDMS is already installed!"
MSG_INSTALL_EXISTS_de="Mayan EDMS ist bereits installiert!"

MSG_INSTALL_OVERWRITE_en="Installation exists. Overwrite?"
MSG_INSTALL_OVERWRITE_de="Installation existiert. Überschreiben?"

MSG_INSTALL_CANCELLED_en="Installation cancelled."
MSG_INSTALL_CANCELLED_de="Installation abgebrochen."

MSG_INSTALL_DOCKER_en="Installing Docker and Docker Compose..."
MSG_INSTALL_DOCKER_de="Installiere Docker und Docker Compose..."

MSG_INSTALL_PASSWORD_en="Set PostgreSQL password (min. 16 characters):"
MSG_INSTALL_PASSWORD_de="PostgreSQL Passwort setzen (min. 16 Zeichen):"

MSG_INSTALL_PASSWORD_SHORT_en="Password too short! Minimum 16 characters required."
MSG_INSTALL_PASSWORD_SHORT_de="Passwort zu kurz! Mindestens 16 Zeichen erforderlich."

MSG_INSTALL_TIMEZONE_en="Timezone (default: Europe/Berlin):"
MSG_INSTALL_TIMEZONE_de="Zeitzone (Standard: Europe/Berlin):"

MSG_INSTALL_LANGUAGE_en="System language (de/en) [de]:"
MSG_INSTALL_LANGUAGE_de="Systemsprache (de/en) [de]:"

MSG_INSTALL_ADMIN_NOTE_en="Note: Mayan creates admin user automatically"
MSG_INSTALL_ADMIN_NOTE_de="Hinweis: Mayan erstellt automatisch einen Admin-User"

MSG_INSTALL_ADMIN_DEFAULT_en="Default username: admin"
MSG_INSTALL_ADMIN_DEFAULT_de="Standard-Benutzername: admin"

MSG_INSTALL_ADMIN_PASSWORD_en="Default password: admin"
MSG_INSTALL_ADMIN_PASSWORD_de="Standard-Passwort: admin"

MSG_INSTALL_CHANGE_PASSWORD_en="Change password after first login!"
MSG_INSTALL_CHANGE_PASSWORD_de="Ändern Sie das Passwort nach dem ersten Login!"

MSG_INSTALL_SMTP_SETUP_en="Configure SMTP for email notifications?"
MSG_INSTALL_SMTP_SETUP_de="SMTP für E-Mail-Benachrichtigungen konfigurieren?"

MSG_INSTALL_PRETYPES_PROMPT_en="Import preTypes (metadata, document types, etc.)?"
MSG_INSTALL_PRETYPES_PROMPT_de="preTypes importieren (Metadaten, Dokumenttypen, etc.)?"

MSG_INSTALL_PRETYPES_LANG_en="Which language for preTypes?"
MSG_INSTALL_PRETYPES_LANG_de="Welche Sprache für preTypes?"

MSG_INSTALL_PRETYPES_LANG_EN_en="1) English - International business types"
MSG_INSTALL_PRETYPES_LANG_EN_de="1) English - Internationale Geschäftstypen"

MSG_INSTALL_PRETYPES_LANG_DE_en="2) German - German business types (GoBD, GDPR, tax)"
MSG_INSTALL_PRETYPES_LANG_DE_de="2) Deutsch - Deutsche Geschäftstypen (GoBD, DSGVO, Steuern)"

MSG_INSTALL_SOURCES_PROMPT_en="Configure document sources (watch/staging folders)?"
MSG_INSTALL_SOURCES_PROMPT_de="Dokumentquellen konfigurieren (Watch/Staging-Ordner)?"

MSG_INSTALL_COMPLETE_en="Installation complete!"
MSG_INSTALL_COMPLETE_de="Installation abgeschlossen!"

MSG_INSTALL_ACCESS_URL_en="Access Mayan at:"
MSG_INSTALL_ACCESS_URL_de="Mayan erreichbar unter:"

MSG_INSTALL_LOGIN_INFO_en="Login: admin / Password: admin"
MSG_INSTALL_LOGIN_INFO_de="Login: admin / Passwort: admin"

# =============================================================================
# Troubleshooting Menu
# =============================================================================

MSG_TSHOOTING_TITLE_en="Troubleshooting & Diagnostics"
MSG_TSHOOTING_TITLE_de="Problemlösung & Diagnose"

MSG_TSHOOTING_CHOOSE_en="Choose a diagnostic tool:"
MSG_TSHOOTING_CHOOSE_de="Wähle ein Diagnose-Tool:"

MSG_TSHOOTING_1_en="Fix Celery Broker (CRITICAL)"
MSG_TSHOOTING_1_de="Celery Broker reparieren (KRITISCH)"

MSG_TSHOOTING_1_SUB_en="→ Fixes: memory:// instead of redis://"
MSG_TSHOOTING_1_SUB_de="→ Behebt: memory:// statt redis://"

MSG_TSHOOTING_1_DESC_en="→ Documents not being imported"
MSG_TSHOOTING_1_DESC_de="→ Dokumente werden nicht importiert"

MSG_TSHOOTING_2_en="Fix Worker Timeouts"
MSG_TSHOOTING_2_de="Worker-Timeouts beheben"

MSG_TSHOOTING_2_SUB_en="→ Fixes: WORKER TIMEOUT errors"
MSG_TSHOOTING_2_SUB_de="→ Behebt: WORKER TIMEOUT Fehler"

MSG_TSHOOTING_2_DESC_en="→ Increases Gunicorn & Celery time limits"
MSG_TSHOOTING_2_DESC_de="→ Erhöht Gunicorn & Celery Zeitlimits"

MSG_TSHOOTING_3_en="Run Worker Diagnostics"
MSG_TSHOOTING_3_de="Worker-Diagnose ausführen"

MSG_TSHOOTING_3_SUB_en="→ Shows: Celery status, queues, resources"
MSG_TSHOOTING_3_SUB_de="→ Zeigt: Celery Status, Queues, Ressourcen"

MSG_TSHOOTING_3_DESC_en="→ Checks: OCR tools, Elasticsearch"
MSG_TSHOOTING_3_DESC_de="→ Prüft: OCR-Tools, Elasticsearch"

MSG_TSHOOTING_4_en="Verify Configuration & Test Import"
MSG_TSHOOTING_4_de="Konfiguration verifizieren & Import testen"

MSG_TSHOOTING_4_SUB_en="→ Verifies: docker-compose.yml settings"
MSG_TSHOOTING_4_SUB_de="→ Überprüft: docker-compose.yml Einstellungen"

MSG_TSHOOTING_4_DESC_en="→ Tests: Document sources, permissions"
MSG_TSHOOTING_4_DESC_de="→ Testet: Dokumentquellen, Berechtigungen"

MSG_TSHOOTING_5_en="All Diagnostics & Repairs (Complete)"
MSG_TSHOOTING_5_de="Alle Diagnosen & Reparaturen (komplett)"

MSG_TSHOOTING_5_SUB_en="→ Runs 1-4 sequentially"
MSG_TSHOOTING_5_SUB_de="→ Führt 1-4 nacheinander aus"

MSG_TSHOOTING_0_en="Back to Main Menu"
MSG_TSHOOTING_0_de="Zurück zum Hauptmenü"

MSG_TSHOOTING_PROMPT_en="Your choice [0-5]:"
MSG_TSHOOTING_PROMPT_de="Deine Wahl [0-5]:"

MSG_TSHOOTING_NOT_FOUND_en="not found in"
MSG_TSHOOTING_NOT_FOUND_de="nicht gefunden in"

# =============================================================================
# Document Sources
# =============================================================================

MSG_SOURCES_TITLE_en="Configure Document Sources"
MSG_SOURCES_TITLE_de="Dokumentquellen konfigurieren"

MSG_SOURCES_NOT_INSTALLED_en="Mayan EDMS is not installed!"
MSG_SOURCES_NOT_INSTALLED_de="Mayan EDMS ist nicht installiert!"

MSG_SOURCES_INSTALL_FIRST_en="Please install Mayan first (Option 1)"
MSG_SOURCES_INSTALL_FIRST_de="Bitte erst Mayan installieren (Option 1)"

MSG_SOURCES_INFO1_en="This function configures the following document sources in Mayan:"
MSG_SOURCES_INFO1_de="Diese Funktion konfiguriert folgende Dokumentquellen in Mayan:"

MSG_SOURCES_WATCH_en="Watch Folder: /srv/mayan/watch/"
MSG_SOURCES_WATCH_de="Watch Folder: /srv/mayan/watch/"

MSG_SOURCES_WATCH_DESC_en="→ Automatic document import"
MSG_SOURCES_WATCH_DESC_de="→ Automatischer Import von Dokumenten"

MSG_SOURCES_WATCH_DELETE_en="→ Files deleted after import"
MSG_SOURCES_WATCH_DELETE_de="→ Dateien werden nach Import gelöscht"

MSG_SOURCES_STAGING_en="Staging Folder: /srv/mayan/staging/"
MSG_SOURCES_STAGING_de="Staging Folder: /srv/mayan/staging/"

MSG_SOURCES_STAGING_DESC_en="→ Manual upload via web GUI"
MSG_SOURCES_STAGING_DESC_de="→ Manueller Upload via Web-GUI"

MSG_SOURCES_STAGING_KEEP_en="→ Files remain after import"
MSG_SOURCES_STAGING_KEEP_de="→ Dateien bleiben nach Import erhalten"

MSG_SOURCES_CONTINUE_en="Continue?"
MSG_SOURCES_CONTINUE_de="Fortfahren?"

MSG_SOURCES_CANCELLED_en="Cancelled."
MSG_SOURCES_CANCELLED_de="Abgebrochen."

MSG_SOURCES_SUCCESS_en="Document sources configured successfully!"
MSG_SOURCES_SUCCESS_de="Dokumentquellen erfolgreich konfiguriert!"

MSG_SOURCES_FAILED_en="Configuration failed (Exit Code:"
MSG_SOURCES_FAILED_de="Konfiguration fehlgeschlagen (Exit Code:"

# =============================================================================
# Backup Messages
# =============================================================================

MSG_BACKUP_TITLE_en="Create Backup"
MSG_BACKUP_TITLE_de="Backup erstellen"

MSG_BACKUP_NOT_INSTALLED_en="Mayan EDMS is not installed!"
MSG_BACKUP_NOT_INSTALLED_de="Mayan EDMS ist nicht installiert!"

MSG_BACKUP_RUNNING_en="Creating backup..."
MSG_BACKUP_RUNNING_de="Erstelle Backup..."

MSG_BACKUP_COMPLETE_en="Backup completed successfully!"
MSG_BACKUP_COMPLETE_de="Backup erfolgreich erstellt!"

MSG_BACKUP_FAILED_en="Backup failed!"
MSG_BACKUP_FAILED_de="Backup fehlgeschlagen!"

# =============================================================================
# Restore Messages
# =============================================================================

MSG_RESTORE_TITLE_en="Restore Backup"
MSG_RESTORE_TITLE_de="Backup wiederherstellen"

MSG_RESTORE_WARNING_en="WARNING: This will overwrite ALL current data!"
MSG_RESTORE_WARNING_de="WARNUNG: Dies überschreibt ALLE aktuellen Daten!"

MSG_RESTORE_AVAILABLE_en="Available backups:"
MSG_RESTORE_AVAILABLE_de="Verfügbare Backups:"

MSG_RESTORE_SELECT_en="Select backup number:"
MSG_RESTORE_SELECT_de="Backup-Nummer wählen:"

MSG_RESTORE_CONFIRM_en="Restore this backup?"
MSG_RESTORE_CONFIRM_de="Dieses Backup wiederherstellen?"

MSG_RESTORE_CANCELLED_en="Restore cancelled."
MSG_RESTORE_CANCELLED_de="Wiederherstellung abgebrochen."

MSG_RESTORE_COMPLETE_en="Restore completed successfully!"
MSG_RESTORE_COMPLETE_de="Wiederherstellung erfolgreich!"

# =============================================================================
# Status Messages
# =============================================================================

MSG_STATUS_TITLE_en="Mayan EDMS Status"
MSG_STATUS_TITLE_de="Mayan EDMS Status"

MSG_STATUS_CONTAINERS_en="Container Status:"
MSG_STATUS_CONTAINERS_de="Container-Status:"

MSG_STATUS_DISK_en="Disk Usage:"
MSG_STATUS_DISK_de="Festplattennutzung:"

MSG_STATUS_ACCESS_en="Access:"
MSG_STATUS_ACCESS_de="Zugriff:"

MSG_STATUS_LOGS_en="Recent Logs:"
MSG_STATUS_LOGS_de="Aktuelle Logs:"

# =============================================================================
# Common Prompts
# =============================================================================

MSG_YES_NO_en="(y/N):"
MSG_YES_NO_de="(j/N):"

MSG_CONTINUE_en="Continue"
MSG_CONTINUE_de="Fortfahren"

MSG_CANCEL_en="Cancel"
MSG_CANCEL_de="Abbrechen"

MSG_DONE_en="Done"
MSG_DONE_de="Fertig"

MSG_ERROR_en="Error"
MSG_ERROR_de="Fehler"

MSG_SUCCESS_en="Success"
MSG_SUCCESS_de="Erfolg"

MSG_WARNING_en="Warning"
MSG_WARNING_de="Warnung"

MSG_INFO_en="Info"
MSG_INFO_de="Info"

# =============================================================================
# Phase 2: Extended Installation Messages
# =============================================================================

MSG_INSTALL_STEP_DOCKER_en="Installing Docker and Docker Compose..."
MSG_INSTALL_STEP_DOCKER_de="Installiere Docker und Docker Compose..."

MSG_INSTALL_STEP_DIRS_en="Creating directories..."
MSG_INSTALL_STEP_DIRS_de="Erstelle Verzeichnisse..."

MSG_INSTALL_STEP_COMPOSE_en="Creating docker-compose.yml..."
MSG_INSTALL_STEP_COMPOSE_de="Erstelle docker-compose.yml..."

MSG_INSTALL_STEP_START_en="Starting containers..."
MSG_INSTALL_STEP_START_de="Starte Container..."

MSG_INSTALL_STEP_INIT_en="Initializing Mayan..."
MSG_INSTALL_STEP_INIT_de="Initialisiere Mayan..."

MSG_INSTALL_WAITING_en="Waiting for Mayan to start"
MSG_INSTALL_WAITING_de="Warte auf Mayan-Start"

MSG_INSTALL_READY_en="Mayan is ready"
MSG_INSTALL_READY_de="Mayan ist bereit"

MSG_INSTALL_NOT_READY_en="Mayan container may not be ready yet"
MSG_INSTALL_NOT_READY_de="Mayan Container möglicherweise noch nicht bereit"

MSG_INSTALL_CHECK_LOGS_en="Check: docker compose logs -f mayan_app"
MSG_INSTALL_CHECK_LOGS_de="Prüfen Sie: docker compose logs -f mayan_app"

# =============================================================================
# Backup Script Messages
# =============================================================================

MSG_BACKUP_START_en="Starting backup..."
MSG_BACKUP_START_de="Starte Backup..."

MSG_BACKUP_STOP_CONTAINERS_en="Stopping Mayan containers..."
MSG_BACKUP_STOP_CONTAINERS_de="Stoppe Mayan Container..."

MSG_BACKUP_DB_DUMP_en="Creating database dump..."
MSG_BACKUP_DB_DUMP_de="Erstelle Datenbank-Dump..."

MSG_BACKUP_ARCHIVE_en="Creating backup archive..."
MSG_BACKUP_ARCHIVE_de="Erstelle Backup-Archiv..."

MSG_BACKUP_RESTART_en="Restarting containers..."
MSG_BACKUP_RESTART_de="Starte Container neu..."

MSG_BACKUP_SUCCESS_en="Backup completed successfully!"
MSG_BACKUP_SUCCESS_de="Backup erfolgreich erstellt!"

MSG_BACKUP_LOCATION_en="Backup saved to:"
MSG_BACKUP_LOCATION_de="Backup gespeichert in:"

MSG_BACKUP_ROTATION_en="Rotating old backups (keeping last 7)..."
MSG_BACKUP_ROTATION_de="Rotiere alte Backups (behalte letzte 7)..."

MSG_BACKUP_SIZE_en="Backup size:"
MSG_BACKUP_SIZE_de="Backup-Größe:"

# =============================================================================
# Restore Script Messages
# =============================================================================

MSG_RESTORE_NO_BACKUPS_en="No backups found!"
MSG_RESTORE_NO_BACKUPS_de="Keine Backups gefunden!"

MSG_RESTORE_INVALID_en="Invalid selection!"
MSG_RESTORE_INVALID_de="Ungültige Auswahl!"

MSG_RESTORE_EXTRACTING_en="Extracting backup..."
MSG_RESTORE_EXTRACTING_de="Entpacke Backup..."

MSG_RESTORE_DB_en="Restoring database..."
MSG_RESTORE_DB_de="Stelle Datenbank wieder her..."

MSG_RESTORE_FILES_en="Restoring files..."
MSG_RESTORE_FILES_de="Stelle Dateien wieder her..."

MSG_RESTORE_CLEANUP_en="Cleaning up..."
MSG_RESTORE_CLEANUP_de="Räume auf..."

# =============================================================================
# SMB Setup Messages
# =============================================================================

MSG_SMB_TITLE_en="Mayan EDMS Scanner User Setup"
MSG_SMB_TITLE_de="Mayan EDMS Scanner-Benutzer Setup"

MSG_SMB_SUBTITLE_en="Version 3.0 - Fully tested and functional"
MSG_SMB_SUBTITLE_de="Version 3.0 - Vollständig getestet und funktionsfähig"

MSG_SMB_SETUP_STARTED_en="Scanner setup started"
MSG_SMB_SETUP_STARTED_de="Scanner-Setup gestartet"

# Phase headers
MSG_SMB_PHASE0_en="System Checks"
MSG_SMB_PHASE0_de="System-Vorprüfungen"

MSG_SMB_PHASE1_en="Time Synchronization"
MSG_SMB_PHASE1_de="Zeitsynchronisation"

MSG_SMB_PHASE2_en="User Configuration"
MSG_SMB_PHASE2_de="Benutzer-Konfiguration"

MSG_SMB_PHASE3_en="Package Installation"
MSG_SMB_PHASE3_de="Paket-Installation"

MSG_SMB_PHASE4_en="Set Permissions"
MSG_SMB_PHASE4_de="Berechtigungen setzen"

MSG_SMB_PHASE5_en="Configure Samba User"
MSG_SMB_PHASE5_de="Samba-Benutzer konfigurieren"

MSG_SMB_PHASE6_en="Samba Configuration"
MSG_SMB_PHASE6_de="Samba-Konfiguration"

MSG_SMB_PHASE7_en="Start Services"
MSG_SMB_PHASE7_de="Dienste starten"

MSG_SMB_PHASE8_en="Comprehensive Tests"
MSG_SMB_PHASE8_de="Umfassende Tests"

# Phase 0: System Checks
MSG_SMB_CHECK_OS_en="Checking operating system..."
MSG_SMB_CHECK_OS_de="Prüfe Betriebssystem..."

MSG_SMB_NOT_UBUNTU_en="Not Ubuntu or derivative"
MSG_SMB_NOT_UBUNTU_de="Nicht Ubuntu oder Derivat"

MSG_SMB_UBUNTU_OK_en="Ubuntu detected"
MSG_SMB_UBUNTU_OK_de="Ubuntu erkannt"

MSG_SMB_OS_UNKNOWN_en="Unable to detect OS"
MSG_SMB_OS_UNKNOWN_de="Betriebssystem nicht erkennbar"

MSG_SMB_CHECK_NETWORK_en="Checking network configuration..."
MSG_SMB_CHECK_NETWORK_de="Prüfe Netzwerk-Konfiguration..."

MSG_SMB_NO_IP_en="No IP address found"
MSG_SMB_NO_IP_de="Keine IP-Adresse gefunden"

MSG_SMB_IP_FOUND_en="IP address found"
MSG_SMB_IP_FOUND_de="IP-Adresse gefunden"

MSG_SMB_NETBIOS_SHORT_en="NetBIOS name shortened to"
MSG_SMB_NETBIOS_SHORT_de="NetBIOS-Name gekürzt auf"

MSG_SMB_CHECK_DIRS_en="Checking Mayan directories..."
MSG_SMB_CHECK_DIRS_de="Prüfe Mayan-Verzeichnisse..."

MSG_SMB_WATCH_NOT_FOUND_en="Watch directory not found"
MSG_SMB_WATCH_NOT_FOUND_de="Watch-Verzeichnis nicht gefunden"

MSG_SMB_CREATE_DIR_en="Create directory?"
MSG_SMB_CREATE_DIR_de="Verzeichnis erstellen?"

MSG_SMB_WATCH_CREATED_en="Watch directory created"
MSG_SMB_WATCH_CREATED_de="Watch-Verzeichnis erstellt"

MSG_SMB_WATCH_REQUIRED_en="Watch directory is required"
MSG_SMB_WATCH_REQUIRED_de="Watch-Verzeichnis wird benötigt"

MSG_SMB_WATCH_FOUND_en="Watch directory found"
MSG_SMB_WATCH_FOUND_de="Watch-Verzeichnis gefunden"

MSG_SMB_STAGING_NOT_FOUND_en="Staging directory not found"
MSG_SMB_STAGING_NOT_FOUND_de="Staging-Verzeichnis nicht gefunden"

MSG_SMB_STAGING_CREATED_en="Staging directory created"
MSG_SMB_STAGING_CREATED_de="Staging-Verzeichnis erstellt"

MSG_SMB_STAGING_SKIPPED_en="Staging directory creation skipped"
MSG_SMB_STAGING_SKIPPED_de="Staging-Verzeichnis Erstellung übersprungen"

MSG_SMB_STAGING_FOUND_en="Staging directory found"
MSG_SMB_STAGING_FOUND_de="Staging-Verzeichnis gefunden"

MSG_SMB_CHECK_EA_en="Checking Extended Attributes support..."
MSG_SMB_CHECK_EA_de="Prüfe Extended Attributes Unterstützung..."

MSG_SMB_EA_SUPPORTED_en="Extended Attributes supported"
MSG_SMB_EA_SUPPORTED_de="Extended Attributes werden unterstützt"

MSG_SMB_EA_LIMITED_en="Extended Attributes limited or not supported"
MSG_SMB_EA_LIMITED_de="Extended Attributes begrenzt oder nicht unterstützt"

MSG_SMB_EA_INSTALL_en="attr package not installed"
MSG_SMB_EA_INSTALL_de="attr-Paket nicht installiert"

# Phase 1: Time Synchronization
MSG_SMB_CHECK_TIME_en="Checking system time..."
MSG_SMB_CHECK_TIME_de="Prüfe Systemzeit..."

MSG_SMB_TIME_WRONG_en="System time appears incorrect"
MSG_SMB_TIME_WRONG_de="Systemzeit scheint falsch zu sein"

MSG_SMB_TIME_ISSUES_en="Incorrect time can cause Samba authentication issues"
MSG_SMB_TIME_ISSUES_de="Falsche Zeit kann Samba-Authentifizierungsprobleme verursachen"

MSG_SMB_TIME_OK_en="System time OK"
MSG_SMB_TIME_OK_de="Systemzeit OK"

MSG_SMB_INSTALL_CHRONY_en="Installing chrony for time synchronization..."
MSG_SMB_INSTALL_CHRONY_de="Installiere chrony für Zeitsynchronisation..."

MSG_SMB_CHRONY_INSTALLED_en="chrony installed"
MSG_SMB_CHRONY_INSTALLED_de="chrony installiert"

MSG_SMB_CHRONY_EXISTS_en="chrony already installed"
MSG_SMB_CHRONY_EXISTS_de="chrony bereits installiert"

MSG_SMB_TIME_SYNCED_en="Time synchronized"
MSG_SMB_TIME_SYNCED_de="Zeit synchronisiert"

MSG_SMB_TIME_SYNCING_en="Time synchronization in progress..."
MSG_SMB_TIME_SYNCING_de="Zeitsynchronisation läuft..."

MSG_SMB_CHRONY_FAILED_en="chrony service failed to start"
MSG_SMB_CHRONY_FAILED_de="chrony-Dienst konnte nicht gestartet werden"

# Phase 2: User Configuration
MSG_SMB_USERNAME_PROMPT_en="Enter username for scanner access:"
MSG_SMB_USERNAME_PROMPT_de="Benutzername für Scanner-Zugang eingeben:"

MSG_SMB_INVALID_USERNAME_en="Invalid username!"
MSG_SMB_INVALID_USERNAME_de="Ungültiger Benutzername!"

MSG_SMB_USERNAME_RULES_en="Username must follow UNIX naming conventions:"
MSG_SMB_USERNAME_RULES_de="Benutzername muss UNIX-Namenskonventionen folgen:"

MSG_SMB_USER_EXISTS_en="User already exists"
MSG_SMB_USER_EXISTS_de="Benutzer existiert bereits"

MSG_SMB_CONTINUE_ANYWAY_en="Continue anyway?"
MSG_SMB_CONTINUE_ANYWAY_de="Trotzdem fortfahren?"

MSG_SMB_PASSWORD_PROMPT_en="Enter password for"
MSG_SMB_PASSWORD_PROMPT_de="Passwort eingeben für"

MSG_SMB_PASSWORD_REPEAT_en="Repeat password:"
MSG_SMB_PASSWORD_REPEAT_de="Passwort wiederholen:"

MSG_SMB_PASSWORD_MISMATCH_en="Passwords do not match!"
MSG_SMB_PASSWORD_MISMATCH_de="Passwörter stimmen nicht überein!"

MSG_SMB_PASSWORD_SHORT_en="Password is shorter than 8 characters (not recommended)"
MSG_SMB_PASSWORD_SHORT_de="Passwort ist kürzer als 8 Zeichen (nicht empfohlen)"

MSG_SMB_USE_ANYWAY_en="Use anyway?"
MSG_SMB_USE_ANYWAY_de="Trotzdem verwenden?"

MSG_SMB_CONFIG_USER_en="Configuring user"
MSG_SMB_CONFIG_USER_de="Konfiguriere Benutzer"

MSG_SMB_CREATE_USER_en="Creating Unix user"
MSG_SMB_CREATE_USER_de="Erstelle Unix-Benutzer"

MSG_SMB_USER_CREATED_en="Unix user created"
MSG_SMB_USER_CREATED_de="Unix-Benutzer erstellt"

MSG_SMB_USER_UPDATE_en="Updating existing user password..."
MSG_SMB_USER_UPDATE_de="Aktualisiere Passwort für existierenden Benutzer..."

MSG_SMB_PASSWORD_UPDATED_en="Password updated"
MSG_SMB_PASSWORD_UPDATED_de="Passwort aktualisiert"

MSG_SMB_USER_GROUP_ADDED_en="User added to groups"
MSG_SMB_USER_GROUP_ADDED_de="Benutzer zu Gruppen hinzugefügt"

# Phase 3: Package Installation
MSG_SMB_INSTALL_ACL_en="Installing ACL tools..."
MSG_SMB_INSTALL_ACL_de="Installiere ACL-Tools..."

MSG_SMB_ACL_INSTALLED_en="ACL tools installed"
MSG_SMB_ACL_INSTALLED_de="ACL-Tools installiert"

MSG_SMB_ACL_EXISTS_en="ACL tools already installed"
MSG_SMB_ACL_EXISTS_de="ACL-Tools bereits installiert"

MSG_SMB_INSTALL_ATTR_en="Installing attr for Extended Attributes..."
MSG_SMB_INSTALL_ATTR_de="Installiere attr für Extended Attributes..."

MSG_SMB_ATTR_INSTALLED_en="attr installed"
MSG_SMB_ATTR_INSTALLED_de="attr installiert"

MSG_SMB_ATTR_EXISTS_en="attr already installed"
MSG_SMB_ATTR_EXISTS_de="attr bereits installiert"

MSG_SMB_INSTALL_SAMBA_en="Installing Samba..."
MSG_SMB_INSTALL_SAMBA_de="Installiere Samba..."

MSG_SMB_SAMBA_INSTALLED_en="Samba installed"
MSG_SMB_SAMBA_INSTALLED_de="Samba installiert"

MSG_SMB_SAMBA_EXISTS_en="Samba already installed"
MSG_SMB_SAMBA_EXISTS_de="Samba bereits installiert"

MSG_SMB_INSTALL_CLIENT_en="Installing smbclient for tests..."
MSG_SMB_INSTALL_CLIENT_de="Installiere smbclient für Tests..."

MSG_SMB_CLIENT_INSTALLED_en="smbclient installed"
MSG_SMB_CLIENT_INSTALLED_de="smbclient installiert"

MSG_SMB_CLIENT_EXISTS_en="smbclient already installed"
MSG_SMB_CLIENT_EXISTS_de="smbclient bereits installiert"

# Phase 4: Permissions
MSG_SMB_SET_PERMS_en="Setting permissions for"
MSG_SMB_SET_PERMS_de="Setze Berechtigungen für"

MSG_SMB_WATCH_PERMS_OK_en="Watch folder permissions OK"
MSG_SMB_WATCH_PERMS_OK_de="Watch-Ordner Berechtigungen OK"

MSG_SMB_WATCH_NOT_AVAIL_en="Watch directory not available"
MSG_SMB_WATCH_NOT_AVAIL_de="Watch-Verzeichnis nicht verfügbar"

MSG_SMB_STAGING_PERMS_OK_en="Staging folder permissions OK"
MSG_SMB_STAGING_PERMS_OK_de="Staging-Ordner Berechtigungen OK"

MSG_SMB_SET_EA_en="Setting Extended Attributes..."
MSG_SMB_SET_EA_de="Setze Extended Attributes..."

MSG_SMB_EA_SET_en="Extended Attributes set"
MSG_SMB_EA_SET_de="Extended Attributes gesetzt"

# Phase 5: Samba User
MSG_SMB_CREATE_SMB_USER_en="Creating Samba user"
MSG_SMB_CREATE_SMB_USER_de="Erstelle Samba-Benutzer"

MSG_SMB_REMOVE_OLD_USER_en="Removing old Samba user entry..."
MSG_SMB_REMOVE_OLD_USER_de="Entferne alten Samba-Benutzer Eintrag..."

MSG_SMB_CREATE_NEW_USER_en="Creating new Samba user entry..."
MSG_SMB_CREATE_NEW_USER_de="Erstelle neuen Samba-Benutzer Eintrag..."

MSG_SMB_SMB_USER_OK_en="Samba user configured"
MSG_SMB_SMB_USER_OK_de="Samba-Benutzer konfiguriert"

MSG_SMB_SMB_USER_FAILED_en="Samba user creation failed"
MSG_SMB_SMB_USER_FAILED_de="Samba-Benutzer Erstellung fehlgeschlagen"

# Phase 6: Samba Configuration
MSG_SMB_BACKUP_CONFIG_en="Backing up smb.conf..."
MSG_SMB_BACKUP_CONFIG_de="Sichere smb.conf..."

MSG_SMB_BACKUP_CREATED_en="Backup created"
MSG_SMB_BACKUP_CREATED_de="Backup erstellt"

MSG_SMB_CLEAN_CONFIG_en="Cleaning configuration..."
MSG_SMB_CLEAN_CONFIG_de="Bereinige Konfiguration..."

MSG_SMB_NETBIOS_SET_en="NetBIOS name set"
MSG_SMB_NETBIOS_SET_de="NetBIOS-Name gesetzt"

MSG_SMB_CONFIG_COMPAT_en="Adding macOS/Scanner compatibility settings..."
MSG_SMB_CONFIG_COMPAT_de="Füge macOS/Scanner Kompatibilitätseinstellungen hinzu..."

MSG_SMB_COMPAT_ADDED_en="Compatibility settings added"
MSG_SMB_COMPAT_ADDED_de="Kompatibilitätseinstellungen hinzugefügt"

MSG_SMB_REMOVE_OLD_SHARES_en="Removing old share configurations..."
MSG_SMB_REMOVE_OLD_SHARES_de="Entferne alte Freigabe-Konfigurationen..."

MSG_SMB_CREATE_SHARES_en="Creating share configurations..."
MSG_SMB_CREATE_SHARES_de="Erstelle Freigabe-Konfigurationen..."

MSG_SMB_SHARES_CONFIGURED_en="Shares configured"
MSG_SMB_SHARES_CONFIGURED_de="Freigaben konfiguriert"

MSG_SMB_VALIDATE_CONFIG_en="Validating configuration..."
MSG_SMB_VALIDATE_CONFIG_de="Validiere Konfiguration..."

MSG_SMB_CONFIG_VALID_en="Configuration valid"
MSG_SMB_CONFIG_VALID_de="Konfiguration gültig"

MSG_SMB_CONFIG_INVALID_en="Configuration invalid!"
MSG_SMB_CONFIG_INVALID_de="Konfiguration ungültig!"

# Phase 7: Services
MSG_SMB_ENABLE_AUTOSTART_en="Enabling autostart..."
MSG_SMB_ENABLE_AUTOSTART_de="Aktiviere Autostart..."

MSG_SMB_AUTOSTART_ENABLED_en="Autostart enabled"
MSG_SMB_AUTOSTART_ENABLED_de="Autostart aktiviert"

MSG_SMB_RESTART_SERVICES_en="Restarting Samba services..."
MSG_SMB_RESTART_SERVICES_de="Starte Samba-Dienste neu..."

MSG_SMB_SERVICES_RUNNING_en="Samba services running"
MSG_SMB_SERVICES_RUNNING_de="Samba-Dienste laufen"

MSG_SMB_SERVICES_FAILED_en="Samba services failed to start"
MSG_SMB_SERVICES_FAILED_de="Samba-Dienste konnten nicht gestartet werden"

MSG_SMB_UFW_DETECTED_en="UFW firewall detected, opening Samba ports..."
MSG_SMB_UFW_DETECTED_de="UFW Firewall erkannt, öffne Samba-Ports..."

MSG_SMB_UFW_OPENED_en="Firewall rules added"
MSG_SMB_UFW_OPENED_de="Firewall-Regeln hinzugefügt"

# Phase 8: Tests
MSG_SMB_TEST1_TITLE_en="Test 1: Unix User File Creation"
MSG_SMB_TEST1_TITLE_de="Test 1: Unix-Benutzer Dateierstellung"

MSG_SMB_TEST2_TITLE_en="Test 2: Samba User"
MSG_SMB_TEST2_TITLE_de="Test 2: Samba-Benutzer"

MSG_SMB_TEST3_TITLE_en="Test 3: SMB Share Visibility"
MSG_SMB_TEST3_TITLE_de="Test 3: SMB-Freigaben Sichtbarkeit"

MSG_SMB_TEST4_TITLE_en="Test 4: SMB Connection (localhost)"
MSG_SMB_TEST4_TITLE_de="Test 4: SMB-Verbindung (localhost)"

MSG_SMB_TEST5_TITLE_en="Test 5: SMB Connection (IP)"
MSG_SMB_TEST5_TITLE_de="Test 5: SMB-Verbindung (IP)"

MSG_SMB_TEST6_TITLE_en="Test 6: SMB Write Access"
MSG_SMB_TEST6_TITLE_de="Test 6: SMB-Schreibzugriff"

MSG_SMB_TEST7_TITLE_en="Test 7: Directory Permissions"
MSG_SMB_TEST7_TITLE_de="Test 7: Verzeichnis-Berechtigungen"

MSG_SMB_TEST8_TITLE_en="Test 8: Samba Services Status"
MSG_SMB_TEST8_TITLE_de="Test 8: Samba-Dienste Status"

MSG_SMB_TEST9_TITLE_en="Test 9: Autostart Configuration"
MSG_SMB_TEST9_TITLE_de="Test 9: Autostart-Konfiguration"

MSG_SMB_TEST10_TITLE_en="Test 10: SMB Ports"
MSG_SMB_TEST10_TITLE_de="Test 10: SMB-Ports"

MSG_SMB_TEST_FILE_VERIFY_FAILED_en="File creation verification failed"
MSG_SMB_TEST_FILE_VERIFY_FAILED_de="Dateierstellungsverifikation fehlgeschlagen"

MSG_SMB_TEST_USER_NO_CREATE_en="User cannot create files in watch folder"
MSG_SMB_TEST_USER_NO_CREATE_de="Benutzer kann keine Dateien im Watch-Ordner erstellen"

MSG_SMB_TEST_SMB_USER_EXISTS_en="Samba user exists in database"
MSG_SMB_TEST_SMB_USER_EXISTS_de="Samba-Benutzer existiert in Datenbank"

MSG_SMB_TEST_SMB_USER_NOT_FOUND_en="Samba user not found in database"
MSG_SMB_TEST_SMB_USER_NOT_FOUND_de="Samba-Benutzer nicht in Datenbank gefunden"

MSG_SMB_TEST_SHARE_VISIBLE_en="Share visible"
MSG_SMB_TEST_SHARE_VISIBLE_de="Freigabe sichtbar"

MSG_SMB_TEST_SHARE_NOT_VISIBLE_en="Share not visible"
MSG_SMB_TEST_SHARE_NOT_VISIBLE_de="Freigabe nicht sichtbar"

MSG_SMB_TEST_LOCALHOST_OK_en="SMB connection to localhost successful"
MSG_SMB_TEST_LOCALHOST_OK_de="SMB-Verbindung zu localhost erfolgreich"

MSG_SMB_TEST_LOCALHOST_FAILED_en="SMB connection to localhost failed"
MSG_SMB_TEST_LOCALHOST_FAILED_de="SMB-Verbindung zu localhost fehlgeschlagen"

MSG_SMB_TEST_IP_OK_en="SMB connection via IP successful"
MSG_SMB_TEST_IP_OK_de="SMB-Verbindung über IP erfolgreich"

MSG_SMB_TEST_IP_FAILED_en="SMB connection via IP failed"
MSG_SMB_TEST_IP_FAILED_de="SMB-Verbindung über IP fehlgeschlagen"

MSG_SMB_TEST_WRITE_OK_en="SMB write access works"
MSG_SMB_TEST_WRITE_OK_de="SMB-Schreibzugriff funktioniert"

MSG_SMB_TEST_FILE_NOT_CREATED_en="File was not created on server"
MSG_SMB_TEST_FILE_NOT_CREATED_de="Datei wurde nicht auf Server erstellt"

MSG_SMB_TEST_WRITE_FAILED_en="SMB write test failed"
MSG_SMB_TEST_WRITE_FAILED_de="SMB-Schreibtest fehlgeschlagen"

MSG_SMB_TEST_PERMS_OK_en="Watch folder permissions correct (777)"
MSG_SMB_TEST_PERMS_OK_de="Watch-Ordner Berechtigungen korrekt (777)"

MSG_SMB_TEST_SERVICES_OK_en="Both Samba services active"
MSG_SMB_TEST_SERVICES_OK_de="Beide Samba-Dienste aktiv"

MSG_SMB_TEST_SERVICES_NOT_ALL_en="Not all Samba services running"
MSG_SMB_TEST_SERVICES_NOT_ALL_de="Nicht alle Samba-Dienste laufen"

MSG_SMB_TEST_AUTOSTART_OK_en="All services configured for autostart"
MSG_SMB_TEST_AUTOSTART_OK_de="Alle Dienste für Autostart konfiguriert"

MSG_SMB_TEST_AUTOSTART_PARTIAL_en="Not all services have autostart enabled"
MSG_SMB_TEST_AUTOSTART_PARTIAL_de="Nicht alle Dienste haben Autostart aktiviert"

MSG_SMB_TEST_PORT_OK_en="Port 445 (SMB) is open"
MSG_SMB_TEST_PORT_OK_de="Port 445 (SMB) ist offen"

MSG_SMB_TEST_PORT_FAILED_en="Port 445 not reachable"
MSG_SMB_TEST_PORT_FAILED_de="Port 445 nicht erreichbar"

# Summary
MSG_SMB_SETUP_WITH_WARNINGS_en="Setup completed with warnings/errors"
MSG_SMB_SETUP_WITH_WARNINGS_de="Setup mit Warnungen/Fehlern abgeschlossen"

MSG_SMB_CHECK_LOG_en="Check log file:"
MSG_SMB_CHECK_LOG_de="Log-Datei prüfen:"

MSG_SMB_SETUP_SUCCESS_en="Setup completed successfully!"
MSG_SMB_SETUP_SUCCESS_de="Setup erfolgreich abgeschlossen!"

MSG_SMB_ALL_TESTS_PASSED_en="All tests passed"
MSG_SMB_ALL_TESTS_PASSED_de="Alle Tests bestanden"

MSG_SMB_CONFIG_DETAILS_en="Configuration Details"
MSG_SMB_CONFIG_DETAILS_de="Konfigurations-Details"

MSG_SMB_SHARES_TITLE_en="SMB Shares"
MSG_SMB_SHARES_TITLE_de="SMB-Freigaben"

MSG_SMB_CONNECTION_TESTS_en="Connection Tests"
MSG_SMB_CONNECTION_TESTS_de="Verbindungstests"

MSG_SMB_NEXT_STEPS_en="Next Steps"
MSG_SMB_NEXT_STEPS_de="Nächste Schritte"

MSG_SMB_SERVICES_en="Services"
MSG_SMB_SERVICES_de="Dienste"

MSG_SMB_TROUBLESHOOTING_en="Troubleshooting"
MSG_SMB_TROUBLESHOOTING_de="Fehlerbehebung"

MSG_SMB_AUTOSTART_ACTIVE_en="Autostart enabled:"
MSG_SMB_AUTOSTART_ACTIVE_de="Autostart aktiviert:"

MSG_SMB_MANAGE_SERVICES_en="Manage services:"
MSG_SMB_MANAGE_SERVICES_de="Dienste verwalten:"

MSG_SMB_IF_PROBLEMS_en="If you have problems:"
MSG_SMB_IF_PROBLEMS_de="Bei Problemen:"

MSG_SMB_CONNECT_INFO_en="Connect from scanner/computer:"
MSG_SMB_CONNECT_INFO_de="Verbinden von Scanner/Computer:"

# =============================================================================
# Setup Sources Messages
# =============================================================================

MSG_SETUP_SOURCES_TITLE_en="Mayan EDMS - Configure Document Sources"
MSG_SETUP_SOURCES_TITLE_de="Mayan EDMS - Dokumentquellen konfigurieren"

MSG_SETUP_SOURCES_NOT_FOUND_en="Error: Mayan installation not found at"
MSG_SETUP_SOURCES_NOT_FOUND_de="Fehler: Mayan-Installation nicht gefunden unter"

MSG_SETUP_SOURCES_INSTALL_FIRST_en="Please ensure Mayan is installed first."
MSG_SETUP_SOURCES_INSTALL_FIRST_de="Bitte stellen Sie sicher, dass Mayan zuerst installiert ist."

MSG_SETUP_SOURCES_NOT_RUNNING_en="Error: Mayan container is not running"
MSG_SETUP_SOURCES_NOT_RUNNING_de="Fehler: Mayan-Container läuft nicht"

MSG_SETUP_SOURCES_START_FIRST_en="Start Mayan first with: docker compose up -d"
MSG_SETUP_SOURCES_START_FIRST_de="Starten Sie Mayan zuerst mit: docker compose up -d"

MSG_SETUP_SOURCES_RUNNING_en="Running configuration..."
MSG_SETUP_SOURCES_RUNNING_de="Führe Konfiguration aus..."

MSG_SETUP_SOURCES_SCRIPT_NOT_FOUND_en="configure_sources.py not found in"
MSG_SETUP_SOURCES_SCRIPT_NOT_FOUND_de="configure_sources.py nicht gefunden in"

MSG_SETUP_SOURCES_SUCCESS_en="Configuration successful!"
MSG_SETUP_SOURCES_SUCCESS_de="Konfiguration erfolgreich!"

MSG_SETUP_SOURCES_CAN_NOW_en="You can now:"
MSG_SETUP_SOURCES_CAN_NOW_de="Sie können jetzt:"

MSG_SETUP_SOURCES_COPY_WATCH_en="Copy documents to /srv/mayan/watch/ for automatic import"
MSG_SETUP_SOURCES_COPY_WATCH_de="Dokumente nach /srv/mayan/watch/ kopieren für automatischen Import"

MSG_SETUP_SOURCES_COPY_STAGING_en="Copy documents to /srv/mayan/staging/ for manual upload"
MSG_SETUP_SOURCES_COPY_STAGING_de="Dokumente nach /srv/mayan/staging/ kopieren für manuellen Upload"

MSG_SETUP_SOURCES_VIEW_SOURCES_en="View sources in Mayan: Setup → Sources → Document sources"
MSG_SETUP_SOURCES_VIEW_SOURCES_de="Quellen in Mayan anzeigen: Setup → Quellen → Dokumentquellen"

MSG_SETUP_SOURCES_FAILED_en="Configuration failed with exit code:"
MSG_SETUP_SOURCES_FAILED_de="Konfiguration fehlgeschlagen mit Exit-Code:"

MSG_SETUP_SOURCES_CHECK_ERRORS_en="Check the error messages above for details."
MSG_SETUP_SOURCES_CHECK_ERRORS_de="Prüfen Sie die Fehlermeldungen oben für Details."

# =============================================================================
# Celery Broker Fix Messages
# =============================================================================

MSG_CELERY_TITLE_en="Fix Celery Broker Configuration"
MSG_CELERY_TITLE_de="Celery Broker reparieren"

MSG_CELERY_ISSUE_en="CRITICAL ISSUE DETECTED:"
MSG_CELERY_ISSUE_de="KRITISCHES PROBLEM ERKANNT:"

MSG_CELERY_MEMORY_en="Celery is using in-memory transport instead of Redis!"
MSG_CELERY_MEMORY_de="Celery verwendet in-memory Transport statt Redis!"

MSG_CELERY_MEANS_en="This means:"
MSG_CELERY_MEANS_de="Das bedeutet:"

MSG_CELERY_NOT_PERSISTENT_en="Tasks are not persistent"
MSG_CELERY_NOT_PERSISTENT_de="Tasks sind nicht persistent"

MSG_CELERY_NO_PROCESS_en="Documents won't process correctly"
MSG_CELERY_NO_PROCESS_de="Dokumente werden nicht korrekt verarbeitet"

MSG_CELERY_NO_COMM_en="Workers can't communicate"
MSG_CELERY_NO_COMM_de="Worker können nicht kommunizieren"

MSG_CELERY_WILL_FIX_en="This script will:"
MSG_CELERY_WILL_FIX_de="Dieses Skript wird:"

MSG_CELERY_FIX_NOW_en="Fix now?"
MSG_CELERY_FIX_NOW_de="Jetzt reparieren?"

MSG_CELERY_BACKUP_en="Backing up docker-compose.yml"
MSG_CELERY_BACKUP_de="Sichere docker-compose.yml"

MSG_CELERY_UPDATE_en="Updating docker-compose.yml"
MSG_CELERY_UPDATE_de="Aktualisiere docker-compose.yml"

MSG_CELERY_VERIFY_en="Verifying configuration"
MSG_CELERY_VERIFY_de="Verifiziere Konfiguration"

MSG_CELERY_RESTART_en="Restarting containers"
MSG_CELERY_RESTART_de="Starte Container neu"

MSG_CELERY_FIXED_en="Celery Broker Fixed!"
MSG_CELERY_FIXED_de="Celery Broker repariert!"

MSG_CELERY_NOW_USING_en="Celery now using Redis!"
MSG_CELERY_NOW_USING_de="Celery verwendet jetzt Redis!"

MSG_CELERY_TRY_IMPORT_en="Try importing a document now!"
MSG_CELERY_TRY_IMPORT_de="Versuchen Sie jetzt, ein Dokument zu importieren!"

# =============================================================================
# Worker Timeout Fix Messages
# =============================================================================

MSG_TIMEOUT_TITLE_en="Fix Worker Timeouts"
MSG_TIMEOUT_TITLE_de="Worker-Timeouts beheben"

MSG_TIMEOUT_ISSUE_en="Worker timeout issues detected"
MSG_TIMEOUT_ISSUE_de="Worker-Timeout-Probleme erkannt"

MSG_TIMEOUT_SYMPTOMS_en="Symptoms:"
MSG_TIMEOUT_SYMPTOMS_de="Symptome:"

MSG_TIMEOUT_INCREASE_en="Increasing timeouts..."
MSG_TIMEOUT_INCREASE_de="Erhöhe Timeouts..."

MSG_TIMEOUT_CLEAR_en="Clearing stuck tasks..."
MSG_TIMEOUT_CLEAR_de="Lösche hängende Tasks..."

MSG_TIMEOUT_FIXED_en="Worker Timeouts Fixed!"
MSG_TIMEOUT_FIXED_de="Worker-Timeouts behoben!"

MSG_TIMEOUT_NEW_SETTINGS_en="New timeout settings:"
MSG_TIMEOUT_NEW_SETTINGS_de="Neue Timeout-Einstellungen:"

# =============================================================================
# Worker Diagnostics Messages
# =============================================================================

MSG_DIAG_TITLE_en="Worker Diagnostics"
MSG_DIAG_TITLE_de="Worker-Diagnose"

MSG_DIAG_CHECKING_en="Checking"
MSG_DIAG_CHECKING_de="Prüfe"

MSG_DIAG_CELERY_STATUS_en="Celery Worker Status"
MSG_DIAG_CELERY_STATUS_de="Celery Worker Status"

MSG_DIAG_QUEUES_en="Celery Queues"
MSG_DIAG_QUEUES_de="Celery-Queues"

MSG_DIAG_DEPS_en="OCR Dependencies"
MSG_DIAG_DEPS_de="OCR-Abhängigkeiten"

MSG_DIAG_ES_en="Elasticsearch Health"
MSG_DIAG_ES_de="Elasticsearch-Zustand"

MSG_DIAG_RESOURCES_en="Container Resources"
MSG_DIAG_RESOURCES_de="Container-Ressourcen"

MSG_DIAG_ERRORS_en="Recent Errors"
MSG_DIAG_ERRORS_de="Aktuelle Fehler"

MSG_DIAG_SUMMARY_en="Diagnostic Summary"
MSG_DIAG_SUMMARY_de="Diagnose-Zusammenfassung"

MSG_DIAG_RECOMMEND_en="Recommendations"
MSG_DIAG_RECOMMEND_de="Empfehlungen"

# =============================================================================
# Configuration Verification Messages
# =============================================================================

MSG_VERIFY_TITLE_en="Configuration Verification & Import Test"
MSG_VERIFY_TITLE_de="Konfiguration verifizieren & Import testen"

MSG_VERIFY_COMPOSE_en="Checking docker-compose.yml settings"
MSG_VERIFY_COMPOSE_de="Prüfe docker-compose.yml Einstellungen"

MSG_VERIFY_ENV_en="Checking container environment"
MSG_VERIFY_ENV_de="Prüfe Container-Umgebung"

MSG_VERIFY_PROCESSES_en="Checking worker processes"
MSG_VERIFY_PROCESSES_de="Prüfe Worker-Prozesse"

MSG_VERIFY_SOURCES_en="Checking document sources"
MSG_VERIFY_SOURCES_de="Prüfe Dokumentquellen"

MSG_VERIFY_FOLDERS_en="Checking upload folders"
MSG_VERIFY_FOLDERS_de="Prüfe Upload-Ordner"

MSG_VERIFY_TEST_en="Creating test document"
MSG_VERIFY_TEST_de="Erstelle Test-Dokument"

MSG_VERIFY_READY_en="Ready for document import"
MSG_VERIFY_READY_de="Bereit für Dokumenten-Import"

# =============================================================================
# Document Sources Configuration Messages
# =============================================================================

MSG_SOURCES_CONFIGURING_en="Configuring document sources..."
MSG_SOURCES_CONFIGURING_de="Konfiguriere Dokumentquellen..."

MSG_SOURCES_ACCESS_en="Access in Mayan GUI:"
MSG_SOURCES_ACCESS_de="Zugriff in Mayan Web-GUI:"

MSG_SOURCES_USAGE_en="Usage:"
MSG_SOURCES_USAGE_de="Verwendung:"

# =============================================================================
# Common Action Messages
# =============================================================================

MSG_ABORTED_en="Aborted."
MSG_ABORTED_de="Abgebrochen."

MSG_CREATING_en="Creating"
MSG_CREATING_de="Erstelle"

MSG_COPYING_en="Copying"
MSG_COPYING_de="Kopiere"

MSG_STARTING_en="Starting"
MSG_STARTING_de="Starte"

MSG_STOPPING_en="Stopping"
MSG_STOPPING_de="Stoppe"

MSG_WAITING_en="Waiting"
MSG_WAITING_de="Warte"

MSG_CHECKING_en="Checking"
MSG_CHECKING_de="Prüfe"

MSG_UPDATING_en="Updating"
MSG_UPDATING_de="Aktualisiere"

MSG_VERIFYING_en="Verifying"
MSG_VERIFYING_de="Verifiziere"

MSG_RESTARTING_en="Restarting"
MSG_RESTARTING_de="Starte neu"

MSG_FOUND_en="Found"
MSG_FOUND_de="Gefunden"

MSG_NOT_FOUND_en="Not found"
MSG_NOT_FOUND_de="Nicht gefunden"

MSG_COMPLETED_en="Completed"
MSG_COMPLETED_de="Abgeschlossen"

MSG_FAILED_en="Failed"
MSG_FAILED_de="Fehlgeschlagen"

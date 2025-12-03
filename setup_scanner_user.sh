#!/bin/bash

# ============================================================================
# Mayan EDMS Scanner-Benutzer Setup - Version 3.0 FINAL
# Vollständig getestet und funktionsfähig
# ============================================================================

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Fehler-Tracking
ERRORS=0
WARNINGS=0

# Logging
LOG_FILE="/var/log/mayan_scanner_setup.log"

# Funktion: Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Funktion: Fehler-Handling
error() {
    echo -e "${RED}✗ FEHLER: $1${NC}" | tee -a "$LOG_FILE"
    ((ERRORS++))
}

# Funktion: Warnung
warning() {
    echo -e "${YELLOW}⚠ WARNUNG: $1${NC}" | tee -a "$LOG_FILE"
    ((WARNINGS++))
}

# Funktion: Erfolg
success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

# Funktion: Info
info() {
    echo -e "${BLUE}ℹ $1${NC}" | tee -a "$LOG_FILE"
}

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then 
    error "Bitte als root ausführen: sudo $0"
    exit 1
fi

clear
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Mayan EDMS Scanner Setup v3.0 FINAL${NC}"
echo -e "${GREEN}Mit vollständiger Fehlerkorrektur${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
log "=== Setup gestartet ==="

# ============================================================================
# PHASE 0: System-Vorprüfungen
# ============================================================================

echo -e "${MAGENTA}[PHASE 0] System-Vorprüfungen${NC}"
echo ""

# Prüfe Betriebssystem
info "Prüfe Betriebssystem..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID_LIKE" != *"ubuntu"* ]]; then
        warning "Nicht Ubuntu erkannt: $ID $VERSION_ID - Script könnte Anpassungen benötigen"
    else
        success "Ubuntu $VERSION_ID erkannt"
    fi
else
    warning "Betriebssystem nicht erkannt"
fi

# Prüfe Netzwerk-Konfiguration
info "Prüfe Netzwerk-Konfiguration..."
IP_ADDRS=$(hostname -I | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | grep -v '^127\.' | head -1)
if [ -z "$IP_ADDRS" ]; then
    error "Keine gültige IP-Adresse gefunden!"
    exit 1
else
    success "IP-Adresse gefunden: $IP_ADDRS"
fi

# Prüfe Hostname-Länge (NetBIOS Limit: 15 Zeichen)
HOSTNAME=$(hostname)
HOSTNAME_LENGTH=${#HOSTNAME}
if [ $HOSTNAME_LENGTH -gt 15 ]; then
    warning "Hostname '$HOSTNAME' ist zu lang für NetBIOS (${HOSTNAME_LENGTH} > 15 Zeichen)"
    NETBIOS_NAME="${HOSTNAME:0:15}"
    info "Verwende gekürzten NetBIOS-Namen: $NETBIOS_NAME"
else
    NETBIOS_NAME="$HOSTNAME"
    success "Hostname-Länge OK: $HOSTNAME_LENGTH Zeichen"
fi

# Prüfe Mayan-Verzeichnisse
info "Prüfe Mayan EDMS Verzeichnisse..."
MAYAN_BASE="/srv/mayan"
WATCH_DIR="$MAYAN_BASE/watch"
STAGING_DIR="$MAYAN_BASE/staging"

if [ ! -d "$WATCH_DIR" ]; then
    error "Watch-Verzeichnis nicht gefunden: $WATCH_DIR"
    read -p "Soll das Verzeichnis erstellt werden? (j/n): " CREATE_WATCH
    if [[ "$CREATE_WATCH" == "j" || "$CREATE_WATCH" == "J" ]]; then
        mkdir -p "$WATCH_DIR"
        success "Watch-Verzeichnis erstellt"
    else
        error "Abbruch: Watch-Verzeichnis erforderlich"
        exit 1
    fi
else
    success "Watch-Verzeichnis gefunden: $WATCH_DIR"
fi

if [ ! -d "$STAGING_DIR" ]; then
    warning "Staging-Verzeichnis nicht gefunden: $STAGING_DIR"
    read -p "Soll das Verzeichnis erstellt werden? (j/n): " CREATE_STAGING
    if [[ "$CREATE_STAGING" == "j" || "$CREATE_STAGING" == "J" ]]; then
        mkdir -p "$STAGING_DIR"
        success "Staging-Verzeichnis erstellt"
    else
        warning "Staging-Verzeichnis wird übersprungen"
    fi
else
    success "Staging-Verzeichnis gefunden: $STAGING_DIR"
fi

# Prüfe Extended Attributes Support
info "Prüfe Extended Attributes Support (für macOS)..."
if command -v setfattr &> /dev/null; then
    if setfattr -n user.test -v test "$WATCH_DIR" 2>/dev/null; then
        getfattr -n user.test "$WATCH_DIR" &>/dev/null && setfattr -x user.test "$WATCH_DIR" 2>/dev/null
        success "Extended Attributes werden unterstützt"
        EA_SUPPORT=true
    else
        warning "Extended Attributes nicht verfügbar - macOS-Support eingeschränkt"
        EA_SUPPORT=false
    fi
else
    warning "setfattr nicht installiert - wird nachinstalliert"
    EA_SUPPORT=false
fi

echo ""

# ============================================================================
# PHASE 1: Zeitsynchronisation
# ============================================================================

echo -e "${MAGENTA}[PHASE 1] Zeitsynchronisation${NC}"
echo ""

info "Prüfe Systemzeit..."
CURRENT_TIME=$(date +%s)
if [ $CURRENT_TIME -lt 1700000000 ]; then
    error "Systemzeit scheint falsch zu sein: $(date)"
    warning "Dies kann zu SSL/TLS und APT-Problemen führen"
else
    success "Systemzeit plausibel: $(date)"
fi

info "Installiere/Konfiguriere chrony für Zeitsynchronisation..."
if ! command -v chronyd &> /dev/null; then
    apt-get update -qq 2>&1 | tee -a "$LOG_FILE"
    apt-get install -y -qq chrony 2>&1 | tee -a "$LOG_FILE"
    success "Chrony installiert"
else
    success "Chrony bereits installiert"
fi

systemctl enable chrony &>/dev/null
systemctl start chrony &>/dev/null

sleep 3

if systemctl is-active --quiet chrony; then
    SYNC_STATUS=$(timedatectl status | grep "System clock synchronized" | awk '{print $4}')
    if [ "$SYNC_STATUS" = "yes" ]; then
        success "Systemzeit synchronisiert"
    else
        warning "Zeitsynchronisation läuft noch..."
    fi
else
    error "Chrony konnte nicht gestartet werden"
fi

echo ""

# ============================================================================
# PHASE 2: Benutzer-Konfiguration
# ============================================================================

echo -e "${MAGENTA}[PHASE 2] Benutzer-Konfiguration${NC}"
echo ""

# Benutzername abfragen mit Validierung
while true; do
    read -p "Benutzername für Scanner-Zugang: " USERNAME
    
    # UNIX-Namenskonventionen prüfen
    if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        error "Ungültiger Benutzername!"
        echo "Regeln:"
        echo "  - Nur Kleinbuchstaben, Zahlen, _ und -"
        echo "  - Muss mit Buchstabe oder _ beginnen"
        echo "  - Max. 32 Zeichen"
        echo ""
        continue
    fi
    
    # Prüfen ob Benutzer bereits existiert
    if id "$USERNAME" &>/dev/null; then
        warning "Benutzer '$USERNAME' existiert bereits!"
        read -p "Trotzdem fortfahren und SMB-Zugang einrichten? (j/n): " CONTINUE
        if [[ "$CONTINUE" != "j" && "$CONTINUE" != "J" ]]; then
            continue
        fi
        USER_EXISTS=true
    else
        USER_EXISTS=false
    fi
    
    break
done

# Passwort abfragen
while true; do
    read -s -p "Passwort für $USERNAME: " PASSWORD
    echo ""
    read -s -p "Passwort wiederholen: " PASSWORD2
    echo ""
    
    if [ "$PASSWORD" != "$PASSWORD2" ]; then
        error "Passwörter stimmen nicht überein!"
        continue
    fi
    
    if [ ${#PASSWORD} -lt 8 ]; then
        warning "Passwort ist kürzer als 8 Zeichen - empfohlen sind mindestens 8"
        read -p "Trotzdem verwenden? (j/n): " USE_SHORT
        if [[ "$USE_SHORT" != "j" && "$USE_SHORT" != "J" ]]; then
            continue
        fi
    fi
    
    break
done

echo ""
log "Benutzer '$USERNAME' wird konfiguriert"

# Unix-Benutzer anlegen/aktualisieren
if [ "$USER_EXISTS" = false ]; then
    info "Erstelle Unix-Benutzer '$USERNAME'..."
    useradd -m -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
    success "Unix-Benutzer erstellt"
else
    info "Unix-Benutzer existiert bereits, aktualisiere Passwort..."
    echo "$USERNAME:$PASSWORD" | chpasswd
    success "Passwort aktualisiert"
fi

# Zu Gruppen hinzufügen
usermod -a -G users "$USERNAME"
success "Benutzer zu Gruppe 'users' hinzugefügt"

echo ""

# ============================================================================
# PHASE 3: Paket-Installation
# ============================================================================

echo -e "${MAGENTA}[PHASE 3] Paket-Installation${NC}"
echo ""

# ACL-Tools
info "Installiere ACL-Tools..."
if ! command -v setfacl &> /dev/null; then
    apt-get update -qq 2>&1 | tee -a "$LOG_FILE"
    apt-get install -y -qq acl 2>&1 | tee -a "$LOG_FILE"
    success "ACL installiert"
else
    success "ACL bereits installiert"
fi

# attr für Extended Attributes
info "Installiere attr (für macOS-Kompatibilität)..."
if ! command -v setfattr &> /dev/null; then
    apt-get install -y -qq attr 2>&1 | tee -a "$LOG_FILE"
    success "attr installiert"
else
    success "attr bereits installiert"
fi

# Samba
info "Installiere Samba..."
if ! command -v smbd &> /dev/null; then
    apt-get install -y -qq samba samba-common-bin 2>&1 | tee -a "$LOG_FILE"
    success "Samba installiert"
else
    success "Samba bereits installiert"
fi

# smbclient für Tests
info "Installiere smbclient (für Tests)..."
if ! command -v smbclient &> /dev/null; then
    apt-get install -y -qq smbclient 2>&1 | tee -a "$LOG_FILE"
    success "smbclient installiert"
else
    success "smbclient bereits installiert"
fi

echo ""

# ============================================================================
# PHASE 4: Berechtigungen setzen (KORRIGIERT)
# ============================================================================

echo -e "${MAGENTA}[PHASE 4] Berechtigungen setzen${NC}"
echo ""

# KRITISCH: Berechtigungen müssen 777 sein für SMB-Schreibzugriff
if [ -d "$WATCH_DIR" ]; then
    info "Setze Berechtigungen für $WATCH_DIR..."
    
    # Owner setzen
    chown "$USERNAME:$USERNAME" "$WATCH_DIR"
    
    # Berechtigungen: 777 für volle Funktionalität
    chmod 777 "$WATCH_DIR"
    
    # ACLs setzen
    setfacl -R -m u:$USERNAME:rwx "$WATCH_DIR"
    setfacl -R -d -m u:$USERNAME:rwx "$WATCH_DIR"
    
    # Prüfe ob korrekt gesetzt
    PERMS=$(stat -c '%a' "$WATCH_DIR")
    if [ "$PERMS" = "777" ]; then
        success "Berechtigungen für watch-Ordner gesetzt (777)"
    else
        error "Berechtigungen konnten nicht korrekt gesetzt werden (ist: $PERMS, soll: 777)"
    fi
else
    error "Watch-Verzeichnis nicht verfügbar"
fi

# Staging-Folder (falls vorhanden)
if [ -d "$STAGING_DIR" ]; then
    info "Setze Berechtigungen für $STAGING_DIR..."
    
    chown "$USERNAME:$USERNAME" "$STAGING_DIR"
    chmod 777 "$STAGING_DIR"
    setfacl -R -m u:$USERNAME:rwx "$STAGING_DIR"
    setfacl -R -d -m u:$USERNAME:rwx "$STAGING_DIR"
    
    PERMS=$(stat -c '%a' "$STAGING_DIR")
    if [ "$PERMS" = "777" ]; then
        success "Berechtigungen für staging-Ordner gesetzt (777)"
    else
        warning "Staging-Berechtigungen: $PERMS (empfohlen: 777)"
    fi
fi

# Extended Attributes setzen (für macOS)
if [ "$EA_SUPPORT" = true ] || command -v setfattr &> /dev/null; then
    info "Setze Extended Attributes für macOS-Kompatibilität..."
    setfattr -n user.mayan_scanner -v "$USERNAME" "$WATCH_DIR" 2>/dev/null
    [ -d "$STAGING_DIR" ] && setfattr -n user.mayan_scanner -v "$USERNAME" "$STAGING_DIR" 2>/dev/null
    success "Extended Attributes gesetzt"
fi

echo ""

# ============================================================================
# PHASE 5: Samba-Benutzer konfigurieren
# ============================================================================

echo -e "${MAGENTA}[PHASE 5] Samba-Benutzer konfigurieren${NC}"
echo ""

info "Erstelle/Aktualisiere Samba-Benutzer '$USERNAME'..."

# Entferne alten Benutzer falls vorhanden (für saubere Neuinstallation)
if pdbedit -L 2>/dev/null | grep -q "^$USERNAME:"; then
    info "Entferne alten Samba-Benutzer..."
    smbpasswd -x "$USERNAME" 2>/dev/null
fi

# Erstelle Samba-Benutzer NEU
info "Erstelle neuen Samba-Benutzer..."
(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a -s "$USERNAME" 2>/dev/null

# Benutzer aktivieren
smbpasswd -e "$USERNAME" &>/dev/null

# Prüfe ob Benutzer jetzt existiert
if pdbedit -L 2>/dev/null | grep -q "^$USERNAME:"; then
    success "Samba-Benutzer '$USERNAME' konfiguriert"
    
    # Zeige Benutzer-Details (gekürzt)
    USER_INFO=$(pdbedit -L -v 2>/dev/null | grep -A 3 "Unix username:.*$USERNAME")
    log "Samba-Benutzer Details: $USER_INFO"
else
    error "Samba-Benutzer konnte nicht erstellt werden"
fi

echo ""

# ============================================================================
# PHASE 6: Samba-Konfiguration (VOLLSTÄNDIG KORRIGIERT)
# ============================================================================

echo -e "${MAGENTA}[PHASE 6] Samba-Konfiguration${NC}"
echo ""

SMB_CONF="/etc/samba/smb.conf"
BACKUP_CONF="${SMB_CONF}.backup.$(date +%Y%m%d_%H%M%S)"

info "Sichere bestehende Konfiguration..."
cp "$SMB_CONF" "$BACKUP_CONF"
success "Backup erstellt: $BACKUP_CONF"

# Prüfe ob [global] Sektion existiert
if ! grep -q "^\[global\]" "$SMB_CONF"; then
    error "[global] Sektion nicht in smb.conf gefunden!"
    exit 1
fi

# Bereinige Konfiguration
info "Bereinige Konfiguration..."
# Entferne Inline-Kommentare und fehlerhafte Zeilen
sed -i '/# ← NICHT/d' "$SMB_CONF"
sed -i '/^[[:space:]]*$/N;/^\n$/d' "$SMB_CONF"

# Entferne vfs objects aus [global] falls vorhanden
sed -i '/^\[global\]/,/^\[/{/^[[:space:]]*vfs objects/d}' "$SMB_CONF"
sed -i '/^\[global\]/,/^\[/{/^[[:space:]]*fruit:/d}' "$SMB_CONF"

# Setze NetBIOS Name korrekt
if ! grep -q "^[[:space:]]*netbios name" "$SMB_CONF"; then
    sed -i "/^\[global\]/a \   netbios name = $NETBIOS_NAME" "$SMB_CONF"
    success "NetBIOS-Name gesetzt: $NETBIOS_NAME"
elif grep -q "^[[:space:]]*netbios name.*${HOSTNAME}" "$SMB_CONF" && [ $HOSTNAME_LENGTH -gt 15 ]; then
    sed -i "s/netbios name.*/netbios name = $NETBIOS_NAME/" "$SMB_CONF"
    success "NetBIOS-Name gekürzt: $NETBIOS_NAME"
fi

# Füge Log-Level hinzu falls nicht vorhanden
if ! grep -q "^[[:space:]]*log level" "$SMB_CONF"; then
    sed -i '/^\[global\]/a \   log level = 2' "$SMB_CONF"
fi

# macOS/Brother-Kompatibilität in [global] (NUR Basis-Optionen)
info "Konfiguriere Basis-Kompatibilität..."
if ! grep -q "fruit:aapl" "$SMB_CONF"; then
    sed -i '/^\[global\]/a \
   # macOS and Scanner Compatibility\
   fruit:aapl = yes\
   \
   # SMB Protocol\
   server min protocol = SMB2\
   client min protocol = SMB2\
   \
   # Brother Scanner Auth\
   ntlm auth = ntlmv1-permitted\
   \
   # Extended Attributes\
   ea support = yes\
   store dos attributes = yes\
   \
   # Unix Extensions deaktivieren\
   unix extensions = no' "$SMB_CONF"
    success "Basis-Kompatibilität hinzugefügt"
fi

# Entferne alte Freigaben-Sektionen komplett
info "Entferne alte Freigaben-Konfigurationen..."
sed -i '/^\[mayan-watch\]/,/^$/d' "$SMB_CONF"
sed -i '/^\[mayan-staging\]/,/^$/d' "$SMB_CONF"
sed -i '/^# Mayan EDMS/d' "$SMB_CONF"

# Füge KORREKTE Freigaben hinzu
info "Erstelle neue Freigaben-Konfiguration..."
cat >> "$SMB_CONF" << EOF

[mayan-watch]
   comment = Mayan EDMS Watch Folder
   path = $WATCH_DIR
   browseable = yes
   read only = no
   writable = yes
   valid users = $USERNAME
   write list = $USERNAME
   create mask = 0664
   directory mask = 0775
   force user = $USERNAME
   force group = $USERNAME
   vfs objects = catia fruit streams_xattr
   fruit:metadata = stream
   fruit:model = MacSamba
   fruit:encoding = native

[mayan-staging]
   comment = Mayan EDMS Staging Folder
   path = $STAGING_DIR
   browseable = yes
   read only = no
   writable = yes
   valid users = $USERNAME
   write list = $USERNAME
   create mask = 0664
   directory mask = 0775
   force user = $USERNAME
   force group = $USERNAME
   vfs objects = catia fruit streams_xattr
   fruit:metadata = stream
   fruit:model = MacSamba
   fruit:encoding = native
EOF

success "Freigaben konfiguriert"

# Konfiguration validieren
info "Validiere Samba-Konfiguration..."
if testparm -s "$SMB_CONF" &>/dev/null; then
    success "Samba-Konfiguration gültig"
    
    # Prüfe auf kritische Warnungen
    TESTPARM_OUTPUT=$(testparm -s "$SMB_CONF" 2>&1)
    if echo "$TESTPARM_OUTPUT" | grep -qi "ERROR"; then
        error "testparm zeigt Fehler - bitte manuell prüfen"
    fi
else
    error "Samba-Konfiguration ungültig!"
    info "Stelle Backup wieder her..."
    cp "$BACKUP_CONF" "$SMB_CONF"
    exit 1
fi

echo ""

# ============================================================================
# PHASE 7: Dienste starten
# ============================================================================

echo -e "${MAGENTA}[PHASE 7] Dienste starten${NC}"
echo ""

info "Aktiviere Samba-Autostart..."
systemctl enable smbd nmbd &>/dev/null
success "Autostart aktiviert"

info "Starte Samba-Dienste neu..."
systemctl restart smbd nmbd

sleep 3

if systemctl is-active --quiet smbd && systemctl is-active --quiet nmbd; then
    success "Samba-Dienste laufen"
else
    error "Samba-Dienste konnten nicht gestartet werden"
    info "Status prüfen mit: systemctl status smbd nmbd"
fi

# Firewall prüfen und konfigurieren
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        info "UFW Firewall erkannt, öffne Samba-Ports..."
        ufw allow samba &>/dev/null
        success "Samba-Ports in UFW freigegeben"
    fi
fi

echo ""

# ============================================================================
# PHASE 8: Umfassende Tests
# ============================================================================

echo -e "${MAGENTA}[PHASE 8] Umfassende Tests${NC}"
echo ""

TEST_FAILED=false

# Test 1: Unix-Benutzer Dateierstellung
echo -e "${BLUE}Test 1: Unix-Benutzer Dateierstellung${NC}"
TEST_FILE="$WATCH_DIR/test_unix_$USERNAME.txt"
if sudo -u "$USERNAME" touch "$TEST_FILE" 2>/dev/null; then
    if [ -f "$TEST_FILE" ]; then
        FILE_OWNER=$(stat -c '%U' "$TEST_FILE")
        success "Datei erstellt (Owner: $FILE_OWNER)"
        rm -f "$TEST_FILE"
    else
        error "Datei konnte nicht verifiziert werden"
        TEST_FAILED=true
    fi
else
    error "Benutzer kann keine Dateien erstellen"
    TEST_FAILED=true
fi

# Test 2: Samba-Benutzer existiert
echo -e "${BLUE}Test 2: Samba-Benutzer${NC}"
if pdbedit -L 2>/dev/null | grep -q "^$USERNAME:"; then
    success "Samba-Benutzer existiert"
else
    error "Samba-Benutzer nicht gefunden"
    TEST_FAILED=true
fi

# Test 3: SMB-Freigaben sichtbar (lokal)
echo -e "${BLUE}Test 3: SMB-Freigaben Sichtbarkeit${NC}"
SMB_LIST=$(smbclient -L localhost -U "$USERNAME%$PASSWORD" -N 2>/dev/null)
if echo "$SMB_LIST" | grep -q "mayan-watch"; then
    success "Freigabe 'mayan-watch' sichtbar"
else
    error "Freigabe 'mayan-watch' nicht sichtbar"
    TEST_FAILED=true
fi

# Test 4: SMB-Verbindung (localhost)
echo -e "${BLUE}Test 4: SMB-Verbindung (localhost)${NC}"
if smbclient //localhost/mayan-watch -U "$USERNAME%$PASSWORD" -c "ls" &>/dev/null; then
    success "SMB-Verbindung zu localhost erfolgreich"
else
    error "SMB-Verbindung zu localhost fehlgeschlagen"
    info "Prüfe Logs: tail -20 /var/log/samba/log.smbd"
    TEST_FAILED=true
fi

# Test 5: SMB-Verbindung (IP-Adresse)
echo -e "${BLUE}Test 5: SMB-Verbindung (IP: $IP_ADDRS)${NC}"
if smbclient //$IP_ADDRS/mayan-watch -U "$USERNAME%$PASSWORD" -c "ls" &>/dev/null; then
    success "SMB-Verbindung über IP erfolgreich"
else
    error "SMB-Verbindung über IP fehlgeschlagen"
    TEST_FAILED=true
fi

# Test 6: SMB-Schreibzugriff (KRITISCH)
echo -e "${BLUE}Test 6: SMB-Schreibzugriff${NC}"
TEST_SMB_FILE="smb_test_$(date +%s).txt"
if echo "SMB Test" | smbclient //localhost/mayan-watch -U "$USERNAME%$PASSWORD" -c "put - $TEST_SMB_FILE" &>/dev/null; then
    if [ -f "$WATCH_DIR/$TEST_SMB_FILE" ]; then
        success "SMB-Schreibzugriff funktioniert"
        rm -f "$WATCH_DIR/$TEST_SMB_FILE"
    else
        error "Datei wurde nicht auf Server erstellt"
        TEST_FAILED=true
    fi
else
    error "SMB-Schreibtest fehlgeschlagen"
    TEST_FAILED=true
fi

# Test 7: Berechtigungen prüfen
echo -e "${BLUE}Test 7: Verzeichnis-Berechtigungen${NC}"
WATCH_PERMS=$(stat -c '%a' "$WATCH_DIR")
if [ "$WATCH_PERMS" = "777" ]; then
    success "Watch-Ordner Berechtigungen korrekt (777)"
else
    warning "Watch-Ordner Berechtigungen: $WATCH_PERMS (sollte 777 sein für vollen Zugriff)"
fi

# Test 8: Samba-Dienste Status
echo -e "${BLUE}Test 8: Samba-Dienste Status${NC}"
if systemctl is-active --quiet smbd && systemctl is-active --quiet nmbd; then
    success "Beide Samba-Dienste aktiv"
else
    error "Nicht alle Samba-Dienste laufen"
    TEST_FAILED=true
fi

# Test 9: Autostart-Konfiguration
echo -e "${BLUE}Test 9: Autostart-Konfiguration${NC}"
ALL_ENABLED=true
systemctl is-enabled --quiet smbd || ALL_ENABLED=false
systemctl is-enabled --quiet nmbd || ALL_ENABLED=false
systemctl is-enabled --quiet chrony || ALL_ENABLED=false

if [ "$ALL_ENABLED" = true ]; then
    success "Alle Dienste für Autostart konfiguriert"
else
    warning "Nicht alle Dienste haben Autostart aktiviert"
fi

# Test 10: Port-Verfügbarkeit
echo -e "${BLUE}Test 10: SMB-Ports${NC}"
if ss -tulpn 2>/dev/null | grep -q ":445.*smbd"; then
    success "Port 445 (SMB) ist offen"
else
    error "Port 445 nicht erreichbar"
    TEST_FAILED=true
fi

echo ""

# ============================================================================
# Zusammenfassung
# ============================================================================

echo -e "${MAGENTA}============================================${NC}"
if [ "$TEST_FAILED" = true ] || [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}Setup mit Warnungen/Fehlern abgeschlossen${NC}"
    echo -e "${YELLOW}============================================${NC}"
    echo -e "${RED}Fehler: $ERRORS${NC}"
    echo -e "${YELLOW}Warnungen: $WARNINGS${NC}"
    echo ""
    echo -e "${YELLOW}Bitte prüfen Sie die Fehler oben und die Log-Datei:${NC}"
    echo "  $LOG_FILE"
else
    echo -e "${GREEN}✓ Setup erfolgreich abgeschlossen!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}Alle Tests bestanden!${NC}"
    echo -e "${GREEN}Fehler: $ERRORS | Warnungen: $WARNINGS${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}Konfigurationsdetails${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Benutzer:${NC} $USERNAME"
echo -e "${GREEN}Hostname:${NC} $(hostname)"
echo -e "${GREEN}NetBIOS-Name:${NC} $NETBIOS_NAME"
echo -e "${GREEN}IP-Adresse:${NC} $IP_ADDRS"
echo -e "${GREEN}Watch-Ordner:${NC} $WATCH_DIR (Berechtigungen: $(stat -c '%a' $WATCH_DIR))"
echo -e "${GREEN}Staging-Ordner:${NC} $STAGING_DIR (Berechtigungen: $(stat -c '%a' $STAGING_DIR 2>/dev/null || echo 'N/A'))"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}SMB-Freigaben${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Windows/Scanner:${NC}"
echo "  \\\\$IP_ADDRS\\mayan-watch"
echo "  \\\\$IP_ADDRS\\mayan-staging"
echo ""
echo -e "${GREEN}macOS:${NC}"
echo "  smb://$IP_ADDRS/mayan-watch"
echo "  smb://$IP_ADDRS/mayan-staging"
echo ""
echo -e "${GREEN}Linux:${NC}"
echo "  //$IP_ADDRS/mayan-watch"
echo "  //$IP_ADDRS/mayan-staging"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}Verbindungstests${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Von macOS Terminal:${NC}"
echo "  smbutil view //$USERNAME@$IP_ADDRS"
echo "  open \"smb://$IP_ADDRS/mayan-watch\""
echo "  mount_smbfs //$USERNAME@$IP_ADDRS/mayan-watch ~/mnt/mayan"
echo ""
echo -e "${YELLOW}Von Linux:${NC}"
echo "  smbclient -L $IP_ADDRS -U $USERNAME"
echo "  smbclient //$IP_ADDRS/mayan-watch -U $USERNAME"
echo ""
echo -e "${YELLOW}Brother Scanner ADS-4700W:${NC}"
echo "  Server: $IP_ADDRS"
echo "  Freigabe: mayan-watch"
echo "  Benutzername: $USERNAME"
echo "  Port: 445"
echo "  Auth: Auto/NTLM"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}Nächste Schritte${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo "1. Testen Sie die Verbindung von Ihrem Client (Mac/Scanner)"
echo ""
echo "2. Erstellen Sie Unterordner für Dokumenttypen:"
echo "   sudo mkdir -p $WATCH_DIR/gmbh/{Eingangsrechnung,Versandbeleg}"
echo "   sudo chown -R $USERNAME:$USERNAME $WATCH_DIR/gmbh"
echo "   sudo chmod -R 777 $WATCH_DIR/gmbh"
echo ""
echo "3. Konfigurieren Sie in Mayan EDMS die Watch-Folder-Quellen:"
echo "   System → Quellen → Neue Quelle → Watch folder"
echo "   - Quelle 1: Pfad 'gmbh/Eingangsrechnung'"
echo "   - Quelle 2: Pfad 'gmbh/Versandbeleg'"
echo ""
echo "4. Konfigurieren Sie Ihren Scanner:"
echo "   - Profil 1 → Ziel: /gmbh/Eingangsrechnung"
echo "   - Profil 2 → Ziel: /gmbh/Versandbeleg"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}Dienste${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Autostart aktiviert:${NC}"
echo "  ✓ smbd (Samba Server)"
echo "  ✓ nmbd (NetBIOS Name Service)"
echo "  ✓ chrony (Zeitsynchronisation)"
echo ""
echo -e "${YELLOW}Dienste verwalten:${NC}"
echo "  Status:   systemctl status smbd nmbd"
echo "  Neu start: systemctl restart smbd nmbd"
echo "  Logs:     tail -f /var/log/samba/log.smbd"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}Troubleshooting${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Bei Problemen:${NC}"
echo "  1. Logs prüfen:"
echo "     tail -100 /var/log/samba/log.smbd"
echo "     tail -50 /var/log/samba/log.mac-* # für macOS"
echo ""
echo "  2. Konfiguration testen:"
echo "     testparm -s"
echo ""
echo "  3. Verbindung testen:"
echo "     smbclient //localhost/mayan-watch -U $USERNAME"
echo ""
echo "  4. Berechtigungen prüfen:"
echo "     ls -la $WATCH_DIR"
echo "     getfacl $WATCH_DIR"
echo ""
echo "  5. Dienste-Status:"
echo "     systemctl status smbd nmbd"
echo ""
echo -e "${YELLOW}Backup der Konfiguration:${NC}"
echo "  $BACKUP_CONF"
echo ""
echo -e "${GREEN}Setup-Log:${NC} $LOG_FILE"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

log "=== Setup abgeschlossen: Fehler=$ERRORS, Warnungen=$WARNINGS ==="

# Exit Code basierend auf Fehlern
if [ $ERRORS -gt 0 ]; then
    exit 1
else
    exit 0
fi
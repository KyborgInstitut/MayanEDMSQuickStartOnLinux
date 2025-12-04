#!/bin/bash

# ============================================================================
# Mayan EDMS Scanner User Setup / Scanner-Benutzer Setup - Version 3.0 FINAL
# Fully tested and functional / Vollständig getestet und funktionsfähig
# ============================================================================

# Colors for output / Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Error tracking / Fehler-Tracking
ERRORS=0
WARNINGS=0

# Logging
LOG_FILE="/var/log/mayan_scanner_setup.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load language messages
if [[ -f "${SCRIPT_DIR}/lang_messages.sh" ]]; then
    source "${SCRIPT_DIR}/lang_messages.sh"
else
    echo "ERROR: lang_messages.sh not found!"
    exit 1
fi

# Use language from environment or default to English
LANG_CODE="${MAYAN_LANG:-en}"

# Function: Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function: Error handling
error() {
    echo -e "${RED}✗ $(msg ERROR): $1${NC}" | tee -a "$LOG_FILE"
    ((ERRORS++))
}

# Function: Warning
warning() {
    echo -e "${YELLOW}⚠ $(msg WARNING): $1${NC}" | tee -a "$LOG_FILE"
    ((WARNINGS++))
}

# Function: Success
success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

# Function: Info
info() {
    echo -e "${BLUE}ℹ $1${NC}" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "$(msg ROOT_REQUIRED)"
    [[ "$LANG_CODE" == "en" ]] && echo "Please run: sudo $0" || echo "Bitte als root ausführen: sudo $0"
    exit 1
fi

clear
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}$(msg SMB_TITLE)${NC}"
echo -e "${GREEN}$(msg SMB_SUBTITLE)${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
log "=== $(msg SMB_SETUP_STARTED) ==="

# ============================================================================
# PHASE 0: System Checks / System-Vorprüfungen
# ============================================================================

echo -e "${MAGENTA}[PHASE 0] $(msg SMB_PHASE0)${NC}"
echo ""

# Check operating system / Prüfe Betriebssystem
info "$(msg SMB_CHECK_OS)"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID_LIKE" != *"ubuntu"* ]]; then
        warning "$(msg SMB_NOT_UBUNTU): $ID $VERSION_ID"
    else
        success "$(msg SMB_UBUNTU_OK) $VERSION_ID"
    fi
else
    warning "$(msg SMB_OS_UNKNOWN)"
fi

# Check network configuration / Prüfe Netzwerk-Konfiguration
info "$(msg SMB_CHECK_NETWORK)"
IP_ADDRS=$(hostname -I | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | grep -v '^127\.' | head -1)
if [ -z "$IP_ADDRS" ]; then
    error "$(msg SMB_NO_IP)"
    exit 1
else
    success "$(msg SMB_IP_FOUND): $IP_ADDRS"
fi

# Check hostname length (NetBIOS limit: 15 chars)
HOSTNAME=$(hostname)
HOSTNAME_LENGTH=${#HOSTNAME}
if [ $HOSTNAME_LENGTH -gt 15 ]; then
    [[ "$LANG_CODE" == "en" ]] && warning "Hostname '$HOSTNAME' too long for NetBIOS (${HOSTNAME_LENGTH} > 15 chars)" || warning "Hostname '$HOSTNAME' ist zu lang für NetBIOS (${HOSTNAME_LENGTH} > 15 Zeichen)"
    NETBIOS_NAME="${HOSTNAME:0:15}"
    info "$(msg SMB_NETBIOS_SHORT): $NETBIOS_NAME"
else
    NETBIOS_NAME="$HOSTNAME"
    [[ "$LANG_CODE" == "en" ]] && success "Hostname length OK: $HOSTNAME_LENGTH chars" || success "Hostname-Länge OK: $HOSTNAME_LENGTH Zeichen"
fi

# Check Mayan directories / Prüfe Mayan-Verzeichnisse
info "$(msg SMB_CHECK_DIRS)"
MAYAN_BASE="/srv/mayan"
WATCH_DIR="$MAYAN_BASE/watch"
STAGING_DIR="$MAYAN_BASE/staging"

if [ ! -d "$WATCH_DIR" ]; then
    error "$(msg SMB_WATCH_NOT_FOUND): $WATCH_DIR"
    read -p "$(msg SMB_CREATE_DIR) $(msg YES_NO) " CREATE_WATCH
    if [[ "$CREATE_WATCH" =~ ^[yYjJ]$ ]]; then
        mkdir -p "$WATCH_DIR"
        success "$(msg SMB_WATCH_CREATED)"
    else
        error "$(msg SMB_WATCH_REQUIRED)"
        exit 1
    fi
else
    success "$(msg SMB_WATCH_FOUND): $WATCH_DIR"
fi

if [ ! -d "$STAGING_DIR" ]; then
    warning "$(msg SMB_STAGING_NOT_FOUND): $STAGING_DIR"
    read -p "$(msg SMB_CREATE_DIR) $(msg YES_NO) " CREATE_STAGING
    if [[ "$CREATE_STAGING" =~ ^[yYjJ]$ ]]; then
        mkdir -p "$STAGING_DIR"
        success "$(msg SMB_STAGING_CREATED)"
    else
        warning "$(msg SMB_STAGING_SKIPPED)"
    fi
else
    success "$(msg SMB_STAGING_FOUND): $STAGING_DIR"
fi

# Check Extended Attributes support
info "$(msg SMB_CHECK_EA)"
if command -v setfattr &> /dev/null; then
    if setfattr -n user.test -v test "$WATCH_DIR" 2>/dev/null; then
        getfattr -n user.test "$WATCH_DIR" &>/dev/null && setfattr -x user.test "$WATCH_DIR" 2>/dev/null
        success "$(msg SMB_EA_SUPPORTED)"
        EA_SUPPORT=true
    else
        warning "$(msg SMB_EA_LIMITED)"
        EA_SUPPORT=false
    fi
else
    warning "$(msg SMB_EA_INSTALL)"
    EA_SUPPORT=false
fi

echo ""

# ============================================================================
# PHASE 1: Time Synchronization / Zeitsynchronisation
# ============================================================================

echo -e "${MAGENTA}[PHASE 1] $(msg SMB_PHASE1)${NC}"
echo ""

info "$(msg SMB_CHECK_TIME)"
CURRENT_TIME=$(date +%s)
if [ $CURRENT_TIME -lt 1700000000 ]; then
    error "$(msg SMB_TIME_WRONG): $(date)"
    warning "$(msg SMB_TIME_ISSUES)"
else
    success "$(msg SMB_TIME_OK): $(date)"
fi

info "$(msg SMB_INSTALL_CHRONY)"
if ! command -v chronyd &> /dev/null; then
    apt-get update -qq 2>&1 | tee -a "$LOG_FILE"
    apt-get install -y -qq chrony 2>&1 | tee -a "$LOG_FILE"
    success "$(msg SMB_CHRONY_INSTALLED)"
else
    success "$(msg SMB_CHRONY_EXISTS)"
fi

systemctl enable chrony &>/dev/null
systemctl start chrony &>/dev/null

sleep 3

if systemctl is-active --quiet chrony; then
    SYNC_STATUS=$(timedatectl status | grep "System clock synchronized" | awk '{print $4}')
    if [ "$SYNC_STATUS" = "yes" ]; then
        success "$(msg SMB_TIME_SYNCED)"
    else
        warning "$(msg SMB_TIME_SYNCING)"
    fi
else
    error "$(msg SMB_CHRONY_FAILED)"
fi

echo ""

# ============================================================================
# PHASE 2: User Configuration / Benutzer-Konfiguration
# ============================================================================

echo -e "${MAGENTA}[PHASE 2] $(msg SMB_PHASE2)${NC}"
echo ""

# Ask for username with validation
while true; do
    read -p "$(msg SMB_USERNAME_PROMPT) " USERNAME

    # Check UNIX naming conventions
    if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        error "$(msg SMB_INVALID_USERNAME)"
        echo "$(msg SMB_USERNAME_RULES)"
        [[ "$LANG_CODE" == "en" ]] && echo "  - Lowercase letters, numbers, _ and - only" || echo "  - Nur Kleinbuchstaben, Zahlen, _ und -"
        [[ "$LANG_CODE" == "en" ]] && echo "  - Must start with letter or _" || echo "  - Muss mit Buchstabe oder _ beginnen"
        [[ "$LANG_CODE" == "en" ]] && echo "  - Max. 32 characters" || echo "  - Max. 32 Zeichen"
        echo ""
        continue
    fi

    # Check if user already exists
    if id "$USERNAME" &>/dev/null; then
        warning "$(msg SMB_USER_EXISTS) '$USERNAME'"
        read -p "$(msg SMB_CONTINUE_ANYWAY) $(msg YES_NO) " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[yYjJ]$ ]]; then
            continue
        fi
        USER_EXISTS=true
    else
        USER_EXISTS=false
    fi

    break
done

# Ask for password
while true; do
    read -s -p "$(msg SMB_PASSWORD_PROMPT) $USERNAME: " PASSWORD
    echo ""
    read -s -p "$(msg SMB_PASSWORD_REPEAT) " PASSWORD2
    echo ""

    if [ "$PASSWORD" != "$PASSWORD2" ]; then
        error "$(msg SMB_PASSWORD_MISMATCH)"
        continue
    fi

    if [ ${#PASSWORD} -lt 8 ]; then
        warning "$(msg SMB_PASSWORD_SHORT)"
        read -p "$(msg SMB_USE_ANYWAY) $(msg YES_NO) " USE_SHORT
        if [[ ! "$USE_SHORT" =~ ^[yYjJ]$ ]]; then
            continue
        fi
    fi

    break
done

echo ""
log "$(msg SMB_CONFIG_USER) '$USERNAME'"

# Create/update Unix user
if [ "$USER_EXISTS" = false ]; then
    info "$(msg SMB_CREATE_USER) '$USERNAME'..."
    useradd -m -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
    success "$(msg SMB_USER_CREATED)"
else
    info "$(msg SMB_USER_UPDATE)"
    echo "$USERNAME:$PASSWORD" | chpasswd
    success "$(msg SMB_PASSWORD_UPDATED)"
fi

# Add to groups
usermod -a -G users "$USERNAME"
success "$(msg SMB_USER_GROUP_ADDED)"

echo ""

# ============================================================================
# PHASE 3: Package Installation / Paket-Installation
# ============================================================================

echo -e "${MAGENTA}[PHASE 3] $(msg SMB_PHASE3)${NC}"
echo ""

# ACL tools
info "$(msg SMB_INSTALL_ACL)"
if ! command -v setfacl &> /dev/null; then
    apt-get update -qq 2>&1 | tee -a "$LOG_FILE"
    apt-get install -y -qq acl 2>&1 | tee -a "$LOG_FILE"
    success "$(msg SMB_ACL_INSTALLED)"
else
    success "$(msg SMB_ACL_EXISTS)"
fi

# attr for Extended Attributes
info "$(msg SMB_INSTALL_ATTR)"
if ! command -v setfattr &> /dev/null; then
    apt-get install -y -qq attr 2>&1 | tee -a "$LOG_FILE"
    success "$(msg SMB_ATTR_INSTALLED)"
else
    success "$(msg SMB_ATTR_EXISTS)"
fi

# Samba
info "$(msg SMB_INSTALL_SAMBA)"
if ! command -v smbd &> /dev/null; then
    apt-get install -y -qq samba samba-common-bin 2>&1 | tee -a "$LOG_FILE"
    success "$(msg SMB_SAMBA_INSTALLED)"
else
    success "$(msg SMB_SAMBA_EXISTS)"
fi

# smbclient for tests
info "$(msg SMB_INSTALL_CLIENT)"
if ! command -v smbclient &> /dev/null; then
    apt-get install -y -qq smbclient 2>&1 | tee -a "$LOG_FILE"
    success "$(msg SMB_CLIENT_INSTALLED)"
else
    success "$(msg SMB_CLIENT_EXISTS)"
fi

echo ""

# ============================================================================
# PHASE 4: Set Permissions / Berechtigungen setzen
# ============================================================================

echo -e "${MAGENTA}[PHASE 4] $(msg SMB_PHASE4)${NC}"
echo ""

# CRITICAL: Permissions must be 777 for SMB write access
if [ -d "$WATCH_DIR" ]; then
    info "$(msg SMB_SET_PERMS) $WATCH_DIR..."

    # Set owner
    chown "$USERNAME:$USERNAME" "$WATCH_DIR"

    # Permissions: 777 for full functionality
    chmod 777 "$WATCH_DIR"

    # Set ACLs
    setfacl -R -m u:$USERNAME:rwx "$WATCH_DIR"
    setfacl -R -d -m u:$USERNAME:rwx "$WATCH_DIR"

    # Check if correctly set
    PERMS=$(stat -c '%a' "$WATCH_DIR")
    if [ "$PERMS" = "777" ]; then
        success "$(msg SMB_WATCH_PERMS_OK) (777)"
    else
        [[ "$LANG_CODE" == "en" ]] && error "Permissions could not be set correctly (is: $PERMS, should: 777)" || error "Berechtigungen konnten nicht korrekt gesetzt werden (ist: $PERMS, soll: 777)"
    fi
else
    error "$(msg SMB_WATCH_NOT_AVAIL)"
fi

# Staging folder (if present)
if [ -d "$STAGING_DIR" ]; then
    info "$(msg SMB_SET_PERMS) $STAGING_DIR..."

    chown "$USERNAME:$USERNAME" "$STAGING_DIR"
    chmod 777 "$STAGING_DIR"
    setfacl -R -m u:$USERNAME:rwx "$STAGING_DIR"
    setfacl -R -d -m u:$USERNAME:rwx "$STAGING_DIR"

    PERMS=$(stat -c '%a' "$STAGING_DIR")
    if [ "$PERMS" = "777" ]; then
        success "$(msg SMB_STAGING_PERMS_OK) (777)"
    else
        [[ "$LANG_CODE" == "en" ]] && warning "Staging permissions: $PERMS (recommended: 777)" || warning "Staging-Berechtigungen: $PERMS (empfohlen: 777)"
    fi
fi

# Set Extended Attributes (for macOS)
if [ "$EA_SUPPORT" = true ] || command -v setfattr &> /dev/null; then
    info "$(msg SMB_SET_EA)"
    setfattr -n user.mayan_scanner -v "$USERNAME" "$WATCH_DIR" 2>/dev/null
    [ -d "$STAGING_DIR" ] && setfattr -n user.mayan_scanner -v "$USERNAME" "$STAGING_DIR" 2>/dev/null
    success "$(msg SMB_EA_SET)"
fi

echo ""

# ============================================================================
# PHASE 5: Configure Samba User / Samba-Benutzer konfigurieren
# ============================================================================

echo -e "${MAGENTA}[PHASE 5] $(msg SMB_PHASE5)${NC}"
echo ""

info "$(msg SMB_CREATE_SMB_USER) '$USERNAME'..."

# Remove old user if present (for clean reinstall)
if pdbedit -L 2>/dev/null | grep -q "^$USERNAME:"; then
    info "$(msg SMB_REMOVE_OLD_USER)"
    smbpasswd -x "$USERNAME" 2>/dev/null
fi

# Create new Samba user
info "$(msg SMB_CREATE_NEW_USER)"
(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a -s "$USERNAME" 2>/dev/null

# Enable user
smbpasswd -e "$USERNAME" &>/dev/null

# Check if user now exists
if pdbedit -L 2>/dev/null | grep -q "^$USERNAME:"; then
    success "$(msg SMB_SMB_USER_OK) '$USERNAME'"

    # Show user details (shortened)
    USER_INFO=$(pdbedit -L -v 2>/dev/null | grep -A 3 "Unix username:.*$USERNAME")
    [[ "$LANG_CODE" == "en" ]] && log "Samba user details: $USER_INFO" || log "Samba-Benutzer Details: $USER_INFO"
else
    error "$(msg SMB_SMB_USER_FAILED)"
fi

echo ""

# ============================================================================
# PHASE 6: Samba Configuration / Samba-Konfiguration
# ============================================================================

echo -e "${MAGENTA}[PHASE 6] $(msg SMB_PHASE6)${NC}"
echo ""

SMB_CONF="/etc/samba/smb.conf"
BACKUP_CONF="${SMB_CONF}.backup.$(date +%Y%m%d_%H%M%S)"

info "$(msg SMB_BACKUP_CONFIG)"
cp "$SMB_CONF" "$BACKUP_CONF"
success "$(msg SMB_BACKUP_CREATED): $BACKUP_CONF"

# Check if [global] section exists
if ! grep -q "^\[global\]" "$SMB_CONF"; then
    [[ "$LANG_CODE" == "en" ]] && error "[global] section not found in smb.conf!" || error "[global] Sektion nicht in smb.conf gefunden!"
    exit 1
fi

# Clean configuration
info "$(msg SMB_CLEAN_CONFIG)"
# Remove inline comments and faulty lines
sed -i '/# ← NICHT/d' "$SMB_CONF"
sed -i '/^[[:space:]]*$/N;/^\n$/d' "$SMB_CONF"

# Remove vfs objects from [global] if present
sed -i '/^\[global\]/,/^\[/{/^[[:space:]]*vfs objects/d}' "$SMB_CONF"
sed -i '/^\[global\]/,/^\[/{/^[[:space:]]*fruit:/d}' "$SMB_CONF"

# Set NetBIOS name correctly
if ! grep -q "^[[:space:]]*netbios name" "$SMB_CONF"; then
    sed -i "/^\[global\]/a \   netbios name = $NETBIOS_NAME" "$SMB_CONF"
    success "$(msg SMB_NETBIOS_SET): $NETBIOS_NAME"
elif grep -q "^[[:space:]]*netbios name.*${HOSTNAME}" "$SMB_CONF" && [ $HOSTNAME_LENGTH -gt 15 ]; then
    sed -i "s/netbios name.*/netbios name = $NETBIOS_NAME/" "$SMB_CONF"
    [[ "$LANG_CODE" == "en" ]] && success "NetBIOS name shortened: $NETBIOS_NAME" || success "NetBIOS-Name gekürzt: $NETBIOS_NAME"
fi

# Add log level if not present
if ! grep -q "^[[:space:]]*log level" "$SMB_CONF"; then
    sed -i '/^\[global\]/a \   log level = 2' "$SMB_CONF"
fi

# macOS/Brother compatibility in [global] (base options only)
info "$(msg SMB_CONFIG_COMPAT)"
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
    success "$(msg SMB_COMPAT_ADDED)"
fi

# Remove old share sections completely
info "$(msg SMB_REMOVE_OLD_SHARES)"
sed -i '/^\[mayan-watch\]/,/^$/d' "$SMB_CONF"
sed -i '/^\[mayan-staging\]/,/^$/d' "$SMB_CONF"
sed -i '/^# Mayan EDMS/d' "$SMB_CONF"

# Add CORRECT shares
info "$(msg SMB_CREATE_SHARES)"
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

success "$(msg SMB_SHARES_CONFIGURED)"

# Validate configuration
info "$(msg SMB_VALIDATE_CONFIG)"
if testparm -s "$SMB_CONF" &>/dev/null; then
    success "$(msg SMB_CONFIG_VALID)"

    # Check for critical warnings
    TESTPARM_OUTPUT=$(testparm -s "$SMB_CONF" 2>&1)
    if echo "$TESTPARM_OUTPUT" | grep -qi "ERROR"; then
        [[ "$LANG_CODE" == "en" ]] && error "testparm shows errors - please check manually" || error "testparm zeigt Fehler - bitte manuell prüfen"
    fi
else
    error "$(msg SMB_CONFIG_INVALID)"
    [[ "$LANG_CODE" == "en" ]] && info "Restoring backup..." || info "Stelle Backup wieder her..."
    cp "$BACKUP_CONF" "$SMB_CONF"
    exit 1
fi

echo ""

# ============================================================================
# PHASE 7: Start Services / Dienste starten
# ============================================================================

echo -e "${MAGENTA}[PHASE 7] $(msg SMB_PHASE7)${NC}"
echo ""

info "$(msg SMB_ENABLE_AUTOSTART)"
systemctl enable smbd nmbd &>/dev/null
success "$(msg SMB_AUTOSTART_ENABLED)"

info "$(msg SMB_RESTART_SERVICES)"
systemctl restart smbd nmbd

sleep 3

if systemctl is-active --quiet smbd && systemctl is-active --quiet nmbd; then
    success "$(msg SMB_SERVICES_RUNNING)"
else
    error "$(msg SMB_SERVICES_FAILED)"
    [[ "$LANG_CODE" == "en" ]] && info "Check status with: systemctl status smbd nmbd" || info "Status prüfen mit: systemctl status smbd nmbd"
fi

# Check and configure firewall
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        info "$(msg SMB_UFW_DETECTED)"
        ufw allow samba &>/dev/null
        success "$(msg SMB_UFW_OPENED)"
    fi
fi

echo ""

# ============================================================================
# PHASE 8: Comprehensive Tests / Umfassende Tests
# ============================================================================

echo -e "${MAGENTA}[PHASE 8] $(msg SMB_PHASE8)${NC}"
echo ""

TEST_FAILED=false

# Test 1: Unix user file creation
[[ "$LANG_CODE" == "en" ]] && echo -e "${BLUE}Test 1: Unix User File Creation${NC}" || echo -e "${BLUE}Test 1: Unix-Benutzer Dateierstellung${NC}"
TEST_FILE="$WATCH_DIR/test_unix_$USERNAME.txt"
if sudo -u "$USERNAME" touch "$TEST_FILE" 2>/dev/null; then
    if [ -f "$TEST_FILE" ]; then
        FILE_OWNER=$(stat -c '%U' "$TEST_FILE")
        [[ "$LANG_CODE" == "en" ]] && success "File created (Owner: $FILE_OWNER)" || success "Datei erstellt (Owner: $FILE_OWNER)"
        rm -f "$TEST_FILE"
    else
        error "$(msg SMB_TEST_FILE_VERIFY_FAILED)"
        TEST_FAILED=true
    fi
else
    error "$(msg SMB_TEST_USER_NO_CREATE)"
    TEST_FAILED=true
fi

# Test 2: Samba user exists
[[ "$LANG_CODE" == "en" ]] && echo -e "${BLUE}Test 2: Samba User${NC}" || echo -e "${BLUE}Test 2: Samba-Benutzer${NC}"
if pdbedit -L 2>/dev/null | grep -q "^$USERNAME:"; then
    success "$(msg SMB_TEST_SMB_USER_EXISTS)"
else
    error "$(msg SMB_TEST_SMB_USER_NOT_FOUND)"
    TEST_FAILED=true
fi

# Test 3: SMB Share Visibility
echo -e "${BLUE}$(msg SMB_TEST3_TITLE)${NC}"
SMB_LIST=$(smbclient -L localhost -U "$USERNAME%$PASSWORD" -N 2>/dev/null)
if echo "$SMB_LIST" | grep -q "mayan-watch"; then
    [[ "$LANG_CODE" == "en" ]] && success "$(msg SMB_TEST_SHARE_VISIBLE) 'mayan-watch'" || success "$(msg SMB_TEST_SHARE_VISIBLE) 'mayan-watch'"
else
    [[ "$LANG_CODE" == "en" ]] && error "$(msg SMB_TEST_SHARE_NOT_VISIBLE) 'mayan-watch'" || error "$(msg SMB_TEST_SHARE_NOT_VISIBLE) 'mayan-watch'"
    TEST_FAILED=true
fi

# Test 4: SMB Connection (localhost)
echo -e "${BLUE}$(msg SMB_TEST4_TITLE)${NC}"
if smbclient //localhost/mayan-watch -U "$USERNAME%$PASSWORD" -c "ls" &>/dev/null; then
    success "$(msg SMB_TEST_LOCALHOST_OK)"
else
    error "$(msg SMB_TEST_LOCALHOST_FAILED)"
    [[ "$LANG_CODE" == "en" ]] && info "Check logs: tail -20 /var/log/samba/log.smbd" || info "Prüfe Logs: tail -20 /var/log/samba/log.smbd"
    TEST_FAILED=true
fi

# Test 5: SMB Connection (IP)
echo -e "${BLUE}$(msg SMB_TEST5_TITLE): $IP_ADDRS${NC}"
if smbclient //$IP_ADDRS/mayan-watch -U "$USERNAME%$PASSWORD" -c "ls" &>/dev/null; then
    success "$(msg SMB_TEST_IP_OK)"
else
    error "$(msg SMB_TEST_IP_FAILED)"
    TEST_FAILED=true
fi

# Test 6: SMB Write Access (CRITICAL)
echo -e "${BLUE}$(msg SMB_TEST6_TITLE)${NC}"
TEST_SMB_FILE="smb_test_$(date +%s).txt"
if echo "SMB Test" | smbclient //localhost/mayan-watch -U "$USERNAME%$PASSWORD" -c "put - $TEST_SMB_FILE" &>/dev/null; then
    if [ -f "$WATCH_DIR/$TEST_SMB_FILE" ]; then
        success "$(msg SMB_TEST_WRITE_OK)"
        rm -f "$WATCH_DIR/$TEST_SMB_FILE"
    else
        error "$(msg SMB_TEST_FILE_NOT_CREATED)"
        TEST_FAILED=true
    fi
else
    error "$(msg SMB_TEST_WRITE_FAILED)"
    TEST_FAILED=true
fi

# Test 7: Directory Permissions
echo -e "${BLUE}$(msg SMB_TEST7_TITLE)${NC}"
WATCH_PERMS=$(stat -c '%a' "$WATCH_DIR")
if [ "$WATCH_PERMS" = "777" ]; then
    success "$(msg SMB_TEST_PERMS_OK)"
else
    [[ "$LANG_CODE" == "en" ]] && warning "Watch folder permissions: $WATCH_PERMS (should be 777 for full access)" || warning "Watch-Ordner Berechtigungen: $WATCH_PERMS (sollte 777 sein für vollen Zugriff)"
fi

# Test 8: Samba Services Status
echo -e "${BLUE}$(msg SMB_TEST8_TITLE)${NC}"
if systemctl is-active --quiet smbd && systemctl is-active --quiet nmbd; then
    success "$(msg SMB_TEST_SERVICES_OK)"
else
    error "$(msg SMB_TEST_SERVICES_NOT_ALL)"
    TEST_FAILED=true
fi

# Test 9: Autostart Configuration
echo -e "${BLUE}$(msg SMB_TEST9_TITLE)${NC}"
ALL_ENABLED=true
systemctl is-enabled --quiet smbd || ALL_ENABLED=false
systemctl is-enabled --quiet nmbd || ALL_ENABLED=false
systemctl is-enabled --quiet chrony || ALL_ENABLED=false

if [ "$ALL_ENABLED" = true ]; then
    success "$(msg SMB_TEST_AUTOSTART_OK)"
else
    warning "$(msg SMB_TEST_AUTOSTART_PARTIAL)"
fi

# Test 10: SMB Ports
echo -e "${BLUE}$(msg SMB_TEST10_TITLE)${NC}"
if ss -tulpn 2>/dev/null | grep -q ":445.*smbd"; then
    success "$(msg SMB_TEST_PORT_OK)"
else
    error "$(msg SMB_TEST_PORT_FAILED)"
    TEST_FAILED=true
fi

echo ""

# ============================================================================
# Summary / Zusammenfassung
# ============================================================================

echo -e "${MAGENTA}============================================${NC}"
if [ "$TEST_FAILED" = true ] || [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}$(msg SMB_SETUP_WITH_WARNINGS)${NC}"
    echo -e "${YELLOW}============================================${NC}"
    [[ "$LANG_CODE" == "en" ]] && echo -e "${RED}Errors: $ERRORS${NC}" || echo -e "${RED}Fehler: $ERRORS${NC}"
    [[ "$LANG_CODE" == "en" ]] && echo -e "${YELLOW}Warnings: $WARNINGS${NC}" || echo -e "${YELLOW}Warnungen: $WARNINGS${NC}"
    echo ""
    echo -e "${YELLOW}$(msg SMB_CHECK_LOG)${NC}"
    echo "  $LOG_FILE"
else
    echo -e "${GREEN}$(msg SMB_SETUP_SUCCESS)${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}$(msg SMB_ALL_TESTS_PASSED)${NC}"
    [[ "$LANG_CODE" == "en" ]] && echo -e "${GREEN}Errors: $ERRORS | Warnings: $WARNINGS${NC}" || echo -e "${GREEN}Fehler: $ERRORS | Warnungen: $WARNINGS${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}$(msg SMB_CONFIG_DETAILS)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo -e "${GREEN}User:${NC} $USERNAME" || echo -e "${GREEN}Benutzer:${NC} $USERNAME"
echo -e "${GREEN}Hostname:${NC} $(hostname)"
[[ "$LANG_CODE" == "en" ]] && echo -e "${GREEN}NetBIOS Name:${NC} $NETBIOS_NAME" || echo -e "${GREEN}NetBIOS-Name:${NC} $NETBIOS_NAME"
[[ "$LANG_CODE" == "en" ]] && echo -e "${GREEN}IP Address:${NC} $IP_ADDRS" || echo -e "${GREEN}IP-Adresse:${NC} $IP_ADDRS"
[[ "$LANG_CODE" == "en" ]] && echo -e "${GREEN}Watch Folder:${NC} $WATCH_DIR (Permissions: $(stat -c '%a' $WATCH_DIR))" || echo -e "${GREEN}Watch-Ordner:${NC} $WATCH_DIR (Berechtigungen: $(stat -c '%a' $WATCH_DIR))"
[[ "$LANG_CODE" == "en" ]] && echo -e "${GREEN}Staging Folder:${NC} $STAGING_DIR (Permissions: $(stat -c '%a' $STAGING_DIR 2>/dev/null || echo 'N/A'))" || echo -e "${GREEN}Staging-Ordner:${NC} $STAGING_DIR (Berechtigungen: $(stat -c '%a' $STAGING_DIR 2>/dev/null || echo 'N/A'))"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}$(msg SMB_SHARES_TITLE)${NC}"
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
echo -e "${BLUE}$(msg SMB_CONNECTION_TESTS)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo -e "${YELLOW}From macOS Terminal:${NC}" || echo -e "${YELLOW}Von macOS Terminal:${NC}"
echo "  smbutil view //$USERNAME@$IP_ADDRS"
echo "  open \"smb://$IP_ADDRS/mayan-watch\""
echo "  mount_smbfs //$USERNAME@$IP_ADDRS/mayan-watch ~/mnt/mayan"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo -e "${YELLOW}From Linux:${NC}" || echo -e "${YELLOW}Von Linux:${NC}"
echo "  smbclient -L $IP_ADDRS -U $USERNAME"
echo "  smbclient //$IP_ADDRS/mayan-watch -U $USERNAME"
echo ""
echo -e "${YELLOW}Brother Scanner ADS-4700W:${NC}"
echo "  Server: $IP_ADDRS"
[[ "$LANG_CODE" == "en" ]] && echo "  Share: mayan-watch" || echo "  Freigabe: mayan-watch"
[[ "$LANG_CODE" == "en" ]] && echo "  Username: $USERNAME" || echo "  Benutzername: $USERNAME"
echo "  Port: 445"
echo "  Auth: Auto/NTLM"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}$(msg SMB_NEXT_STEPS)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo "1. Test the connection from your client (Mac/Scanner)" || echo "1. Testen Sie die Verbindung von Ihrem Client (Mac/Scanner)"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo "2. Create subfolders for document types:" || echo "2. Erstellen Sie Unterordner für Dokumenttypen:"
echo "   sudo mkdir -p $WATCH_DIR/gmbh/{Eingangsrechnung,Versandbeleg}"
echo "   sudo chown -R $USERNAME:$USERNAME $WATCH_DIR/gmbh"
echo "   sudo chmod -R 777 $WATCH_DIR/gmbh"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo "3. Configure watch folder sources in Mayan EDMS:" || echo "3. Konfigurieren Sie in Mayan EDMS die Watch-Folder-Quellen:"
[[ "$LANG_CODE" == "en" ]] && echo "   System → Sources → New Source → Watch folder" || echo "   System → Quellen → Neue Quelle → Watch folder"
[[ "$LANG_CODE" == "en" ]] && echo "   - Source 1: Path 'gmbh/Eingangsrechnung'" || echo "   - Quelle 1: Pfad 'gmbh/Eingangsrechnung'"
[[ "$LANG_CODE" == "en" ]] && echo "   - Source 2: Path 'gmbh/Versandbeleg'" || echo "   - Quelle 2: Pfad 'gmbh/Versandbeleg'"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo "4. Configure your scanner:" || echo "4. Konfigurieren Sie Ihren Scanner:"
[[ "$LANG_CODE" == "en" ]] && echo "   - Profile 1 → Destination: /gmbh/Eingangsrechnung" || echo "   - Profil 1 → Ziel: /gmbh/Eingangsrechnung"
[[ "$LANG_CODE" == "en" ]] && echo "   - Profile 2 → Destination: /gmbh/Versandbeleg" || echo "   - Profil 2 → Ziel: /gmbh/Versandbeleg"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}$(msg SMB_SERVICES)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}$(msg SMB_AUTOSTART_ACTIVE)${NC}"
echo "  ✓ smbd (Samba Server)"
[[ "$LANG_CODE" == "en" ]] && echo "  ✓ nmbd (NetBIOS Name Service)" || echo "  ✓ nmbd (NetBIOS Name Service)"
[[ "$LANG_CODE" == "en" ]] && echo "  ✓ chrony (Time Synchronization)" || echo "  ✓ chrony (Zeitsynchronisation)"
echo ""
echo -e "${YELLOW}$(msg SMB_MANAGE_SERVICES)${NC}"
echo "  Status:   systemctl status smbd nmbd"
[[ "$LANG_CODE" == "en" ]] && echo "  Restart:  systemctl restart smbd nmbd" || echo "  Neustart: systemctl restart smbd nmbd"
echo "  Logs:     tail -f /var/log/samba/log.smbd"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}$(msg SMB_TROUBLESHOOTING)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}$(msg SMB_IF_PROBLEMS)${NC}"
[[ "$LANG_CODE" == "en" ]] && echo "  1. Check logs:" || echo "  1. Logs prüfen:"
echo "     tail -100 /var/log/samba/log.smbd"
[[ "$LANG_CODE" == "en" ]] && echo "     tail -50 /var/log/samba/log.mac-* # for macOS" || echo "     tail -50 /var/log/samba/log.mac-* # für macOS"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo "  2. Test configuration:" || echo "  2. Konfiguration testen:"
echo "     testparm -s"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo "  3. Test connection:" || echo "  3. Verbindung testen:"
echo "     smbclient //localhost/mayan-watch -U $USERNAME"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo "  4. Check permissions:" || echo "  4. Berechtigungen prüfen:"
echo "     ls -la $WATCH_DIR"
echo "     getfacl $WATCH_DIR"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo "  5. Services status:" || echo "  5. Dienste-Status:"
echo "     systemctl status smbd nmbd"
echo ""
[[ "$LANG_CODE" == "en" ]] && echo -e "${YELLOW}Configuration backup:${NC}" || echo -e "${YELLOW}Backup der Konfiguration:${NC}"
echo "  $BACKUP_CONF"
echo ""
echo -e "${GREEN}Setup-Log:${NC} $LOG_FILE"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

[[ "$LANG_CODE" == "en" ]] && log "=== Setup completed: Errors=$ERRORS, Warnings=$WARNINGS ===" || log "=== Setup abgeschlossen: Fehler=$ERRORS, Warnungen=$WARNINGS ==="

# Exit Code basierend auf Fehlern
if [ $ERRORS -gt 0 ]; then
    exit 1
else
    exit 0
fi
#!/bin/bash

# ============================================
# WireGuard VPS + MikroTik Client Manager v2
# SolusiDigitalnet
# ============================================

# set -e disabled - script handles errors gracefully

# ── Colors ──────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# ── Config ───────────────────────────────────
SERVER_IP="192.22.22.1"
SERVER_NETWORK="192.22.22.0/24"
SERVER_PORT=51820
MT_NETWORK="192.22.22"
MT_START_IP=2
VPS_PUBLIC_IP=""
WG_CONF="/etc/wireguard/wg0.conf"
WG_CLIENTS="/etc/wireguard/clients"

# ════════════════════════════════════════════
# BANNER
# ════════════════════════════════════════════
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "               +▒▒▒▒+  +▒▒▒+  ▒▒   ▒▒  ▒▒  +▒▒▒+  ▒▒  "
    echo "               ▒▒+---  ▒▒ ▒▒  ▒▒   ▒▒  ▒▒  ▒▒+--  ▒▒  "
    echo "               +▒▒▒+   ▒▒ ▒▒  ▒▒   ▒▒  ▒▒  +▒▒▒+  ▒▒  "
    echo "               ---▒▒▒  ▒▒ ▒▒  ▒▒   ▒▒--▒▒  --▒▒▒  ▒▒  "
    echo "               +▒▒▒▒+  +▒▒▒+  +▒▒  +▒▒▒▒+  +▒▒▒+  ▒▒  "
    echo ""
    echo "  ▒▒▒▒+   ▒▒  +▒▒▒▒+  ▒▒  ▒▒▒▒▒  +▒▒▒▒  ▒▒   ▒▒  +▒▒  +▒▒▒▒  ▒▒▒▒▒  "
    echo "  ▒▒  ▒▒  ▒▒  ▒▒  --  ▒▒   ▒▒       ▒▒  ▒▒   ▒▒▒ ▒▒▒  ▒▒+--   ▒▒    "
    echo "  ▒▒  ▒▒  ▒▒  ▒▒ +▒▒  ▒▒   ▒▒    +▒▒▒▒  ▒▒   ▒▒▒▒▒▒▒  ▒▒▒▒▒   ▒▒    "
    echo "  ▒▒  ▒▒  ▒▒  ▒▒  ▒▒  ▒▒   ▒▒    ▒▒  ▒  ▒▒   ▒▒ ▒▒▒▒  ▒▒+--   ▒▒    "
    echo "  ▒▒▒▒+   ▒▒  +▒▒▒▒+  ▒▒   +▒▒   +▒▒▒▒  +▒▒  ▒▒  +▒▒  +▒▒▒▒   +▒▒   "
    echo -e "${NC}"
    echo -e "${WHITE}  ╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}     ${BOLD}${CYAN}SolusiDigitalNet${NC} ${GRAY}─${NC} WireGuard Manager ${YELLOW}v2.0${NC}          ${NC}"
    echo -e "${WHITE}     ${GRAY}VPS Hub + MikroTik Client Provisioner${NC}              ${NC}"
    echo -e "${WHITE}  ╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ════════════════════════════════════════════
# ANIMASI
# ════════════════════════════════════════════
spinner() {
    local pid=$1
    local msg="${2:-Processing...}"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}${frames[$i]}${NC}  ${msg}"
        i=$(( (i+1) % 10 ))
        sleep 0.08
    done
    printf "\r"
}

progress_bar() {
    local msg="${1:-Loading...}"
    local duration="${2:-1.5}"
    local width=40
    printf "  ${GRAY}[${NC}"
    for i in $(seq 1 $width); do
        printf "${CYAN}░${NC}"
    done
    printf "${GRAY}]${NC} 0%%"
    
    local steps=20
    local delay=$(echo "$duration / $steps" | bc -l 2>/dev/null || echo "0.075")
    for i in $(seq 1 $steps); do
        local filled=$(( i * width / steps ))
        local pct=$(( i * 100 / steps ))
        printf "\r  ${GRAY}[${NC}"
        for j in $(seq 1 $filled); do printf "${CYAN}█${NC}"; done
        for j in $(seq $filled $((width-1))); do printf "${GRAY}░${NC}"; done
        printf "${GRAY}]${NC} ${pct}%%"
        sleep "$delay" 2>/dev/null || sleep 0.075
    done
    printf "\r  ${GRAY}[${NC}"
    for i in $(seq 1 $width); do printf "${GREEN}█${NC}"; done
    printf "${GRAY}]${NC} ${GREEN}100%% ✓${NC}\n"
}

anim_dots() {
    local msg="$1"
    for i in 1 2 3; do
        printf "\r  ${YELLOW}${msg}$(printf '.%.0s' $(seq 1 $i))   ${NC}"
        sleep 0.3
    done
    printf "\r"
}

ok()   { echo -e "  ${GREEN}✔${NC}  $*"; }
fail() { echo -e "  ${RED}✘${NC}  $*"; }
info() { echo -e "  ${CYAN}ℹ${NC}  $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $*"; }
hr()   { echo -e "  ${GRAY}──────────────────────────────────────────────────────${NC}"; }
sep()  { echo -e "\n  ${GRAY}╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${NC}\n"; }

# ════════════════════════════════════════════
# HELPERS
# ════════════════════════════════════════════
check_root() {
    if [[ $EUID -ne 0 ]]; then
        fail "Jalankan sebagai root: ${BOLD}sudo bash $0${NC}"
        exit 1
    fi
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
            fail "Hanya support Ubuntu & Debian"
            exit 1
        fi
        ok "OS: $PRETTY_NAME"
    fi
}

get_public_ip() {
    VPS_PUBLIC_IP=$(curl -s -4 --connect-timeout 5 ifconfig.me 2>/dev/null \
        || curl -s -4 --connect-timeout 5 icanhazip.com 2>/dev/null \
        || curl -s --connect-timeout 5 --ipv4 api.ipify.org 2>/dev/null)
    if [[ -z "$VPS_PUBLIC_IP" ]] || [[ "$VPS_PUBLIC_IP" =~ : ]]; then
        warn "Tidak bisa detect IP public"
        echo -ne "  ${YELLOW}Masukkan IP public VPS:${NC} "
        read -r VPS_PUBLIC_IP
    fi
    echo "$VPS_PUBLIC_IP"
}

get_mt_ip() {
    if [[ ! -f "$WG_CONF" ]]; then
        echo "${MT_NETWORK}.${MT_START_IP}"
        return
    fi
    local LAST_IP
    LAST_IP=$(grep "AllowedIPs" "$WG_CONF" \
        | grep -oE "${MT_NETWORK}\.[0-9]+" \
        | sort -t. -k4 -n \
        | tail -1 \
        | cut -d. -f4 2>/dev/null || true)
    if [[ -z "$LAST_IP" ]]; then
        echo "${MT_NETWORK}.${MT_START_IP}"
    else
        echo "${MT_NETWORK}.$((LAST_IP + 1))"
    fi
}

wg_is_installed() { [[ -f /etc/wireguard/server_private.key ]]; }

wg_is_running() { wg show wg0 &>/dev/null; }

client_exists() { [[ -d "${WG_CLIENTS}/$1" ]]; }

count_clients() { ls -d "${WG_CLIENTS}"/*/ 2>/dev/null | wc -l; }

# ════════════════════════════════════════════
# RESTART WG
# ════════════════════════════════════════════
do_wg_restart() {
    echo ""
    info "Merestart WireGuard..."
    wg-quick down wg0 2>/dev/null || true
    local RC=0
    wg-quick up wg0 > /tmp/wg_up.log 2>&1 || RC=$?
    if [[ $RC -ne 0 ]]; then
        fail "Config error! Merestore backup..."
        cat /tmp/wg_up.log | while IFS= read -r line; do
            echo -e "  ${GRAY}$line${NC}"
        done
        if [[ -f "${WG_CONF}.bak" ]]; then
            cp "${WG_CONF}.bak" "$WG_CONF"
            wg-quick up wg0 &>/dev/null || true
        fi
        return 1
    fi
    ok "WireGuard aktif"
    return 0
}

# ════════════════════════════════════════════
# INSTALL
# ════════════════════════════════════════════
do_install() {
    show_banner
    echo -e "  ${WHITE}${BOLD}[ INSTALL WIREGUARD SERVER ]${NC}"
    hr
    echo ""
    check_root
    detect_os
    echo ""

    info "Update & install packages..."
    (apt-get update -qq 2>/tmp/wg_update.log || true; \
     apt-get install -y wireguard wireguard-tools iptables) \
     > /tmp/wg_install.log 2>&1 &
    local INSTALL_PID=$!
    spinner $INSTALL_PID "Install WireGuard..."
    wait $INSTALL_PID || {
        fail "Gagal install packages! Log:"
        tail -20 /tmp/wg_install.log | while IFS= read -r line; do
            echo -e "  ${GRAY}$line${NC}"
        done
        return 1
    }
    ok "Packages terinstall"

    echo ""
    info "Generate server keys..."
    progress_bar "Generating keys" 1
    local PRIV PUB
    PRIV=$(wg genkey)
    PUB=$(echo "$PRIV" | wg pubkey)
    mkdir -p /etc/wireguard
    echo "$PRIV" > /etc/wireguard/server_private.key
    echo "$PUB"  > /etc/wireguard/server_public.key
    chmod 600 /etc/wireguard/*.key
    ok "Keys tergenerate"

    echo ""
    info "Buat server config..."
    local PUBLIC_IF
    PUBLIC_IF=$(ip route | grep default | awk '{print $5}' | head -1)
    cat > "$WG_CONF" <<EOF
[Interface]
PrivateKey = $PRIV
Address = $SERVER_IP/24
ListenPort = $SERVER_PORT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $PUBLIC_IF -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $PUBLIC_IF -j MASQUERADE
EOF
    chmod 600 "$WG_CONF"
    ok "Config dibuat (interface: $PUBLIC_IF)"

    echo ""
    info "Enable IP forward..."
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    sysctl -qw net.ipv4.ip_forward=1 2>/dev/null || true
    ok "IP forward enabled"

    echo ""
    anim_dots "Starting WireGuard"
    wg-quick up wg0 2>/dev/null || true
    systemctl enable wg-quick@wg0 2>/dev/null || true

    echo ""
    info "Mengecek & menginstall cron..."
    if ! command -v crontab &>/dev/null; then
        apt-get install -y cron > /dev/null 2>&1
        ok "Cron terinstall"
    else
        ok "Cron sudah terinstall"
    fi

    info "Membuat cron job untuk route management..."
    cat > /etc/cron.d/wg-routes << 'EOF'
* * * * * root /usr/bin/wg show wg0 allowed-ips | awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '0.0.0.0/0' | while read r; do /usr/sbin/ip route show | grep -q "$r dev wg0" || /usr/sbin/ip route add $r dev wg0; done
EOF
    chmod 644 /etc/cron.d/wg-routes
    ok "Cron job wg-routes dibuat"

    sep
    local PUBLIC_IP
    PUBLIC_IP=$(get_public_ip)
    echo -e "  ${WHITE}${BOLD}INSTALLASI BERHASIL!${NC}"
    hr
    echo -e "  ${GRAY}WireGuard IP   :${NC}  ${CYAN}${SERVER_IP}${NC}"
    echo -e "  ${GRAY}Public IP      :${NC}  ${CYAN}${PUBLIC_IP}${NC}"
    echo -e "  ${GRAY}Port           :${NC}  ${CYAN}${SERVER_PORT}${NC}"
    echo -e "  ${GRAY}Server Pub Key :${NC}"
    echo -e "  ${YELLOW}$(cat /etc/wireguard/server_public.key)${NC}"
    hr
    echo ""
}

# ════════════════════════════════════════════
# KONTROL WG (Aktif / Nonaktif / Restart)
# ════════════════════════════════════════════
menu_control() {
    while true; do
        show_banner
        echo -e "  ${WHITE}${BOLD}[ KONTROL WIREGUARD ]${NC}"
        hr
        echo ""
        local STATUS
        if wg_is_running; then
            STATUS="${GREEN}● AKTIF${NC}"
        else
            STATUS="${RED}○ NONAKTIF${NC}"
        fi
        echo -e "  Status  :  $STATUS"
        echo -e "  Uptime  :  $(systemctl show wg-quick@wg0 --property=ActiveEnterTimestamp 2>/dev/null | cut -d= -f2 || echo '-')"
        sep
        echo -e "  ${GREEN}1)${NC} ${WHITE}Aktifkan${NC}   (wg-quick up)"
        echo -e "  ${RED}2)${NC} ${WHITE}Matikan${NC}    (wg-quick down)"
        echo -e "  ${YELLOW}3)${NC} ${WHITE}Restart${NC}    (down → up)"
        echo -e "  ${CYAN}4)${NC} ${WHITE}Enable Boot${NC} (systemctl enable)"
        echo -e "  ${CYAN}5)${NC} ${WHITE}Disable Boot${NC}(systemctl disable)"
        echo ""
        echo -e "  ${GRAY}0) Kembali${NC}"
        hr
        echo -ne "\n  ${BOLD}Pilihan:${NC} "
        read -r choice
        echo ""
        case $choice in
            1)
                anim_dots "Mengaktifkan WireGuard"
                if wg-quick up wg0 2>/dev/null; then
                    ok "WireGuard aktif!"
                else
                    fail "Gagal — cek config wg0.conf"
                fi
                ;;
            2)
                anim_dots "Mematikan WireGuard"
                wg-quick down wg0 2>/dev/null || true
                ok "WireGuard dimatikan"
                ;;
            3)
                do_wg_restart
                ;;
            4)
                systemctl enable wg-quick@wg0 2>/dev/null && ok "Auto-start saat boot diaktifkan"
                ;;
            5)
                systemctl disable wg-quick@wg0 2>/dev/null && ok "Auto-start saat boot dinonaktifkan"
                ;;
            0) return ;;
            *) warn "Pilihan tidak valid" ;;
        esac
        echo ""
        echo -ne "  ${GRAY}ENTER untuk lanjut...${NC}"
        read -r
    done
}

# ════════════════════════════════════════════
# SHOW STATUS
# ════════════════════════════════════════════
show_status() {
    show_banner
    echo -e "  ${WHITE}${BOLD}[ STATUS WIREGUARD ]${NC}"
    hr
    echo ""

    local STATUS_LINE
    if wg_is_running; then
        STATUS_LINE="${GREEN}● AKTIF${NC}"
    else
        STATUS_LINE="${RED}○ NONAKTIF${NC}"
    fi

    local PUBLIC_IP
    PUBLIC_IP=$(cat /etc/wireguard/server_public.key 2>/dev/null || echo "N/A")

    echo -e "  ${GRAY}Status         :${NC} $STATUS_LINE"
    echo -e "  ${GRAY}WireGuard IP   :${NC} ${CYAN}${SERVER_IP}${NC}"
    echo -e "  ${GRAY}Listen Port    :${NC} ${CYAN}${SERVER_PORT}${NC}"
    echo -e "  ${GRAY}Server Pub Key :${NC}"
    echo -e "  ${YELLOW}$PUBLIC_IP${NC}"
    echo ""

    if wg_is_running; then
        hr
        echo -e "  ${WHITE}${BOLD}Peer Overview:${NC}"
        echo ""
        wg show wg0 2>/dev/null | while IFS= read -r line; do
            if [[ "$line" =~ ^peer ]]; then
                echo -e "  ${CYAN}$line${NC}"
            elif [[ "$line" =~ endpoint|allowed|latest|transfer ]]; then
                echo -e "  ${GRAY}$line${NC}"
            else
                echo -e "  $line"
            fi
        done
    fi
    echo ""
    hr
    echo ""
}

# ════════════════════════════════════════════
# CLIENT LIST
# ════════════════════════════════════════════
list_clients_inline() {
    echo ""
    if [[ ! -d "$WG_CLIENTS" ]] || [[ -z "$(ls -A "$WG_CLIENTS" 2>/dev/null)" ]]; then
        warn "Belum ada client."
        return 1
    fi

    local i=0
    echo -e "  ${WHITE}${BOLD}  #   NAMA CLIENT          IP ADDRESS         ROUTES${NC}"
    hr
    for dir in "${WG_CLIENTS}"/*/; do
        local CLIENT
        CLIENT=$(basename "$dir")
        local IP ROUTES
        IP=$(grep -A5 "# Client: $CLIENT" "$WG_CONF" 2>/dev/null \
            | grep "AllowedIPs" | head -1 | cut -d'=' -f2 | tr -d ' ' | cut -d',' -f1 || echo "N/A")
        ROUTES=$(grep -A5 "# Client: $CLIENT" "$WG_CONF" 2>/dev/null \
            | grep "AllowedIPs" | head -1 | cut -d'=' -f2 | tr -d ' ' | tr ',' '\n' | tail -n+2 | tr '\n' ' ' || true)
        [[ -z "$ROUTES" ]] && ROUTES="${GRAY}(no extra routes)${NC}"

        i=$((i+1))
        printf "  ${CYAN}%-4s${NC}${GREEN}%-22s${NC}${YELLOW}%-20s${NC}" \
            "$i)" "$CLIENT" "$IP"
        echo -e "${ROUTES}"
    done
    hr
    echo -e "  ${GRAY}Total: $(count_clients) client(s)${NC}"
    echo ""
}

# ════════════════════════════════════════════
# DETAIL CLIENT (interaktif inline)
# ════════════════════════════════════════════
client_detail() {
    local CLIENT_NAME="$1"
    while true; do
        show_banner
        echo -e "  ${WHITE}${BOLD}[ DETAIL CLIENT: ${CYAN}${CLIENT_NAME}${NC}${WHITE}${BOLD} ]${NC}"
        hr
        echo ""

        local IP ALLOWED PUB
        IP=$(grep -A5 "# Client: $CLIENT_NAME" "$WG_CONF" 2>/dev/null \
            | grep "AllowedIPs" | head -1 | cut -d'=' -f2 | tr -d ' ' | cut -d',' -f1 || echo "N/A")
        ALLOWED=$(grep -A5 "# Client: $CLIENT_NAME" "$WG_CONF" 2>/dev/null \
            | grep "AllowedIPs" | head -1 | cut -d'=' -f2 | tr -d ' ' || echo "N/A")
        PUB=$(cat "${WG_CLIENTS}/${CLIENT_NAME}/public.key" 2>/dev/null || echo "N/A")

        echo -e "  ${GRAY}IP WireGuard   :${NC} ${CYAN}${IP}${NC}"
        echo -e "  ${GRAY}Public Key     :${NC}"
        echo -e "  ${YELLOW}${PUB}${NC}"
        echo ""
        echo -e "  ${GRAY}AllowedIPs     :${NC}"
        echo "$ALLOWED" | tr ',' '\n' | while read -r route; do
            [[ -z "$route" ]] && continue
            echo -e "    ${GREEN}→${NC} ${route}"
        done
        echo ""

        # Cek koneksi live
        if wg_is_running; then
            local HANDSHAKE TRANSFER
            HANDSHAKE=$(wg show wg0 latest-handshakes 2>/dev/null | grep "$PUB" | awk '{print $2}' || true)
            TRANSFER=$(wg show wg0 transfer 2>/dev/null | grep "$PUB" | awk '{print "TX:"$2" RX:"$3}' || true)
            if [[ -n "$HANDSHAKE" && "$HANDSHAKE" != "0" ]]; then
                local HS_AGO=$(( $(date +%s) - HANDSHAKE ))
                echo -e "  ${GRAY}Last Handshake :${NC} ${GREEN}${HS_AGO}s ago${NC}"
            else
                echo -e "  ${GRAY}Last Handshake :${NC} ${RED}Belum ada / offline${NC}"
            fi
            [[ -n "$TRANSFER" ]] && echo -e "  ${GRAY}Transfer       :${NC} ${CYAN}${TRANSFER}${NC}"
            echo ""
        fi

        hr
        echo -e "  ${GREEN}1)${NC} Tambah Route"
        echo -e "  ${RED}2)${NC} Hapus Route"
        echo -e "  ${CYAN}3)${NC} Lihat Konfigurasi MikroTik"
        echo -e "  ${RED}4)${NC} Hapus Client Ini"
        echo ""
        echo -e "  ${GRAY}0) Kembali${NC}"
        hr
        echo -ne "\n  ${BOLD}Pilihan:${NC} "
        read -r choice
        echo ""
        case $choice in
            1) _client_add_route "$CLIENT_NAME" ;;
            2) _client_del_route "$CLIENT_NAME" ;;
            3) _client_show_mikrotik "$CLIENT_NAME" ;;
            4)
                _client_delete "$CLIENT_NAME"
                [[ $? -eq 0 ]] && return
                ;;
            0) return ;;
            *) warn "Pilihan tidak valid" ;;
        esac
        echo ""
        echo -ne "  ${GRAY}ENTER untuk lanjut...${NC}"
        read -r
    done
}

# ════════════════════════════════════════════
# CLIENT: TAMBAH ROUTE (inline)
# ════════════════════════════════════════════
_client_add_route() {
    local CLIENT_NAME="$1"
    echo -e "  ${WHITE}${BOLD}Tambah Route ke ${CYAN}${CLIENT_NAME}${NC}"
    hr

    local CURRENT
    CURRENT=$(grep -A5 "# Client: $CLIENT_NAME" "$WG_CONF" \
        | grep "AllowedIPs" | head -1 | sed 's/AllowedIPs = //' | tr -d ' ')

    echo -e "  AllowedIPs saat ini:"
    echo "$CURRENT" | tr ',' '\n' | while read -r r; do
        [[ -n "$r" ]] && echo -e "    ${CYAN}→ $r${NC}"
    done
    echo ""
    echo -e "  ${YELLOW}Masukkan network baru (contoh: 10.22.0.0/20):${NC}"
    echo -ne "  > "
    read -r NETWORK
    if [[ -z "$NETWORK" ]]; then
        warn "Dibatalkan"
        return
    fi
    if [[ ! "$NETWORK" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
        fail "Format salah. Contoh: 10.22.0.0/20"
        return
    fi
    if echo "$CURRENT" | grep -q "$NETWORK"; then
        warn "Route ${NETWORK} sudah ada!"
        return
    fi

    cp "$WG_CONF" "${WG_CONF}.bak"
    local NEW_ROUTES="${CURRENT},${NETWORK}"

    # Update AllowedIPs menggunakan awk - lebih reliable dari sed
    awk -v client="$CLIENT_NAME" -v routes="$NEW_ROUTES" '
        /^# Client: / && $3 == client { found=1 }
        found && /^AllowedIPs/ { $0 = "AllowedIPs = " routes; found=0 }
        { print }
    ' "$WG_CONF" > "${WG_CONF}.tmp" && mv "${WG_CONF}.tmp" "$WG_CONF"

    anim_dots "Mengaplikasikan route"
    local PUB
    PUB=$(cat "${WG_CLIENTS}/${CLIENT_NAME}/public.key" 2>/dev/null || true)
    if wg_is_running && [[ -n "$PUB" ]]; then
        if do_wg_restart; then
            ok "Route ${NETWORK} berhasil ditambahkan!"
            info "AllowedIPs baru: ${NEW_ROUTES}"
            info "Server perlu restart WG - client akan reconnect otomatis"
        else
            fail "Gagal restart WireGuard"
            cp "${WG_CONF}.bak" "$WG_CONF"
        fi
    else
        fail "WireGuard tidak aktif, tidak bisa update route"
    fi
}

# ════════════════════════════════════════════
# CLIENT: HAPUS ROUTE (inline)
# ════════════════════════════════════════════
_client_del_route() {
    local CLIENT_NAME="$1"
    echo -e "  ${WHITE}${BOLD}Hapus Route dari ${CYAN}${CLIENT_NAME}${NC}"
    hr

    local CURRENT
    CURRENT=$(grep -A5 "# Client: $CLIENT_NAME" "$WG_CONF" \
        | grep "AllowedIPs" | head -1 | sed 's/AllowedIPs = //' | tr -d ' ')

    local MAIN_IP
    MAIN_IP=$(echo "$CURRENT" | cut -d',' -f1)

    local ROUTES
    ROUTES=$(echo "$CURRENT" | tr ',' '\n' | tail -n+2)
    if [[ -z "$ROUTES" ]]; then
        warn "Tidak ada extra route untuk dihapus (hanya IP utama $MAIN_IP)"
        return
    fi

    echo -e "  ${YELLOW}Pilih route yang dihapus:${NC}"
    echo ""
    local i=0
    local ROUTE_ARR=()
    while IFS= read -r r; do
        [[ -z "$r" ]] && continue
        i=$((i+1))
        ROUTE_ARR+=("$r")
        echo -e "  ${CYAN}${i})${NC} $r"
    done <<< "$ROUTES"
    echo ""
    echo -e "  ${GRAY}0) Batal${NC}"
    echo -ne "\n  ${BOLD}Pilih nomor:${NC} "
    read -r NUM

    if [[ "$NUM" == "0" ]] || [[ -z "$NUM" ]]; then
        warn "Dibatalkan"
        return
    fi
    if [[ "$NUM" -lt 1 || "$NUM" -gt "${#ROUTE_ARR[@]}" ]]; then
        fail "Nomor tidak valid"
        return
    fi

    local NETWORK="${ROUTE_ARR[$((NUM-1))]}"
    echo ""
    echo -ne "  ${RED}Yakin hapus route ${NETWORK}? (yes/no):${NC} "
    read -r confirm
    [[ "$confirm" != "yes" ]] && { warn "Dibatalkan"; return; }

    cp "$WG_CONF" "${WG_CONF}.bak"
    local NEW_ROUTES
    NEW_ROUTES=$(echo "$CURRENT" | tr ',' '\n' \
        | grep -v "^${NETWORK}$" \
        | tr '\n' ',' \
        | sed 's/,$//')

    # Update AllowedIPs menggunakan awk - lebih reliable dari sed
    awk -v client="$CLIENT_NAME" -v routes="$NEW_ROUTES" '
        /^# Client: / && $3 == client { found=1 }
        found && /^AllowedIPs/ { $0 = "AllowedIPs = " routes; found=0 }
        { print }
    ' "$WG_CONF" > "${WG_CONF}.tmp" && mv "${WG_CONF}.tmp" "$WG_CONF"

    anim_dots "Mengaplikasikan perubahan"
    local PUB
    PUB=$(cat "${WG_CLIENTS}/${CLIENT_NAME}/public.key" 2>/dev/null || true)
    if wg_is_running && [[ -n "$PUB" ]]; then
        if do_wg_restart; then
            ok "Route ${NETWORK} dihapus!"
            info "AllowedIPs baru: ${NEW_ROUTES}"
            info "Server perlu restart WG - client akan reconnect otomatis"
        else
            fail "Gagal restart WireGuard"
            cp "${WG_CONF}.bak" "$WG_CONF"
        fi
    else
        fail "WireGuard tidak aktif, tidak bisa update route"
    fi
}

# ════════════════════════════════════════════
# CLIENT: SHOW MIKROTIK CONFIG
# ════════════════════════════════════════════
_client_show_mikrotik() {
    local CLIENT_NAME="$1"
    local MT_PRIV MT_IP SERVER_PUB PUBLIC_IP
    MT_PRIV=$(cat "${WG_CLIENTS}/${CLIENT_NAME}/private.key" 2>/dev/null || echo "N/A")
    MT_IP=$(grep -A5 "# Client: $CLIENT_NAME" "$WG_CONF" \
        | grep "AllowedIPs" | head -1 | cut -d'=' -f2 | tr -d ' ' | cut -d',' -f1)
    SERVER_PUB=$(cat /etc/wireguard/server_public.key 2>/dev/null || echo "N/A")
    PUBLIC_IP=$(get_public_ip)

    # Format nama peer - replace dash with space untuk readability
    local PEER_NAME="$CLIENT_NAME"
    PEER_NAME="${PEER_NAME//-/ }"

    echo ""
    echo -e "  ${WHITE}${BOLD}Konfigurasi MikroTik untuk: ${CYAN}${CLIENT_NAME}${NC}"
    hr
    echo -e "  ${GRAY}Paste ke Terminal MikroTik:${NC}"
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo ""
    echo -e "  ${GREEN}/interface wireguard${NC}"
    echo -e "  add name=${CLIENT_NAME} \\"
    echo -e "      listen-port=${SERVER_PORT} \\"
    echo -e "      private-key=\"${MT_PRIV}\""
    echo ""
    echo -e "  ${GREEN}/interface wireguard peers${NC}"
    echo -e "  add interface=${CLIENT_NAME} \\"
    echo -e "      public-key=\"${SERVER_PUB}\" \\"
    echo -e "      endpoint-address=${PUBLIC_IP} \\"
    echo -e "      endpoint-port=${SERVER_PORT} \\"
    echo -e "      allowed-address=0.0.0.0/0 \\"
    echo -e "      persistent-keepalive=25 \\"
    echo -e "      comment=\"WG Peer: ${PEER_NAME}\""
    echo ""
    echo -e "  ${GREEN}/ip address${NC}"
    echo -e "  add address=${MT_IP}/24 \"
    echo -e "      interface=${CLIENT_NAME} \"
    echo -e "      comment=\"${PEER_NAME}\""
    echo ""
    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ════════════════════════════════════════════
# CLIENT: HAPUS CLIENT
# ════════════════════════════════════════════
_client_delete() {
    local CLIENT_NAME="$1"
    echo -ne "  ${RED}⚠  Yakin hapus client '${CLIENT_NAME}'? (yes/no):${NC} "
    read -r confirm
    if [[ "$confirm" != "yes" ]]; then
        warn "Dibatalkan"
        return 1
    fi
    cp "$WG_CONF" "${WG_CONF}.bak"

    # Hapus block client dari config menggunakan awk
    awk -v client="$CLIENT_NAME" '
        /^# Client: / && $3 == client { skip=1; next }
        skip && /^$/ { skip=0; next }
        skip { next }
        { print }
    ' "$WG_CONF" > "${WG_CONF}.tmp" && mv "${WG_CONF}.tmp" "$WG_CONF"
    
    rm -rf "${WG_CLIENTS:?}/${CLIENT_NAME}"

    anim_dots "Menghapus client"
    if do_wg_restart; then
        ok "Client '${CLIENT_NAME}' berhasil dihapus!"
        return 0
    else
        fail "Gagal restart WireGuard"
        return 1
    fi
}

# ════════════════════════════════════════════
# MENU CLIENT (pilih dari list)
# ════════════════════════════════════════════
menu_client() {
    while true; do
        show_banner
        echo -e "  ${WHITE}${BOLD}[ MENU CLIENT ]${NC}"
        hr

        list_clients_inline || true

        echo -e "  ${GREEN}N)${NC} ${WHITE}Tambah Client Baru${NC}"
        echo ""
        echo -e "  ${GRAY}Ketik nomor client untuk detail & route management${NC}"
        echo -e "  ${GRAY}0) Kembali ke Menu Utama${NC}"
        hr
        echo -ne "\n  ${BOLD}Pilihan:${NC} "
        read -r choice
        echo ""

        case "$choice" in
            0) return ;;
            [Nn])
                add_client
                echo ""
                echo -ne "  ${GRAY}ENTER untuk lanjut...${NC}"
                read -r
                ;;
            ''|*[!0-9]*)
                warn "Pilihan tidak valid"
                sleep 1
                ;;
            *)
                local i=0
                local TARGET=""
                for dir in "${WG_CLIENTS}"/*/; do
                    i=$((i+1))
                    if [[ "$i" == "$choice" ]]; then
                        TARGET=$(basename "$dir")
                        break
                    fi
                done
                if [[ -z "$TARGET" ]]; then
                    warn "Nomor tidak valid"
                    sleep 1
                else
                    client_detail "$TARGET"
                fi
                ;;
        esac
    done
}

# ════════════════════════════════════════════
# ADD CLIENT
# ════════════════════════════════════════════
add_client() {
    show_banner
    echo -e "  ${WHITE}${BOLD}[ TAMBAH CLIENT BARU ]${NC}"
    hr
    echo ""
    echo -ne "  ${YELLOW}Nama client (contoh: mt-malang):${NC} "
    read -r CLIENT_NAME
    CLIENT_NAME=$(echo "$CLIENT_NAME" | tr -cd '[:alnum:]-_')
    if [[ -z "$CLIENT_NAME" ]]; then
        fail "Nama tidak boleh kosong!"
        return
    fi
    if client_exists "$CLIENT_NAME"; then
        fail "Client '${CLIENT_NAME}' sudah ada!"
        return
    fi

    echo ""
    info "Generate keys untuk: ${CLIENT_NAME}"
    progress_bar "Generating keypair" 0.8

    cp "$WG_CONF" "${WG_CONF}.bak" 2>/dev/null || true

    local MT_PRIV MT_PUB SERVER_PUB CLIENT_IP PUBLIC_IP
    MT_PRIV=$(wg genkey)
    MT_PUB=$(echo "$MT_PRIV" | wg pubkey)
    SERVER_PUB=$(cat /etc/wireguard/server_public.key)
    CLIENT_IP=$(get_mt_ip)
    PUBLIC_IP=$(get_public_ip)

    mkdir -p "${WG_CLIENTS}/${CLIENT_NAME}"
    echo "$MT_PRIV" > "${WG_CLIENTS}/${CLIENT_NAME}/private.key"
    echo "$MT_PUB"  > "${WG_CLIENTS}/${CLIENT_NAME}/public.key"
    chmod 600 "${WG_CLIENTS}/${CLIENT_NAME}/private.key"

    cat >> "$WG_CONF" <<EOF

# Client: ${CLIENT_NAME}
[Peer]
PublicKey = ${MT_PUB}
AllowedIPs = ${CLIENT_IP}/32
EOF

    anim_dots "Restart WireGuard"
    if ! do_wg_restart; then
        fail "Gagal restart WireGuard!"
        return
    fi

    sep
    echo -e "  ${GREEN}${BOLD}✔ Client '${CLIENT_NAME}' berhasil dibuat!${NC}"
    echo -e "  ${GRAY}IP WireGuard: ${CYAN}${CLIENT_IP}/32${NC}"
    echo ""

    _client_show_mikrotik "$CLIENT_NAME"
}

# ════════════════════════════════════════════
# UNINSTALL
# ════════════════════════════════════════════
do_uninstall() {
    show_banner
    echo -e "  ${RED}${BOLD}[ UNINSTALL WIREGUARD ]${NC}"
    hr
    echo ""
    warn "Semua config & client akan DIHAPUS PERMANEN!"
    echo ""
    echo -ne "  ${RED}Ketik 'HAPUS' untuk konfirmasi:${NC} "
    read -r confirm
    if [[ "$confirm" != "HAPUS" ]]; then
        warn "Dibatalkan"
        return
    fi
    echo ""
    anim_dots "Menghapus WireGuard"
    wg-quick down wg0 2>/dev/null || true
    systemctl disable wg-quick@wg0 2>/dev/null || true
    rm -rf /etc/wireguard
    # Hapus isi cron job WireGuard tapi file tetap ada
    > /etc/cron.d/wg-routes
    apt-get purge -y wireguard wireguard-tools 2>/dev/null || true
    ok "WireGuard berhasil diuninstall"
    echo ""
}

# ════════════════════════════════════════════
# MAIN MENU
# ════════════════════════════════════════════
main_menu() {
    check_root
    while true; do
        show_banner

        if wg_is_installed; then
            if wg_is_running; then
                echo -e "  ${GREEN}● WireGuard  :  AKTIF${NC}   ${GRAY}│${NC}  Clients: ${CYAN}$(count_clients)${NC}   ${GRAY}│${NC}  Port: ${CYAN}${SERVER_PORT}${NC}"
            else
                echo -e "  ${YELLOW}◐ WireGuard  :  TERPASANG tapi TIDAK AKTIF${NC}"
            fi
        else
            echo -e "  ${RED}○ WireGuard  :  BELUM TERPASANG${NC}"
        fi

        sep
        echo -e "  ${GREEN}1)${NC}  ${WHITE}Install WireGuard Server${NC}"
        echo -e "  ${GREEN}2)${NC}  ${WHITE}Menu Client${NC}           ${GRAY}(tambah, detail, route)${NC}"
        echo -e "  ${GREEN}3)${NC}  ${WHITE}Kontrol WireGuard${NC}     ${GRAY}(aktif/matikan/restart)${NC}"
        echo -e "  ${GREEN}4)${NC}  ${WHITE}Lihat Status & Peers${NC}"
        echo -e "  ${RED}5)${NC}  ${WHITE}Uninstall${NC}"
        echo ""
        echo -e "  ${GRAY}0) Keluar${NC}"
        hr
        echo -ne "\n  ${BOLD}Pilihan:${NC} "
        read -r choice
        echo ""

        case $choice in
            1)
                if wg_is_installed; then
                    warn "WireGuard sudah terinstall! Gunakan menu Kontrol."
                else
                    do_install
                fi
                ;;
            2)
                if ! wg_is_installed; then
                    fail "WireGuard belum terinstall!"
                else
                    menu_client
                fi
                ;;
            3)
                if ! wg_is_installed; then
                    fail "WireGuard belum terinstall!"
                else
                    menu_control
                fi
                ;;
            4)
                if ! wg_is_installed; then
                    fail "WireGuard belum terinstall!"
                else
                    show_status
                fi
                ;;
            5) do_uninstall ;;
            0)
                echo -e "  ${GRAY}Sampai jumpa! — SolusiDigitalNet${NC}"
                echo ""
                exit 0
                ;;
            *) warn "Pilihan tidak valid" ;;
        esac

        echo ""
        echo -ne "  ${GRAY}ENTER untuk kembali ke menu...${NC}"
        read -r
    done
}

# ════════════════════════════════════════════
main_menu
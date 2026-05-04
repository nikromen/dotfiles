#!/bin/bash
# shellcheck disable=SC2001

source "$HOME/.local/lib/help.sh"

check_help "$1" && show_help "unified network manager (WiFi, VPN, Wired, Bluetooth)" \
    "Interactive TUI for managing all network connections.

Tabs: F1 WiFi | F2 VPN | F3 Wired | F4 Bluetooth
Start on a specific tab: network.sh [wifi|vpn|wired|bt]

Actions: Enter to connect/disconnect, typed text filters the list.
Press Escape or Ctrl+C to close." && exit 0

# ── Colors ────────────────────────────────────────────────────────────

GREEN=$'\033[32m'
RED=$'\033[31m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

notify_cmd="notify-send -t 3000"

# ── WiFi ──────────────────────────────────────────────────────────────

wifi_signal_icon() {
    local s=$1
    if (( s >= 75 )); then echo "󰤨"
    elif (( s >= 50 )); then echo "󰤥"
    elif (( s >= 25 )); then echo "󰤢"
    else echo "󰤟"; fi
}

get_wifi_list() {
    nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list --rescan no 2>/dev/null \
        | awk -F: '$1 != ""' | sort -t: -k2 -rn \
        | awk -F: '!seen[$1]++' \
        | while IFS=: read -r ssid signal security in_use; do
            local icon
            icon=$(wifi_signal_icon "$signal")
            local lock=""
            [[ -n "$security" && "$security" != "--" ]] && lock=" 🔒"
            if [[ "$in_use" == "*" ]]; then
                printf "%s▰ %s %s (%s%%)%s%s\n" "$GREEN" "$icon" "$ssid" "$signal" "$lock" "$RESET"
            else
                printf "  %s %s (%s%%)%s\n" "$icon" "$ssid" "$signal" "$lock"
            fi
        done
    printf "%s  ↻ Rescan networks%s\n" "$DIM" "$RESET"
    printf "%s  ✕ Disconnect WiFi%s\n" "$DIM" "$RESET"
}

handle_wifi() {
    local sel="$1"
    sel=$(echo "$sel" | sed 's/\x1b\[[0-9;]*m//g')

    case "$sel" in
        *"↻ Rescan"*)
            $notify_cmd "WiFi" "Scanning..."
            nmcli dev wifi rescan 2>/dev/null
            sleep 1
            ;;
        *"✕ Disconnect"*)
            nmcli dev disconnect wlan0 2>/dev/null || nmcli dev disconnect wifi 2>/dev/null
            $notify_cmd "WiFi" "Disconnected"
            ;;
        *)
            local ssid
            ssid=$(echo "$sel" | sed 's/^[▰ ]*//' | sed 's/^[^ ]* //' | sed 's/ ([0-9]*%).*//')
            local saved
            saved=$(nmcli -t -f NAME con show 2>/dev/null | grep -qx "$ssid" && echo "yes" || echo "no")

            local output rc
            if [[ "$saved" == "yes" ]]; then
                output=$(nmcli con up "$ssid" 2>&1)
                rc=$?
            else
                local security
                security=$(nmcli -t -f SSID,SECURITY dev wifi list --rescan no 2>/dev/null \
                    | grep "^${ssid}:" | head -1 | cut -d: -f2)

                if [[ -n "$security" && "$security" != "--" ]]; then
                    echo ""
                    printf "%sPassword for %s (Esc=cancel):%s " "$BOLD" "$ssid" "$RESET"
                    password=""
                    while IFS= read -rsn1 char; do
                        if [[ "$char" == $'\x1b' ]]; then
                            password=""
                            break
                        elif [[ "$char" == "" ]]; then
                            break
                        elif [[ "$char" == $'\x7f' || "$char" == $'\b' ]]; then
                            if [ -n "$password" ]; then
                                password="${password%?}"
                                printf '\b \b'
                            fi
                        else
                            password+="$char"
                            printf '*'
                        fi
                    done
                    echo ""
                    if [ -z "$password" ]; then
                        return
                    fi
                    output=$(nmcli dev wifi connect "$ssid" password "$password" 2>&1)
                    rc=$?
                    unset password
                else
                    output=$(nmcli dev wifi connect "$ssid" 2>&1)
                    rc=$?
                fi
            fi

            if [ "$rc" -eq 0 ]; then
                $notify_cmd "WiFi" "Connected to $ssid"
            else
                printf "\n%s✕ Connection failed:%s %s\n" "$RED" "$RESET" "$output"
                printf "%sPress Enter to continue...%s" "$DIM" "$RESET"
                read -r
            fi
            ;;
    esac
}

# ── VPN ───────────────────────────────────────────────────────────────

get_vpn_list() {
    nmcli -t -f NAME,TYPE,STATE con show 2>/dev/null \
        | while IFS=: read -r name type state; do
            [[ "$type" != *vpn* && "$type" != *wireguard* ]] && continue
            if [[ "$state" == "activated" ]]; then
                printf "%s▰ 󰌆 %s%s\n" "$GREEN" "$name" "$RESET"
            else
                printf "  󰌊 %s\n" "$name"
            fi
        done
    if ! nmcli -t -f TYPE con show 2>/dev/null | grep -qE 'vpn|wireguard'; then
        printf "%s  (no VPN connections configured)%s\n" "$DIM" "$RESET"
    fi
}

handle_vpn() {
    local sel="$1"
    sel=$(echo "$sel" | sed 's/\x1b\[[0-9;]*m//g')
    [[ "$sel" == *"no VPN"* ]] && return

    local name
    name=$(echo "$sel" | sed 's/^[▰ ]*//' | sed 's/^[󰌆󰌊] //')
    local state
    state=$(nmcli -t -f NAME,STATE con show 2>/dev/null | grep "^${name}:" | cut -d: -f2)

    if [[ "$state" == "activated" ]]; then
        nmcli con down "$name" && $notify_cmd "VPN" "Disconnected $name"
    else
        echo ""
        printf "%sConnecting to %s...%s\n" "$BOLD" "$name" "$RESET"
        local output
        if output=$(nmcli con up "$name" 2>&1); then
            $notify_cmd "VPN" "Connected $name"
        else
            printf "%sPassword for %s (Esc=cancel):%s " "$BOLD" "$name" "$RESET"
            vpn_password=""
            while IFS= read -rsn1 char; do
                if [[ "$char" == $'\x1b' ]]; then
                    vpn_password=""
                    break
                elif [[ "$char" == "" ]]; then
                    break
                elif [[ "$char" == $'\x7f' || "$char" == $'\b' ]]; then
                    if [ -n "$vpn_password" ]; then
                        vpn_password="${vpn_password%?}"
                        printf '\b \b'
                    fi
                else
                    vpn_password+="$char"
                    printf '*'
                fi
            done
            echo ""
            if [ -z "$vpn_password" ]; then
                return
            fi
            output=$(nmcli --ask con up "$name" <<< "$vpn_password" 2>&1)
            rc=$?
            unset vpn_password
            if [ "$rc" -eq 0 ]; then
                $notify_cmd "VPN" "Connected $name"
            else
                printf "\n%s✕ Connection failed:%s %s\n" "$RED" "$RESET" "$output"
                printf "%sPress Enter to continue...%s" "$DIM" "$RESET"
                read -r
            fi
        fi
    fi
}

# ── Wired ─────────────────────────────────────────────────────────────

get_wired_list() {
    local active_names
    active_names=$(nmcli -t -f NAME,TYPE,STATE con show --active 2>/dev/null \
        | awk -F: '$2 ~ /ethernet/ {print $1}')

    nmcli -t -f NAME,TYPE,DEVICE con show --active 2>/dev/null \
        | while IFS=: read -r name type device; do
            [[ "$type" != *ethernet* ]] && continue
            printf "%s▰ 󰈀 %s (%s)%s\n" "$GREEN" "$name" "$device" "$RESET"
        done

    nmcli -t -f NAME,TYPE con show 2>/dev/null \
        | while IFS=: read -r name type; do
            [[ "$type" != *ethernet* ]] && continue
            echo "$active_names" | grep -qx "$name" && continue
            printf "  󰈀 %s\n" "$name"
        done

    if ! nmcli -t -f TYPE con show 2>/dev/null | grep -q 'ethernet'; then
        printf "%s  (no wired connections)%s\n" "$DIM" "$RESET"
    fi
}

handle_wired() {
    local sel="$1"
    sel=$(echo "$sel" | sed 's/\x1b\[[0-9;]*m//g')
    [[ "$sel" == *"no wired"* ]] && return

    local name
    name=$(echo "$sel" | sed 's/^[▰ ]*//' | sed 's/^󰈀 //' | sed 's/ (.*)$//')

    if [[ "$sel" == *"▰"* ]]; then
        nmcli con down "$name" && $notify_cmd "Wired" "Disconnected $name"
    else
        nmcli con up "$name" && $notify_cmd "Wired" "Connected $name"
    fi
}

# ── Bluetooth ─────────────────────────────────────────────────────────

bt_device_icon() {
    case "$1" in
        *headset*|*headphone*|*audio*) echo "󰋋" ;;
        *keyboard*)                    echo "󰌌" ;;
        *mouse*|*pointing*)            echo "󰍽" ;;
        *phone*)                       echo "󰏲" ;;
        *computer*)                    echo "󰍹" ;;
        *)                             echo "󰂯" ;;
    esac
}

get_bt_list() {
    local power
    power=$(bluetoothctl show < /dev/null 2>/dev/null | grep -q "Powered: yes" && echo "on" || echo "off")

    while read -r _ mac name; do
        local info icon_type icon connected
        info=$(bluetoothctl info "$mac" < /dev/null 2>/dev/null)
        icon_type=$(echo "$info" | grep "Icon:" | awk '{print $2}')
        icon=$(bt_device_icon "$icon_type")
        connected=$(echo "$info" | grep -q "Connected: yes" && echo "yes" || echo "no")

        if [[ "$connected" == "yes" ]]; then
            printf "%s▰ %s %s%s\n" "$GREEN" "$icon" "$name" "$RESET"
        else
            printf "  %s %s\n" "$icon" "$name"
        fi
    done < <(bluetoothctl devices Paired < /dev/null 2>/dev/null)

    printf "%s  ↻ Scan for devices%s\n" "$DIM" "$RESET"
    if [[ "$power" == "on" ]]; then
        printf "%s  ⏻ Turn bluetooth off%s\n" "$DIM" "$RESET"
    else
        printf "%s%s  ⏻ Turn bluetooth on%s\n" "$RED" "$BOLD" "$RESET"
    fi
}

handle_bt() {
    local sel="$1"
    sel=$(echo "$sel" | sed 's/\x1b\[[0-9;]*m//g')

    case "$sel" in
        *"↻ Scan"*)
            $notify_cmd "Bluetooth" "Scanning (2s)..."
            bluetoothctl --timeout 2 scan on < /dev/null &>/dev/null
            ;;
        *"⏻ Turn bluetooth off"*)
            bluetoothctl power off < /dev/null &>/dev/null
            $notify_cmd "Bluetooth" "Powered off"
            ;;
        *"⏻ Turn bluetooth on"*)
            bluetoothctl power on < /dev/null &>/dev/null
            $notify_cmd "Bluetooth" "Powered on"
            ;;
        *)
            local device_name mac info
            device_name=$(echo "$sel" | sed 's/^[▰ ]*//' | sed 's/^[^ ]* //')
            mac=$(bluetoothctl devices Paired < /dev/null 2>/dev/null | grep "$device_name" | head -1 | awk '{print $2}')
            [ -z "$mac" ] && return

            info=$(bluetoothctl info "$mac" < /dev/null 2>/dev/null)
            if echo "$info" | grep -q "Connected: yes"; then
                if bluetoothctl disconnect "$mac" < /dev/null &>/dev/null; then
                    $notify_cmd "Bluetooth" "Disconnected $device_name"
                else
                    $notify_cmd -u critical "Bluetooth" "Failed to disconnect"
                fi
            else
                if bluetoothctl connect "$mac" < /dev/null &>/dev/null; then
                    $notify_cmd "Bluetooth" "Connected $device_name"
                else
                    $notify_cmd -u critical "Bluetooth" "Failed to connect"
                fi
            fi
            ;;
    esac
}

# ── Tab bar & main loop ──────────────────────────────────────────────

tab_header() {
    local active="$1"
    local w=" F1:WiFi " v=" F2:VPN " e=" F3:Wired " b=" F4:BT "

    case "$active" in
        wifi)  w="[F1:WiFi]" ;;
        vpn)   v="[F2:VPN]" ;;
        wired) e="[F3:Wired]" ;;
        bt)    b="[F4:BT]" ;;
    esac

    echo "$w  $v  $e  $b"
}

build_menu() {
    case "$1" in
        wifi)  get_wifi_list ;;
        vpn)   get_vpn_list ;;
        wired) get_wired_list ;;
        bt)    get_bt_list ;;
    esac
}

run_tui() {
    local tab="$1"
    while true; do
        local header
        header=$(tab_header "$tab")

        local result
        result=$(build_menu "$tab" | fzf --ansi \
            --header="$header" \
            --expect=f1,f2,f3,f4 \
            --prompt="Network> " \
            --no-info \
            --reverse \
            --no-sort)

        local key selection
        key=$(head -1 <<< "$result")
        selection=$(sed -n '2p' <<< "$result")

        case "$key" in
            f1) tab="wifi"; continue ;;
            f2) tab="vpn"; continue ;;
            f3) tab="wired"; continue ;;
            f4) tab="bt"; continue ;;
        esac

        [ -z "$selection" ] && break

        case "$tab" in
            wifi)  handle_wifi "$selection" ;;
            vpn)   handle_vpn "$selection" ;;
            wired) handle_wired "$selection" ;;
            bt)    handle_bt "$selection" ;;
        esac
    done
}

# ── Entry point ───────────────────────────────────────────────────────

if [[ "$1" == "--tui" ]]; then
    shift
    run_tui "${1:-wifi}"
    exit 0
fi

tab="${1:-wifi}"
case "$tab" in
    wifi|vpn|wired|bt) ;;
    *) tab="wifi" ;;
esac

exec alacritty --title rofi-network -e "$(readlink -f "$0")" --tui "$tab"

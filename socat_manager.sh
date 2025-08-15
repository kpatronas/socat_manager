#!/bin/bash

# ---- Logging helper ----
log() {
    local level="$1"
    shift
    printf "%s [%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*"
}

listeners_file="/tmp/socat_listeners"
config_file="${1:-config}"  # Use argument or default to 'config'

# ---- Check for socat ----
if ! command -v socat >/dev/null 2>&1; then
    log "ERROR" "socat command not found. Please install socat and retry."
    exit 1
fi

# ---- Check for config file ----
if [[ ! -f "$config_file" ]]; then
    log "ERROR" "Config file '$config_file' not found"
    exit 1
fi

# ---- Refresh listeners list ----
lsof -iTCP -sTCP:LISTEN -n -P \
    | tr -s " " \
    | grep "(LISTEN)" \
    | cut -d " " -f1,9 > "$listeners_file"

# ---- Process config ----
while read -r name target listen; do
    # Skip empty or comment lines
    [[ -z "$name" || "$name" =~ ^# ]] && continue

    target_port="${target##*:}"
    listen_port="${listen##*:}"
    target_ip="${target%:*}"

    log "INFO" "Checking mapping: ${name} ${target} ${listen}"

    if grep -Fq "$name $target" "$listeners_file"; then
        if pgrep -f "socat TCP-LISTEN:${listen_port},fork,reuseaddr TCP:${target_ip}:${target_port}" >/dev/null; then
            log "INFO" "Already running: socat TCP-LISTEN:${listen_port},fork,reuseaddr TCP:${target_ip}:${target_port}"
            continue
        fi
        log "INFO" "Starting socat: TCP-LISTEN:${listen_port},fork,reuseaddr TCP:${target_ip}:${target_port}"
        nohup socat TCP-LISTEN:${listen_port},fork,reuseaddr TCP:${target_ip}:${target_port} >/dev/null 2>&1 &
    else
        log "WARNING" "Target not found: ${name} ${target}"
        pid=$(pgrep -f "socat TCP-LISTEN:${listen_port},fork,reuseaddr TCP:${target_ip}:${target_port}")
        if [ -n "$pid" ]; then
            log "WARNING" "Stopping socat on ${listen_port} (target ${target_ip}:${target_port} not found)"
            kill "$pid"
        fi
    fi
done < "$config_file"


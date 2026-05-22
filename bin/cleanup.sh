#!/usr/bin/env bash
#
# cleanup.sh — Kill zombie processes, stale tmux sessions, and orphaned daemons
#
# Usage:
#   cleanup.sh              Interactive mode (asks before killing)
#   cleanup.sh --dry-run    Show what would be cleaned, change nothing
#   cleanup.sh --force      Kill everything without asking
#

set -euo pipefail

MODE="interactive"
[[ "${1:-}" == "--dry-run" ]] && MODE="dry-run"
[[ "${1:-}" == "--force" ]]   && MODE="force"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ─────────────────────────────────────────────────────────────────
info()    { printf "${CYAN}▸${RESET} %s\n" "$*"; }
success() { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn()    { printf "${YELLOW}!${RESET} %s\n" "$*"; }
header()  { printf "\n${BOLD}── %s ──${RESET}\n" "$*"; }
dim()     { printf "${DIM}  %s${RESET}\n" "$*"; }

confirm() {
    [[ "$MODE" == "force" ]] && return 0
    [[ "$MODE" == "dry-run" ]] && return 1
    printf "${YELLOW}  → %s [y/N] ${RESET}" "$1"
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

killed_pids=0
killed_sessions=0

# ── 1. Zombie Processes ────────────────────────────────────────────────────
header "Zombie Processes"

zombies=$(ps axo pid,ppid,state,comm | awk '$3 ~ /Z/ && $1 != "PID" {print $0}')
if [[ -n "$zombies" ]]; then
    echo "$zombies" | while read -r zpid zppid zstate zcomm; do
        warn "Zombie: PID $zpid (parent $zppid) — $zcomm"
    done
    if confirm "Kill zombie parent processes to reap them?"; then
        echo "$zombies" | while read -r zpid zppid _ _; do
            kill -HUP "$zppid" 2>/dev/null && killed_pids=$((killed_pids + 1))
        done
        success "Sent SIGHUP to zombie parents"
    fi
else
    success "No zombie processes found"
fi

# ── 2. Stale Tmux Sessions ─────────────────────────────────────────────────
header "Detached Tmux Sessions"

current_session=""
if [[ -n "${TMUX:-}" ]]; then
    current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
fi

# Protected sessions: the attached one + the main repo session
protected_sessions=("$current_session" "gondor")

stale_sessions=()
while IFS=: read -r name attached; do
    [[ "$attached" == "1" ]] && continue

    is_protected=false
    for p in "${protected_sessions[@]}"; do
        [[ "$name" == "$p" ]] && is_protected=true && break
    done
    $is_protected && continue

    stale_sessions+=("$name")
done < <(tmux list-sessions -F '#{session_name}:#{session_attached}' 2>/dev/null)

if [[ ${#stale_sessions[@]} -gt 0 ]]; then
    # Compute CPU cost of stale sessions
    total_cpu=0
    for session in "${stale_sessions[@]}"; do
        # Get all pids in this session's panes
        pane_pids=$(tmux list-panes -s -t "$session" -F '#{pane_pid}' 2>/dev/null || true)
        session_cpu=0
        for ppid in $pane_pids; do
            # Sum CPU of the pane process and its children
            cpu=$(ps -o %cpu= -p "$ppid" 2>/dev/null | tr -d ' ' || echo "0")
            child_cpu=$(pgrep -P "$ppid" 2>/dev/null | xargs -I{} ps -o %cpu= -p {} 2>/dev/null | awk '{s+=$1}END{printf "%.1f",s}' || echo "0")
            session_cpu=$(echo "$session_cpu + $cpu + $child_cpu" | bc 2>/dev/null || echo "$session_cpu")
        done
        total_cpu=$(echo "$total_cpu + $session_cpu" | bc 2>/dev/null || echo "$total_cpu")

        if (( $(echo "$session_cpu > 0.5" | bc -l 2>/dev/null || echo 0) )); then
            warn "$(printf '%-55s %s' "$session" "${RED}${session_cpu}% CPU${RESET}")"
        else
            dim "$session"
        fi
    done

    printf "\n"
    info "${#stale_sessions[@]} detached sessions using ~${total_cpu}% CPU total"

    if confirm "Kill all ${#stale_sessions[@]} detached sessions? (protects: gondor + attached)"; then
        for session in "${stale_sessions[@]}"; do
            # Try to resolve worktree path from session's starting directory
            session_path=$(tmux display-message -p -t "$session" '#{session_path}' 2>/dev/null || true)

            # Kill processes tied to that worktree path (nvim, LSPs, vite, etc.)
            if [[ -n "$session_path" ]]; then
                escaped_path=$(printf '%s' "$session_path" | sed 's/[.[\(*^$+?{|]/\\&/g')
                stale_pids=$(pgrep -f "$escaped_path" 2>/dev/null | grep -v "^$$\$" || true)
                if [[ -n "$stale_pids" ]]; then
                    echo "$stale_pids" | xargs kill 2>/dev/null || true
                    sleep 0.2
                    echo "$stale_pids" | xargs kill -9 2>/dev/null || true
                fi
            fi

            tmux kill-session -t "$session" 2>/dev/null || true
            killed_sessions=$((killed_sessions + 1))
        done
        success "Killed $killed_sessions tmux sessions"
    fi
else
    success "No stale tmux sessions"
fi

# ── 3. Orphaned Processes ──────────────────────────────────────────────────
header "Orphaned Heavy Processes"

# Find nvim instances not inside any surviving tmux session
surviving_pane_pids=""
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null; then
    surviving_pane_pids=$(tmux list-panes -a -F '#{pane_pid}' 2>/dev/null | tr '\n' '|' | sed 's/|$//')
fi

orphan_nvims=()
while read -r pid cpu mem elapsed cmd; do
    [[ -z "$pid" ]] && continue
    # Skip if this nvim is owned by a surviving tmux pane
    if [[ -n "$surviving_pane_pids" ]]; then
        ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        if echo "$ppid" | grep -qE "^($surviving_pane_pids)$" 2>/dev/null; then
            continue
        fi
    fi
    orphan_nvims+=("$pid|$cpu|$mem|$elapsed")
done < <(pgrep -f "nvim --embed" 2>/dev/null | xargs -I{} ps -o pid=,pcpu=,pmem=,etime=,comm= -p {} 2>/dev/null)

if [[ ${#orphan_nvims[@]} -gt 0 ]]; then
    for entry in "${orphan_nvims[@]}"; do
        IFS='|' read -r pid cpu mem elapsed <<< "$entry"
        warn "nvim PID $pid — CPU: ${cpu}%, MEM: ${mem}%, running: $elapsed"
    done
    if confirm "Kill ${#orphan_nvims[@]} orphaned nvim processes?"; then
        for entry in "${orphan_nvims[@]}"; do
            pid="${entry%%|*}"
            kill "$pid" 2>/dev/null || true
        done
        success "Killed ${#orphan_nvims[@]} orphaned nvim instances"
    fi
else
    success "No orphaned nvim processes"
fi

# ── 4. Background Daemons ──────────────────────────────────────────────────
header "Background Daemons"

# Check redis
redis_pid=$(pgrep -x "redis-server" 2>/dev/null || true)
if [[ -n "$redis_pid" ]]; then
    redis_uptime=$(ps -o etime= -p "$redis_pid" 2>/dev/null | tr -d ' ')
    redis_cpu=$(ps -o %cpu= -p "$redis_pid" 2>/dev/null | tr -d ' ')
    warn "redis-server PID $redis_pid — CPU: ${redis_cpu}%, uptime: $redis_uptime"
    if confirm "Stop redis-server?"; then
        redis-cli shutdown nosave 2>/dev/null || kill "$redis_pid" 2>/dev/null || true
        success "Stopped redis-server"
    fi
else
    success "No stray redis-server"
fi

# Check for orphaned node processes (vite, tsserver, etc.) not in tmux
orphan_nodes=()
while read -r line; do
    [[ -z "$line" ]] && continue
    pid=$(echo "$line" | awk '{print $1}')
    # Skip if owned by a surviving tmux pane
    if [[ -n "$surviving_pane_pids" ]]; then
        ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        if echo "$ppid" | grep -qE "^($surviving_pane_pids)$" 2>/dev/null; then
            continue
        fi
    fi
    orphan_nodes+=("$line")
done < <(ps axo pid,%cpu,%mem,etime,command | grep -E "(vite|tsserver|webpack|esbuild|turbopack)" | grep -v grep | awk '$2 > 1.0')

if [[ ${#orphan_nodes[@]} -gt 0 ]]; then
    for line in "${orphan_nodes[@]}"; do
        pid=$(echo "$line" | awk '{print $1}')
        cpu=$(echo "$line" | awk '{print $2}')
        cmd=$(echo "$line" | awk '{for(i=5;i<=NF;i++) printf "%s ", $i; print ""}' | head -c 80)
        warn "PID $pid — CPU: ${cpu}% — $cmd"
    done
    if confirm "Kill ${#orphan_nodes[@]} orphaned node dev processes?"; then
        for line in "${orphan_nodes[@]}"; do
            pid=$(echo "$line" | awk '{print $1}')
            kill "$pid" 2>/dev/null || true
        done
        success "Killed orphaned node processes"
    fi
else
    success "No orphaned node dev processes"
fi

# ── 5. Memory Pressure ─────────────────────────────────────────────────────
header "System Overview"

load=$(sysctl -n vm.loadavg 2>/dev/null | tr -d '{}')
mem_pressure=$(memory_pressure 2>/dev/null | tail -1 || echo "unknown")

info "Load average: $load"
info "Memory: $mem_pressure"
info "Battery: $(pmset -g batt 2>/dev/null | grep -o '[0-9]*%.*' || echo 'unknown')"

# ── Summary ─────────────────────────────────────────────────────────────────
header "Done"
if [[ "$MODE" == "dry-run" ]]; then
    info "Dry run — nothing was changed. Run without --dry-run to clean up."
else
    success "Cleanup complete"
fi

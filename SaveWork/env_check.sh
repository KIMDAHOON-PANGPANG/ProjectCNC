#!/usr/bin/env bash
# env_check.sh — Claude 다음 세션용 환경 자동 검출 + 검증 명령 출력.
#
# 사용:
#   bash SaveWork/env_check.sh           # 검출 결과 출력
#   bash SaveWork/env_check.sh --export  # export 줄만 출력 (source용)
#   bash SaveWork/env_check.sh --verify  # 검출 + §I-7 3단계 검증 자동 실행
#
# OS 자동 분기: Windows (git-bash/MSYS) / macOS / Linux

set -e

MODE="${1:-status}"
PROJECT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── OS 검출 ─────────────────────────────────────────────────
case "$(uname -s)" in
    CYGWIN*|MINGW*|MSYS*) OS="windows" ;;
    Darwin*)              OS="macos" ;;
    Linux*)               OS="linux" ;;
    *)                    OS="unknown" ;;
esac

# ── Godot CLI 검출 ──────────────────────────────────────────
GODOT_BIN=""
GODOT_CANDIDATES=()

case "$OS" in
    windows)
        # git-bash에서는 $USER가 비어있을 수 있음 → $USERNAME 또는 $HOME 사용
        WIN_USER="${USERNAME:-$(basename "$HOME")}"
        # 1) PATH
        if command -v godot >/dev/null 2>&1; then
            GODOT_BIN="$(command -v godot)"
        fi
        # 2) 흔한 위치들
        GODOT_CANDIDATES=(
            "$HOME/Desktop/Godot_v4.7-dev2_win64.exe/Godot_v4.7-dev2_win64_console.exe"
            "$HOME/Desktop/Godot_v4.7-dev2_win64_console.exe"
            "$HOME/Desktop/Godot_v4.7-dev2_win64.exe"
            "/c/Users/$WIN_USER/Desktop/Godot_v4.7-dev2_win64.exe/Godot_v4.7-dev2_win64_console.exe"
            "/c/Program Files/Godot/Godot.exe"
            "/c/Program Files/Godot Engine/Godot.exe"
            "/c/Godot/Godot.exe"
        )
        # 3) Desktop glob — 정확한 버전 알 수 없을 때
        if [ -z "$GODOT_BIN" ]; then
            for f in "$HOME"/Desktop/Godot*win64*console.exe "$HOME"/Desktop/Godot*/Godot*console.exe; do
                if [ -f "$f" ]; then
                    GODOT_BIN="$f"
                    break
                fi
            done
        fi
        ;;
    macos)
        if command -v godot >/dev/null 2>&1; then
            GODOT_BIN="$(command -v godot)"
        fi
        GODOT_CANDIDATES=(
            "/Applications/Godot.app/Contents/MacOS/Godot"
            "$HOME/Applications/Godot.app/Contents/MacOS/Godot"
            "/Applications/Godot_v4.7-dev2.app/Contents/MacOS/Godot"
        )
        ;;
    linux)
        if command -v godot >/dev/null 2>&1; then
            GODOT_BIN="$(command -v godot)"
        fi
        GODOT_CANDIDATES=(
            "/usr/bin/godot"
            "/usr/local/bin/godot"
            "$HOME/godot/Godot_v4.7-dev2_linux.x86_64"
            "$HOME/.local/bin/godot"
        )
        ;;
esac

if [ -z "$GODOT_BIN" ]; then
    for candidate in "${GODOT_CANDIDATES[@]}"; do
        if [ -x "$candidate" ] || [ -f "$candidate" ]; then
            GODOT_BIN="$candidate"
            break
        fi
    done
fi

# ── 사용자 데이터 경로 (CSV / godot.log) ────────────────────
case "$OS" in
    windows)
        # APPDATA는 Windows path(C:\...) 형식 — git-bash에서 사용하려면 변환.
        if [ -n "$APPDATA" ]; then
            if command -v cygpath >/dev/null 2>&1; then
                APPDATA_BASH="$(cygpath -u "$APPDATA")"
            else
                # 수동 변환: C:\Users\... → /c/Users/...
                APPDATA_BASH="$(echo "$APPDATA" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\):|/\L\1|')"
            fi
            USERDATA="$APPDATA_BASH/Godot/app_userdata/ProjectCNC"
        else
            USERDATA="$HOME/AppData/Roaming/Godot/app_userdata/ProjectCNC"
        fi
        ;;
    macos)
        USERDATA="$HOME/Library/Application Support/Godot/app_userdata/ProjectCNC"
        ;;
    linux)
        USERDATA="$HOME/.local/share/godot/app_userdata/ProjectCNC"
        ;;
    *)
        USERDATA=""
        ;;
esac

CSV_PATH="$USERDATA/session_log.csv"
GODOT_LOG="$USERDATA/logs/godot.log"

# ── Python 검출 ─────────────────────────────────────────────
PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python)"
fi

# ── 출력 모드 분기 ──────────────────────────────────────────
emit_export() {
    [ -n "$GODOT_BIN" ]    && echo "export GODOT_BIN=\"$GODOT_BIN\""
    echo "export PROJECT_PATH=\"$PROJECT_PATH\""
    [ -n "$USERDATA" ]     && echo "export USERDATA=\"$USERDATA\""
    [ -n "$CSV_PATH" ]     && echo "export CSV_PATH=\"$CSV_PATH\""
    [ -n "$GODOT_LOG" ]    && echo "export GODOT_LOG=\"$GODOT_LOG\""
    [ -n "$PYTHON_BIN" ]   && echo "export PYTHON_BIN=\"$PYTHON_BIN\""
}

emit_status() {
    echo "=== Project CNC env detection ==="
    echo "  OS:           $OS"
    echo "  PROJECT_PATH: $PROJECT_PATH"
    echo "  GODOT_BIN:    ${GODOT_BIN:-NOT FOUND}"
    if [ -n "$GODOT_BIN" ] && [ -x "$GODOT_BIN" ]; then
        echo "  GODOT version: $("$GODOT_BIN" --version 2>&1 | head -1)"
    fi
    echo "  USERDATA:     ${USERDATA:-?}"
    echo "  CSV_PATH:     $CSV_PATH"
    echo "  PYTHON_BIN:   ${PYTHON_BIN:-NOT FOUND}"
    echo
    if [ -z "$GODOT_BIN" ]; then
        echo "[ERROR] Godot CLI not found."
        echo "  Tried: ${GODOT_CANDIDATES[*]}"
        echo "  Install Godot 4.7-dev2 from https://godotengine.org/download/archive/4.7-dev2/"
        echo "  Or add to PATH and rerun."
        return 1
    fi
    echo "[OK] env detected. To export to current shell:"
    echo "  source <(bash $0 --export)"
}

run_verify() {
    if [ -z "$GODOT_BIN" ]; then
        echo "[FAIL] GODOT_BIN not set, can't verify"
        return 1
    fi
    echo "=== §I-7 3-step verification ==="
    rm -rf "$PROJECT_PATH/.godot" /tmp/run_*.log "$CSV_PATH" 2>/dev/null || true

    echo "[1/3] import (class_name cache)..."
    "$GODOT_BIN" --headless --path "$PROJECT_PATH" --import 1>/tmp/run_import.log 2>&1
    [ $? -eq 0 ] && echo "      OK" || echo "      FAIL"

    echo "[2/3] gui boot 5s..."
    "$GODOT_BIN" --path "$PROJECT_PATH" --quit-after 300 1>/tmp/run_gui.log 2>&1
    [ $? -eq 0 ] && echo "      OK" || echo "      FAIL"

    echo "[3/3] sandbox sim..."
    "$GODOT_BIN" --headless --path "$PROJECT_PATH" "res://scenes/test/sim_main.tscn" 1>/tmp/run_sim.log 2>&1
    [ $? -eq 0 ] && echo "      OK" || echo "      FAIL"

    echo
    echo "=== filtered errors (whitelist applied) ==="
    local filtered
    filtered="$(grep -iE "error|fail|push_error|push_warning|invalid|cannot|not found|null inst" /tmp/run_*.log 2>/dev/null | \
        grep -vE "DOTNET|Asio|Vulkan|D3D12|TextServer|XR_|OpenXR|FFmpeg|Native mobile|Failed to bind|MultiUma|Orphan|unclaimed|AudioStreamWAV|AudioStreamPlayback|leaked at exit|^$" || true)"
    if [ -z "$filtered" ]; then
        echo "(none — PASS)"
    else
        echo "$filtered"
        echo
        echo "[ACTION] Match against NEXT_SESSION.md §9 table → fix → rerun."
        return 1
    fi
}

case "$MODE" in
    --export)
        emit_export
        ;;
    --verify)
        emit_status
        echo
        run_verify
        ;;
    *)
        emit_status
        ;;
esac

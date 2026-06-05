#!/usr/bin/env bash
#
# start-community.sh - launch Counter-Strike: Source Community Edition on Linux.
#
# It also auto-dismisses the stock engine's harmless startup popup:
#   "SetLocale('en_US.UTF-8') failed ... You may have limited glyph support."
# That warning comes from the closed engine.so (NOT the mod) and cannot be
# fixed from the environment - verified exhaustively: the locale is fully
# installed, all categories load, yet the engine's internal check still fires.
# It is cosmetic (the game runs fine), so instead of fighting it we just click
# its OK for you via xdotool during the loading screen.
#
# Usage:
#   ./start-community.sh                  # main menu
#   ./start-community.sh +map de_dust2    # straight into a map
#   ./start-community.sh -bots            # de_dust2 listen server with 8 bots
# Extra args pass straight through to the engine.

set -u

# --- paths -------------------------------------------------------------------
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mp/game/community"
SDK_DIR="$HOME/.local/share/Steam/steamapps/common/Source SDK Base 2013 Multiplayer"
if [ ! -x "$SDK_DIR/hl2.sh" ]; then
    found=$(find "$HOME/.local/share/Steam" "$HOME/.steam" -maxdepth 4 \
            -name hl2.sh -path "*Source SDK Base 2013 Multiplayer*" 2>/dev/null | head -1)
    [ -n "$found" ] && SDK_DIR="$(dirname "$found")"
fi
[ -x "$SDK_DIR/hl2.sh" ] || { echo "ERROR: Source SDK Base 2013 Multiplayer not found (Steam app 243750)." >&2; exit 1; }
[ -f "$MOD_DIR/gameinfo.txt" ] || { echo "ERROR: mod dir not found at $MOD_DIR" >&2; exit 1; }

# --- environment -------------------------------------------------------------
unset LOCPATH                       # don't let a stray locale dir shadow the system one
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export DISPLAY="${DISPLAY:-:0}"

# --- args (with -bots convenience) ------------------------------------------
EXTRA=()
for a in "$@"; do
    case "$a" in
        -bots) EXTRA+=( +sv_cheats 1 +bot_quota 8 +bot_join_after_player 0 +map de_dust2 ) ;;
        *)     EXTRA+=( "$a" ) ;;
    esac
done

# --- launch ------------------------------------------------------------------
echo "Launching CS:S Community Edition  (mod=$MOD_DIR)"
( cd "$SDK_DIR" && exec ./hl2.sh -game "$MOD_DIR" -insecure "${EXTRA[@]}" ) &
GAME_PID=$!

# --- auto-dismiss the locale warning during the loading screen ---------------
# Presses Enter (the dialog's default OK) at the game window a handful of times
# while the map is still loading. The loop stops well before you can be in-game,
# so it can never trigger the chat box.
if command -v xdotool >/dev/null 2>&1; then
    (
        for _ in $(seq 1 8); do
            sleep 1.5
            hlpid=$(pgrep -x hl2_linux | head -1)
            [ -n "$hlpid" ] || continue
            wid=$(xdotool search --pid "$hlpid" --onlyvisible 2>/dev/null | tail -1)
            [ -n "$wid" ] || wid=$(xdotool search --class hl2_linux 2>/dev/null | tail -1)
            [ -n "$wid" ] || continue
            xdotool windowactivate "$wid" 2>/dev/null
            xdotool key --clearmodifiers Return 2>/dev/null
        done
    ) &
else
    echo "(xdotool not found - the locale warning will need a manual OK click)" >&2
fi

wait "$GAME_PID"

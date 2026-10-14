#!/usr/bin/env bash
# test.sh — every check in one place. Exit 0 = all green = safe to commit.
# `./run.sh test` runs this script.
#   ./test.sh                 everything that needs no database: venv matches requirements.txt,
#                             every module compiles and imports, shell syntax + shellcheck,
#                             no tracked .env
#   ./test.sh --integration   also run main.py against the PostgreSQL named in .env
#   ./test.sh --help          this text
#
# Every step runs even after an earlier failure; a summary table lists them all.
set -euo pipefail
cd "$(dirname "$0")"

INTEGRATION=0
for arg in "$@"; do
  case "$arg" in
    --integration) INTEGRATION=1 ;;
    -h|--help|help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (see ./test.sh --help)" >&2; exit 2 ;;
  esac
done

VENV=venv
PY="$VENV/bin/python"
[ -x "$PY" ] || { echo "No $VENV: run ./init.sh first" >&2; exit 1; }

if [ -t 1 ]; then GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
else GREEN=''; RED=''; YELLOW=''; BOLD=''; RESET=''; fi
LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/postgres-test.XXXXXX")"; trap 'rm -rf "$LOG_DIR"' EXIT

# Parallel indexed arrays (bash 3.2 has no associative arrays).
NAMES=(); RESULTS=()
record() { NAMES+=("$1"); RESULTS+=("$2"); }
run_step() { # <name> <command...>: capture output, never abort; on failure show the last 40 lines
  local name="$1"; shift; local log="$LOG_DIR/$name.log" rc
  printf '%b== %s%b\n' "$BOLD" "$name" "$RESET"
  set +e; ( "$@" ) > "$log" 2>&1; rc=$?; set -e
  if [ "$rc" -eq 0 ]; then record "$name" PASS
  else record "$name" FAIL; printf '%b   failed (exit %s), last 40 lines:%b\n' "$RED" "$rc" "$RESET"; tail -n 40 "$log" | sed 's/^/    /'; fi
}
skip_step() { printf '%b== %s: skipped (%s)%b\n' "$YELLOW" "$1" "$2" "$RESET"; record "$1" "SKIP: $2"; }

check_deps() {
  "$PY" -m pip check
  if "$PY" -m pip install --quiet --disable-pip-version-check --dry-run --no-deps -r requirements.txt 2>&1 | grep -q 'Would install'; then
    echo "venv is missing pinned packages; run ./init.sh"; return 1
  fi
}
check_secrets() {
  local tracked
  tracked="$(git ls-files | grep -E '(^|/)\.env(\..+)?$' | grep -vE '\.env\.(example|template)$' || true)"
  [ -z "$tracked" ] || { echo "env files must never be tracked:"; echo "$tracked"; return 1; }
  echo "no tracked env files"
}
check_shell() {
  local f
  for f in ./*.sh; do bash -n "$f"; /bin/bash -n "$f"; done
  if command -v shellcheck >/dev/null 2>&1; then shellcheck -S warning ./*.sh; else echo "shellcheck not installed; syntax-checked only"; fi
}
check_compile() { git ls-files -z -- '*.py' | xargs -0 "$PY" -m compileall -q; }
check_imports() { "$PY" -c 'import psycopg2, sqlparse, dotenv, db_utils, query_planner; print("imports ok")'; }
check_integration() {
  if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
  fi
  "$PY" main.py
}

run_step python "$PY" --version
run_step deps check_deps
run_step secrets check_secrets
run_step shell check_shell
run_step compile check_compile
run_step imports check_imports
if [ "$INTEGRATION" -eq 1 ]; then run_step integration check_integration; else skip_step integration "pass --integration; needs the PostgreSQL named in .env"; fi

printf '\n%b%-14s %s%b\n' "$BOLD" STEP RESULT "$RESET"
fails=0; i=0
while [ "$i" -lt "${#NAMES[@]}" ]; do
  case "${RESULTS[$i]}" in
    PASS) printf '%-14s %bPASS%b\n' "${NAMES[$i]}" "$GREEN" "$RESET" ;;
    FAIL) printf '%-14s %bFAIL%b\n' "${NAMES[$i]}" "$RED" "$RESET"; fails=$((fails + 1)) ;;
    *)    printf '%-14s %b%s%b\n' "${NAMES[$i]}" "$YELLOW" "${RESULTS[$i]}" "$RESET" ;;
  esac
  i=$((i + 1))
done
[ "$fails" -eq 0 ] && printf '%ball green%b\n' "$GREEN" "$RESET" || { printf '%b%s step(s) failed%b\n' "$RED" "$fails" "$RESET"; exit 1; }

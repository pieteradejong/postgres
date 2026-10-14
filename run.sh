#!/usr/bin/env bash
# run.sh — entry points. Run ./init.sh once first; `run` needs the PostgreSQL named in .env.
#   ./run.sh [run]       parse a query, fetch its plan from PostgreSQL, run the planner (default)
#   ./run.sh test        every check (delegates to ./test.sh; add --integration for the DB round-trip)
#   ./run.sh help        this text
set -euo pipefail
cd "$(dirname "$0")"

usage() { sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; }
cmd="${1:-run}"
[ $# -gt 0 ] && shift
case "$cmd" in help|-h|--help) usage; exit 0 ;; esac

VENV=venv
PY="$VENV/bin/python"
[ -x "$PY" ] || { echo "No $VENV: run ./init.sh first" >&2; exit 1; }

case "$cmd" in
  run) exec "$PY" main.py "$@" ;;
  test) exec ./test.sh "$@" ;;
  *) echo "run.sh: unknown command: $cmd" >&2; usage >&2; exit 2 ;;
esac

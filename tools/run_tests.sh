#!/usr/bin/env bash
# Runs the full deterministic check headless: the import step, the unit tests, then every scenario
# at a fixed 60 FPS. Exits 0 only when every stage passes. Serves AC D-04, D-05 (spec, M0 step 10).
set -uo pipefail

if [[ -z "${GODOT:-}" ]]; then
	echo "run_tests: set GODOT to the Godot 4.5.1 executable." >&2
	exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$ROOT/game"
status=0

echo "== Import =="
"$GODOT" --headless --path "$GAME" --import || { echo "run_tests: import failed." >&2; exit 1; }

echo "== Unit tests =="
"$GODOT" --headless --path "$GAME" res://tests/test_runner.tscn || status=1

echo "== Scenarios =="
# Until the scenario runner exists, --run-scenarios has nothing to drive it and would never quit.
if [[ -f "$GAME/verification/scenario_runner.gd" ]]; then
	"$GODOT" --headless --path "$GAME" --fixed-fps 60 -- --run-scenarios --quit-when-done || status=1
else
	echo "skipped (scenario runner arrives in M1 step 8)"
fi

if [[ $status -eq 0 ]]; then
	echo "run_tests: all passed."
else
	echo "run_tests: FAILED." >&2
fi
exit $status

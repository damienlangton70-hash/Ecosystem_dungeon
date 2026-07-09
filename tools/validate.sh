#!/usr/bin/env bash
# Deepforage — headless validation used by CI and the QA/Playtest agent.
#
# Gates on REAL Godot script/parse/runtime errors and on the gameplay self-test.
# Ignores the harmless dummy-renderer 'Parameter "m" is null' noise that Godot
# prints headless without a GPU (it can't introspect meshes; irrelevant to play).
#
# Usage:  GODOT=/path/to/godot ./tools/validate.sh [project_dir]
set -uo pipefail

GODOT="${GODOT:-godot}"
PROJECT_DIR="${1:-.}"

echo "== Importing project =="
"$GODOT" --headless --path "$PROJECT_DIR" --import 2>&1 | tee /tmp/df_import.log

echo "== Boot smoke-test (120 frames) =="
"$GODOT" --headless --path "$PROJECT_DIR" --quit-after 120 2>&1 | tee /tmp/df_run.log

echo "== Cooking-loop self-test =="
"$GODOT" --headless --path "$PROJECT_DIR" res://tools/SelfTest.tscn 2>&1 | tee /tmp/df_selftest.log

NOISE='Parameter "m" is null|mesh_get_surface_count'
PATTERN='SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Invalid access|Invalid get index|Cannot infer|Nonexistent function'

if grep -E "$PATTERN" /tmp/df_import.log /tmp/df_run.log /tmp/df_selftest.log | grep -vE "$NOISE"; then
  echo "VALIDATION FAILED: real script/runtime errors above."
  exit 1
fi

if ! grep -q "SELFTEST: PASS" /tmp/df_selftest.log; then
  echo "VALIDATION FAILED: gameplay self-test did not pass."
  exit 1
fi

echo "VALIDATION OK: no script/runtime errors; self-test passed."

#!/usr/bin/env bash
# Deepforage — headless validation used by CI and the QA/Playtest agent.
#
# Fails only on REAL Godot script/parse/runtime errors. It ignores the harmless
# dummy-renderer 'Parameter "m" is null' noise that Godot prints when running
# headless without a GPU (it cannot introspect meshes; irrelevant to gameplay).
#
# Usage:  GODOT=/path/to/godot ./tools/validate.sh [project_dir]
set -uo pipefail

GODOT="${GODOT:-godot}"
PROJECT_DIR="${1:-.}"

echo "== Importing project =="
"$GODOT" --headless --path "$PROJECT_DIR" --import 2>&1 | tee /tmp/df_import.log

echo "== Boot smoke-test (120 frames) =="
"$GODOT" --headless --path "$PROJECT_DIR" --quit-after 120 2>&1 | tee /tmp/df_run.log

NOISE='Parameter "m" is null|mesh_get_surface_count'
PATTERN='SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Invalid access|Invalid get index|Cannot infer|Nonexistent function'

if grep -E "$PATTERN" /tmp/df_import.log /tmp/df_run.log | grep -vE "$NOISE"; then
  echo "VALIDATION FAILED: real script/runtime errors above."
  exit 1
fi
echo "VALIDATION OK: no script/runtime errors."

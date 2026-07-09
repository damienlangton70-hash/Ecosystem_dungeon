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

echo "== Originality lint (banned external-IP / inspiration names) =="
# Deepforage borrows only the SPIRIT of its influences — no external-IP names in canon,
# code, or data. Renamed for originality: Antler Warg -> Rackjaw, Stonehide Rhinox ->
# Stonehide Gorehorn. BANNED covers our renamed collisions, Delicious in Dungeon names,
# and a few other franchises (Tolkien / D&D / sci-fi). Deliberately NOT banned: public-domain
# mythology our canon uses (basilisk, cockatrice, roc, wyrm, drake, leviathan, titan...),
# real English words (ent / umber / beholder / mimic / bugbear), and the citation
# "Delicious in Dungeon (Ryoko Kui)". Every entry must be a distinctive proper noun that can
# never be a substring of legitimate content. Extend below (case-insensitive substring).
# Excludes docs/ROADMAP.md + docs/changelog/ (they legitimately record rename history),
# *.base64 and *.import (encoded/generated text can contain these substrings by chance),
# and validate.sh itself (it defines the list).
BANNED='Warg|Rhinox|Laios|Marcille|Falin|Chilchuck|Senshi|Namari|Izutsumi|Shuro|Toshiro|Kabru|Mithrun|Balrog|Nazgul|Mordor|Uruk-hai|Mithril|Smaug|Illithid|Owlbear|Gnoll|Xenomorph'
LINT_HITS=$(grep -rEIni "$BANNED" "$PROJECT_DIR" \
  --exclude-dir=.git --exclude-dir=.godot --exclude-dir=.studio --exclude-dir=changelog \
  --exclude='*.base64' --exclude='*.import' --exclude='ROADMAP.md' --exclude='validate.sh' 2>/dev/null || true)
if [ -n "$LINT_HITS" ]; then
  echo "VALIDATION FAILED: originality lint found banned name(s) (external-IP / inspiration collision):"
  echo "$LINT_HITS"
  echo "Fix: rename to an original coinage (e.g. Warg->Rackjaw, Rhinox->Stonehide Gorehorn). If a mention is deliberate history, add its path to the lint excludes in tools/validate.sh."
  exit 1
fi
echo "Originality lint: OK (no banned names)."

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

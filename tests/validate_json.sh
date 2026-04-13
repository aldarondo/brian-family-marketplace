#!/usr/bin/env bash
# All marketplace JSON files must be valid before any commit.
# Run from the repo root: bash tests/validate_json.sh

echo "Validating marketplace JSON files..."

ERRORS=0

validate() {
  local file="$1"
  if python3 -c "import json, sys; json.load(open('$file'))" 2>/dev/null; then
    echo "  OK: $file"
  else
    echo "  FAIL: $file is not valid JSON"
    ERRORS=$((ERRORS + 1))
  fi
}

validate ".claude-plugin/marketplace.json"

for plugin_json in plugins/*/.claude-plugin/plugin.json; do
  [ -f "$plugin_json" ] && validate "$plugin_json"
done

for mcp_config in plugins/*/mcp/config.json; do
  [ -f "$mcp_config" ] && validate "$mcp_config"
done

if [ "$ERRORS" -eq 0 ]; then
  echo "All JSON files valid."
  exit 0
else
  echo "$ERRORS file(s) failed validation."
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

# Register omniroute-mcp-lite as a stdio MCP server in OpenCode and OMP.
#
# This is the portable equivalent of `opencode mcp add` / omp `/mcp add`:
# OpenCode's `mcp add` CLI only supports remote servers (no --command/--args),
# and omp has no top-level `mcp add` CLI (its native add is the in-session
# `/mcp add`). So we write the same config entries those commands would, with
# the server path resolved relative to this repo so it works at any clone path.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER="$SCRIPT_DIR/omniroute-mcp-lite.js"

for bin in bun jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "error: '$bin' is required" >&2; exit 1; }
done

API_KEY="${OMNIROUTE_API_KEY:-}"
if [ -z "$API_KEY" ]; then
  echo "warning: OMNIROUTE_API_KEY is not set; tool calls will fail until it is exported." >&2
fi

# --- OpenCode: ~/.config/opencode/opencode.json ---
OC="$HOME/.config/opencode/opencode.json"
mkdir -p "$(dirname "$OC")"
if [ -f "$OC" ]; then
  jq --arg cmd bun --arg args "$SERVER" --arg key "$API_KEY" '
    .mcp = (.mcp // {})
    | .mcp["omniroute-mcp-lite"] = {
        type: "local", enabled: true, command: $cmd, args: [$args],
        env: { OMNIROUTE_API_KEY: $key }
      }' "$OC" > "$OC.tmp" && mv "$OC.tmp" "$OC"
else
  jq -n --arg cmd bun --arg args "$SERVER" --arg key "$API_KEY" '
    { "$schema": "https://opencode.ai/config.json",
      mcp: { "omniroute-mcp-lite": {
        type: "local", enabled: true, command: $cmd, args: [$args],
        env: { OMNIROUTE_API_KEY: $key } } } }' > "$OC"
fi

# --- OMP: ~/.omp/agent/mcp.json (native; secret-safe env passthrough) ---
OMP="$HOME/.omp/agent/mcp.json"
mkdir -p "$(dirname "$OMP")"
if [ -f "$OMP" ]; then
  jq --arg cmd bun --arg args "$SERVER" '
    .["$schema"] = "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json"
    | .mcpServers = (.mcpServers // {})
    | .mcpServers["omniroute-mcp-lite"] = {
        type: "stdio", command: $cmd, args: [$args],
        env: { OMNIROUTE_API_KEY: "OMNIROUTE_API_KEY" }
      }' "$OMP" > "$OMP.tmp" && mv "$OMP.tmp" "$OMP"
else
  jq -n --arg cmd bun --arg args "$SERVER" '
    { "$schema": "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json",
      mcpServers: { "omniroute-mcp-lite": {
        type: "stdio", command: $cmd, args: [$args],
        env: { OMNIROUTE_API_KEY: "OMNIROUTE_API_KEY" } } } }' > "$OMP"
fi

echo "Registered omniroute-mcp-lite (stdio, bun) in OpenCode and OMP."
echo "  server : $SERVER"
echo "  reload or restart your harness sessions to pick it up."

# omniroute-mcp-lite

A thin, zero-dependency stdio [MCP](https://modelcontextprotocol.io) server that
exposes **only** OmniRoute's `web_search` and `web_fetch` tools and proxies each
call to your OmniRoute MCP endpoint.

> [!NOTE]
> OmniRoute ships a 100+ tool MCP catalog (~14,000 tokens). This proxy exposes
> just the two web tools — about **330 tokens** (wire) for the agent to load.

## Why

Most agents only need web search and fetch from OmniRoute. Loading the full
catalog wastes ~95% of that context on tools they never call.
`omniroute-mcp-lite` is a narrow pass-through: same capabilities, none of the
bloat.

## Features

- **Two tools, nothing else** — `omniroute_web_search` and `omniroute_web_fetch`.
- **Tiny context footprint** — trimmed schemas, no `provider` field for the agent to reason about.
- **Pinned routing** — search → Exa, fetch → Firecrawl, decided server-side in two constants.
- **Zero dependencies** — a single script run with `bun`; no `node_modules`, no build step.
- **Portable** — any MCP-aware client can launch it as a stdio subprocess.

## Requirements

- [Bun](https://bun.sh) (the server runs with `bun`)
- A running OmniRoute instance (default `http://127.0.0.1:20128/api/mcp/stream`)
  with an API key

## Install / run

No build, no `node_modules`. Run it directly:

```sh
bunx omniroute-mcp-lite
```

or clone and run the script:

```sh
git clone <repo> && bun /path/to/omniroute-mcp-lite
```

## Configuration (environment)

| Variable | Default | Description |
| --- | --- | --- |
| `OMNIROUTE_API_KEY` | _(required)_ | Bearer token for the upstream OmniRoute MCP. |
| `OMNIROUTE_MCP_URL` | `http://127.0.0.1:20128/api/mcp/stream` | Upstream MCP endpoint. |

The server reads these from its environment, so the harness that launches it must
have `OMNIROUTE_API_KEY` available (exported, or loaded via the harness's `.env`).

## Register with your agent

The server is plain stdio MCP, so any MCP-aware client can launch it. The command
is `bunx omniroute-mcp-lite` (or `bun /path/to/omniroute-mcp-lite`).

**OpenCode**

```sh
opencode mcp add omniroute-mcp-lite --env OMNIROUTE_API_KEY=$OMNIROUTE_API_KEY -- bunx omniroute-mcp-lite
```

**oh-my-pi (omp)** — in a session:

```
/mcp add
```

pick stdio, name `omniroute-mcp-lite`, command `bunx omniroute-mcp-lite`. Or write
`~/.omp/agent/mcp.json`:

```json
{
  "mcpServers": {
    "omniroute-mcp-lite": {
      "type": "stdio",
      "command": "bunx",
      "args": ["omniroute-mcp-lite"]
    }
  }
}
```

**Claude Code**

```sh
claude mcp add omniroute-mcp-lite -e OMNIROUTE_API_KEY=sk-… -- bunx omniroute-mcp-lite
```

**Cursor / any `.mcp.json`-aware client**

```json
{
  "mcpServers": {
    "omniroute-mcp-lite": {
      "command": "bunx",
      "args": ["omniroute-mcp-lite"]
    }
  }
}
```

## Tools

- `omniroute_web_search` — web search via OmniRoute, **pinned to Exa**.
- `omniroute_web_fetch` — fetch/extract a URL via OmniRoute, **pinned to Firecrawl**.

The agent never sees a `provider` field; the proxy pins the provider
server-side in the two constants (`SEARCH_PROVIDER` / `FETCH_PROVIDER`) at the
top of the script, so no upstream failover occurs. Edit those two lines to
re-pin to a different provider.

> [!WARNING]
> Pinning a provider disables OmniRoute's upstream failover. If the pinned
> provider (Exa for search, Firecrawl for fetch) is down, that call fails
> instead of rolling over to another provider.

> [!TIP]
> To switch providers, edit `SEARCH_PROVIDER` / `FETCH_PROVIDER` at the top of
> `omniroute-mcp-lite` — no flags or argv needed.

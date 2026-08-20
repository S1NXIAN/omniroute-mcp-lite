# omniroute-mcp-lite

A thin, zero-dependency stdio [MCP](https://modelcontextprotocol.io) server that
exposes **only** OmniRoute's `web_search` and `web_fetch` tools and proxies each
call to your OmniRoute MCP endpoint.

It exists to keep your agent's context small: OmniRoute's full MCP catalog is
~14,000 tokens; this proxy is ~630 tokens (2 tools).

## Why

OmniRoute ships a 100+ tool MCP catalog. Most agents only need web search/fetch.
Loading the full catalog wastes ~95% of that context. This proxy is a narrow
pass-through — same multi-engine failover, none of the bloat.

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

- `omniroute_web_search` — web search via OmniRoute's gateway (Serper, Brave,
  Perplexity, Exa, Tavily, … with automatic failover).
- `omniroute_web_fetch` — fetch/extract a URL via OmniRoute's gateway (Firecrawl,
  Jina Reader, Tavily, … with automatic failover).

Schemas are passed through verbatim from OmniRoute, so arguments need no remapping.

## License

MIT

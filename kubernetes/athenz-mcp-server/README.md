# Athenz MCP Server

FastMCP-based MCP Server demonstrating Athenz Access Token authorization.

## Overview

This MCP server showcases Athenz ID-JAG (Identity JWT Access Grant) token exchange by validating Athenz Access Tokens via JWTVerifier and enforcing scope-based authorization.

- **Read** (`tools/list`): allowed for any valid Athenz Access Token with audience `mcp`
- **Write** (`tools/call`): allowed only when token scope includes `mcp:action.write` (granted by Access Agreement for `mcp:role.mcp-clients`)

## Quick Start

```bash
make deploy-athenz-mcp-server
make test-athenz-mcp-server
```

## Tools

| Tool | Authorization | Description |
|------|--------------|-------------|
| `get_server_info` | Read (any valid token) | Returns server metadata |
| `read_data` | Read (any valid token) | Reads a value by key |
| `write_data` | Write (requires `mcp:action.write` scope) | Writes a key-value pair |

## Authorization Flow

```
Client → Keycloak (OIDC) → ZTS (ID-JAG) → Athenz Access Token (scope: mcp-clients)
  → FastMCP JWTVerifier (validates JWT signature + issuer against ZTS JWKS)
    → Scope Authorization Middleware (checks for mcp:action.write)
      → tools/list (read) → 200
      → tools/call  (write) → 200 or 403
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ZTS_BASE_URL` | `https://athenz-zts-server.athenz:4443/zts/v1` | Athenz ZTS endpoint |
| `JWKS_URI` | `{ZTS_BASE_URL}/oauth2/keys?rfc=true` | JWKS URI for JWT verification |
| `ISSUER` | `{ZTS_BASE_URL}` | Expected JWT issuer |
| `AUDIENCE` | `mcp` | Expected JWT audience |
| `REQUIRED_WRITE_SCOPE` | `mcp:action.write` | Scope required for `tools/call` |

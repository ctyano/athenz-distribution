# Identity Chaining: Keycloak User to MCP Server via ID-JAG Token Exchange on Kubernetes

This showcase demonstrates **Identity Chaining** — a Keycloak user logs in once, and their identity is preserved through every token exchange, all the way to an MCP server. The flow is designed for Agent and MCP users to intuitively understand how a single login propagates through the system.

## What Happens at a Glance

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Keycloak   │───▶│     ZTS     │───▶│     ZTS     │───▶│     ZTS     │───▶│  MCP Server │
│   Login      │    │  ID-JAG     │    │  Access     │    │  Exchanged  │    │  (FastMCP)  │
│              │    │  Exchange   │    │  Token      │    │  Token      │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
  athenz_user@     keycloak:ext.      keycloak:ext.      keycloak:ext.      keycloak:ext.
  athenz.io        athenz_user@       athenz_user@       athenz_user@       athenz_user@
                   athenz.io          athenz.io          athenz.io          athenz.io
   ↓                  ↓                  ↓                  ↓                  ↓
  Keycloak ID      ID-JAG JWT         Access Token       Exchanged Token    MCP logs show
  Token (sub=      (sub=keycloak:     (sub=keycloak:     (sub=keycloak:     sub=keycloak:ext.
  1e5a4f3c...)     ext.athenz_        ext.athenz_        ext.athenz_        athenz_user@athenz.io
                   user@athenz.io)    user@athenz.io)    user@athenz.io)
```

**Key insight**: The `sub` claim evolves from Keycloak's UUID (`1e5a4f3c...`) to the mapped Athenz principal (`keycloak:ext.athenz_user@athenz.io`) and stays there through every exchange. This is Identity Chaining.

## What You Need

| Component | Endpoint | Purpose |
| --- | --- | --- |
| Keycloak | `http://keycloakx-http.keycloak:8080/realms/athenz` | Issues ID Tokens for user login |
| ZMS | `https://athenz-zms-server.athenz:4443/zms/v1` | Manages domains, roles, policies |
| ZTS | `https://athenz-zts-server.athenz:4443/zts/v1` | Issues tokens via ID-JAG and Token Exchange |
| MCP Server | `http://athenz-mcp-server.athenz:8000/mcp` | Demonstrates token authorization |

## How the Identity Chain Works

1. **Keycloak Login** → User `athenz_user@athenz.io` authenticates, gets an ID Token (subject = Keycloak UUID)
2. **ID-JAG Exchange** → ZTS validates the ID Token, maps `email` → `keycloak:ext.athenz_user@athenz.io`, issues an ID-JAG JWT
3. **Access Token** → ZTS converts the ID-JAG into an Athenz Access Token with roles `downstream-agents mcp-clients`
4. **Token Exchange** → Upstream Agent exchanges the Access Token for an `mcp` audience token with role `mcp-clients`
5. **MCP Server** → FastMCP validates the JWT, logs the chained identity, authorizes read/write based on scope

## Environment

| Variable | Value |
| --- | --- |
| namespace | `athenz` |
| Keycloak user | `athenz_user@athenz.io` |
| Keycloak client | `id-jag-client` |
| Keycloak issuer | `http://keycloakx-http.keycloak:8080/realms/athenz` |
| ZMS endpoint | `https://athenz-zms-server.athenz:4443/zms/v1` |
| ZTS endpoint | `https://athenz-zts-server.athenz:4443/zts/v1` |
| Working directory | `/dev/shm/jag-flow.*` |
| Downstream Remote Agent | `keycloak.downstream.agent` |
| Upstream Remote Agent | `agentbroker.upstream.agent` |
| Final Access Token role | `mcp:role.mcp-clients` |

## 1. ZTS OAuth Provider Setup

**What this does**: Tells ZTS to trust Keycloak ID Tokens and map Keycloak users to Athenz principals.

**How it works**: Keycloak assigns users UUID-based `sub` values (like `1e5a4f3c-...`), but Athenz principals look like `keycloak:ext.athenz_user@athenz.io`. ZTS uses a `TokenExchangeIdentityProvider` that maps the Keycloak ID Token `email` claim to the Athenz principal format. With this provider, `athenz_user@athenz.io` becomes `keycloak:ext.athenz_user@athenz.io` — and this mapped identity is what gets chained through every subsequent token.

**Pre-requisite**: This must be configured before the first token exchange. See the ZTS OAuth provider configuration documentation for details.

## 2. Prepare ZMS Objects and Permissions

**What this does**: Creates the Athenz domains, service identities, and authorization policies that the token exchange flow requires. This is the one-time setup that makes Identity Chaining possible.

**What gets created**:

| Resource | Domain | Purpose |
| --- | --- | --- |
| `keycloak.downstream` | `keycloak` | Hosts the Downstream Agent that requests ID-JAG tokens |
| `agentbroker.upstream` | `agentbroker` | Hosts the Upstream Agent that exchanges Access Tokens |
| `mcp` | `mcp` | Target domain for the final Access Token |
| `keycloak.downstream.agent` | `keycloak.downstream` | Downstream Agent service identity (OAuth client `id-jag-client`) |
| `agentbroker.upstream.agent` | `agentbroker.upstream` | Upstream Agent service identity |
| `agentbroker:role.downstream-agents` | `agentbroker` | Source role containing `keycloak:ext.athenz_user@athenz.io` |
| `agentbroker:role.mcp-clients` | `agentbroker` | Compatibility role for token exchange scope validation |
| `mcp:role.mcp-clients` | `mcp` | Target role for the final Access Token |
| `mcp_write_access` policy | `mcp` | Grants `mcp:action.write` action scope |

**Authorization flow**:
1. `keycloak.downstream.agent` is authorized to exchange ID Tokens → ID-JAG for roles in `agentbroker`
2. `agentbroker.upstream.agent` is authorized to exchange Access Tokens from `agentbroker` audience → `mcp` audience
3. The mapped Keycloak principal is added as a member of both source roles and the target role

The script below creates all domains, registers services with Copper Argos Service Certs, configures the `mcp_write_access` template, and sets up exchange policies:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=$(mktemp -d /dev/shm/jag-flow.XXXXXX)
KEY_ID=$(date +%s)
KEY_ID2=$((KEY_ID + 1))
ZMS=https://athenz-zms-server.athenz:4443/zms/v1
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
ADMIN_KEY=/var/run/athenz/athenz_admin.private.pem
ADMIN_CERT=/var/run/athenz/athenz_admin.cert.pem

PARENT_DOMAIN=keycloak
DOWNSTREAM_SUBDOMAIN=downstream
DOWNSTREAM_DOMAIN=$PARENT_DOMAIN.$DOWNSTREAM_SUBDOMAIN
UPSTREAM_PARENT_DOMAIN=agentbroker
UPSTREAM_SUBDOMAIN=upstream
UPSTREAM_DOMAIN=$UPSTREAM_PARENT_DOMAIN.$UPSTREAM_SUBDOMAIN
SOURCE_DOMAIN=$UPSTREAM_PARENT_DOMAIN
TARGET_DOMAIN=mcp
AGENT_SERVICE=agent
DOWNSTREAM_AGENT=$DOWNSTREAM_DOMAIN.$AGENT_SERVICE
UPSTREAM_AGENT=$UPSTREAM_DOMAIN.$AGENT_SERVICE
SOURCE_ROLE_NAME=downstream-agents
SOURCE_COMPAT_ROLE_NAME=mcp-clients
TARGET_ROLE_NAME=mcp-clients
ADMIN_USER=user.athenz_admin
SUBJECT_PRINCIPAL=keycloak:ext.athenz_user@athenz.io

post_zms_json() {
  out=$1
  url=$2
  data=$3
  code=$(curl -sS -o "$out" -w "%{http_code}" \
    -X POST "$url" \
    --cacert "$CA" \
    --key "$ADMIN_KEY" \
    --cert "$ADMIN_CERT" \
    -H "Content-Type: application/json" \
    -d "$data")
  case "$code" in
    2*) ;;
    *)
      if grep -q "Domain name conflict" "$out"; then
        :
      else
        echo "HTTP_ERROR status=$code output=$out" >&2
        cat "$out" >&2 || true
        exit 1
      fi
      ;;
  esac
}

openssl genrsa -out "$WORKDIR/downstream-agent.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/downstream-agent.key.pem" \
  -pubout -out "$WORKDIR/downstream-agent.pub.pem" >/dev/null 2>&1

openssl genrsa -out "$WORKDIR/upstream-agent.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/upstream-agent.key.pem" \
  -pubout -out "$WORKDIR/upstream-agent.pub.pem" >/dev/null 2>&1

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$PARENT_DOMAIN" >"$WORKDIR/add-keycloak-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-keycloak-domain.out" "$ZMS/domain" \
    "{\"name\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$DOWNSTREAM_DOMAIN" >"$WORKDIR/add-downstream-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-downstream-domain.out" "$ZMS/subdomain/$PARENT_DOMAIN" \
    "{\"name\":\"$DOWNSTREAM_SUBDOMAIN\",\"parent\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$UPSTREAM_PARENT_DOMAIN" >"$WORKDIR/add-upstream-parent-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-upstream-parent-domain.out" "$ZMS/domain" \
    "{\"name\":\"$UPSTREAM_PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$UPSTREAM_DOMAIN" >"$WORKDIR/add-upstream-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-upstream-domain.out" "$ZMS/subdomain/$UPSTREAM_PARENT_DOMAIN" \
    "{\"name\":\"$UPSTREAM_SUBDOMAIN\",\"parent\":\"$UPSTREAM_PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$TARGET_DOMAIN" >"$WORKDIR/add-target-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-target-domain.out" "$ZMS/domain" \
    "{\"name\":\"$TARGET_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-service "$AGENT_SERVICE" "$KEY_ID" "$WORKDIR/downstream-agent.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-public-key "$AGENT_SERVICE" "$KEY_ID" "$WORKDIR/downstream-agent.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  set-service-client-id "$AGENT_SERVICE" id-jag-client

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  set-domain-template identity_provisioning \
  instanceprovider=sys.auth.zts service="$AGENT_SERVICE" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-service "$AGENT_SERVICE" "$KEY_ID2" "$WORKDIR/upstream-agent.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-public-key "$AGENT_SERVICE" "$KEY_ID2" "$WORKDIR/upstream-agent.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  set-domain-template identity_provisioning \
  instanceprovider=sys.auth.zts service="$AGENT_SERVICE" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role "$SOURCE_ROLE_NAME" "$SUBJECT_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-member "$SOURCE_ROLE_NAME" "$SUBJECT_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role "$SOURCE_COMPAT_ROLE_NAME" "$SUBJECT_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-member "$SOURCE_COMPAT_ROLE_NAME" "$SUBJECT_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role jag_exchanger_admin "$DOWNSTREAM_AGENT" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-policy jag_exchange_downstream_agents grant zts.jag_exchange to jag_exchanger_admin on role.$SOURCE_ROLE_NAME \
  || zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
    -d "$SOURCE_DOMAIN" \
    add-assertion jag_exchange_downstream_agents grant zts.jag_exchange to jag_exchanger_admin on role.$SOURCE_ROLE_NAME || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-policy jag_exchange_mcp_clients grant zts.jag_exchange to jag_exchanger_admin on role.$SOURCE_COMPAT_ROLE_NAME \
  || zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
    -d "$SOURCE_DOMAIN" \
    add-assertion jag_exchange_mcp_clients grant zts.jag_exchange to jag_exchanger_admin on role.$SOURCE_COMPAT_ROLE_NAME || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-regular-role "$TARGET_ROLE_NAME" "$SUBJECT_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-member "$TARGET_ROLE_NAME" "$SUBJECT_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  set-domain-template mcp_write_access || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role token_source_exchanger "$UPSTREAM_AGENT" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-policy token_source_exchange grant zts.token_source_exchange to token_source_exchanger on "$TARGET_DOMAIN" \
  || zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
    -d "$SOURCE_DOMAIN" \
    add-assertion token_source_exchange grant zts.token_source_exchange to token_source_exchanger on "$TARGET_DOMAIN" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-regular-role token_target_exchanger "$UPSTREAM_AGENT" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-policy token_target_exchange grant zts.token_target_exchange to token_target_exchanger on "$TARGET_DOMAIN:$SOURCE_DOMAIN:role.$TARGET_ROLE_NAME" \
  || zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
    -d "$TARGET_DOMAIN" \
    add-assertion token_target_exchange grant zts.token_target_exchange to token_target_exchanger on "$TARGET_DOMAIN:$SOURCE_DOMAIN:role.$TARGET_ROLE_NAME" || true

sleep 10

zms-svctoken \
  -domain "$DOWNSTREAM_DOMAIN" \
  -service "$AGENT_SERVICE" \
  -private-key "$WORKDIR/downstream-agent.key.pem" \
  -key-version "$KEY_ID" | tr -d "\n" > "$WORKDIR/downstream-agent.ntoken"

zts-svccert \
  -zts "$ZTS" \
  -cacert "$CA" \
  -domain "$DOWNSTREAM_DOMAIN" \
  -service "$AGENT_SERVICE" \
  -provider sys.auth.zts \
  -instance "$DOWNSTREAM_AGENT" \
  -attestation-data "$WORKDIR/downstream-agent.ntoken" \
  -dns-domain zts.athenz.cloud \
  -private-key "$WORKDIR/downstream-agent.key.pem" \
  -key-version "$KEY_ID" \
  -cert-file "$WORKDIR/downstream-agent.cert.pem" \
  -signer-cert-file "$WORKDIR/downstream-agent-signer-ca.cert.pem"

zms-svctoken \
  -domain "$UPSTREAM_DOMAIN" \
  -service "$AGENT_SERVICE" \
  -private-key "$WORKDIR/upstream-agent.key.pem" \
  -key-version "$KEY_ID2" | tr -d "\n" > "$WORKDIR/upstream-agent.ntoken"

zts-svccert \
  -zts "$ZTS" \
  -cacert "$CA" \
  -domain "$UPSTREAM_DOMAIN" \
  -service "$AGENT_SERVICE" \
  -provider sys.auth.zts \
  -instance "$UPSTREAM_AGENT" \
  -attestation-data "$WORKDIR/upstream-agent.ntoken" \
  -dns-domain zts.athenz.cloud \
  -private-key "$WORKDIR/upstream-agent.key.pem" \
  -key-version "$KEY_ID2" \
  -cert-file "$WORKDIR/upstream-agent.cert.pem" \
  -signer-cert-file "$WORKDIR/upstream-agent-signer-ca.cert.pem"

echo "WORKDIR=$WORKDIR"
'
```

The split examples below use the `downstream-agent.key.pem`, `downstream-agent.cert.pem`, `upstream-agent.key.pem`, and `upstream-agent.cert.pem` files created in the `WORKDIR` printed by the previous command. The examples use `WORKDIR=/dev/shm/jag-flow.example`; replace it with the value printed in your own environment when you rerun the procedure.

## 3. Request Keycloak ID Token

**What happens**: User `athenz_user@athenz.io` logs in to Keycloak. Keycloak issues an ID Token with `sub` = Keycloak UUID (e.g., `1e5a4f3c-...`) and `email` = `athenz_user@athenz.io`.

**Command**:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example

curl -sfS -X POST "http://keycloakx-http.keycloak:8080/realms/athenz/protocol/openid-connect/token" \
  -u "id-jag-client:id-jag-client" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "scope=openid profile email" \
  --data-urlencode "username=athenz_user@athenz.io" \
  --data-urlencode "password=password" \
  > "$WORKDIR/keycloak-token.json"

jq -r .id_token "$WORKDIR/keycloak-token.json"
'
```

**Result**: A Keycloak ID Token JWT.

```json
{
  "iss": "http://keycloakx-http.keycloak:8080/realms/athenz",
  "sub": "1e5a4f3c-6c8b-4e2a-9d0f-3b7e1a2c4d5e",
  "aud": "id-jag-client",
  "email": "athenz_user@athenz.io",
  "email_verified": true,
  "name": "athenz_user",
  "iat": 1781269291,
  "exp": 1781355691
}
```

Request parameters:

| Parameter | Value |
| --- | --- |
| endpoint | `http://keycloakx-http.keycloak:8080/realms/athenz/protocol/openid-connect/token` |
| auth | HTTP Basic: `id-jag-client:id-jag-client` |
| `grant_type` | `password` (RFC 6749 Section 4.3) |
| `scope` | `openid profile email` (OpenID Connect Core Section 11) |
| `username` | `athenz_user@athenz.io` |
| `password` | `password` |

Response field used in the next step:

| Field | Meaning |
| --- | --- |
| `id_token` | OIDC ID Token (JWT) issued by Keycloak. Used as the ZTS token exchange `subject_token`. |

**Identity Chaining checkpoint**: At this point, the identity is `sub: 1e5a4f3c-6c8b-4e2a-9d0f-3b7e1a2c4d5e` (Keycloak UUID). The `email` claim is what ZTS will use to map to the Athenz principal in the next step.

## 4. Exchange Keycloak ID Token for ID-JAG

**What happens**: The Downstream Agent sends the Keycloak ID Token to ZTS. ZTS validates the token against Keycloak's JWKS, maps the `email` claim to `keycloak:ext.athenz_user@athenz.io`, and issues an ID-JAG JWT with the mapped identity as `sub`.

**Command**:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
SOURCE_DOMAIN=agentbroker
SOURCE_ROLE_NAME=downstream-agents
SOURCE_COMPAT_ROLE_NAME=mcp-clients
ID_TOKEN=$(jq -r .id_token "$WORKDIR/keycloak-token.json")

curl -sfS -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/downstream-agent.key.pem" \
  --cert "$WORKDIR/downstream-agent.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:id-jag" \
  --data-urlencode "audience=$ZTS" \
  --data-urlencode "scope=$SOURCE_DOMAIN:role.$SOURCE_ROLE_NAME $SOURCE_DOMAIN:role.$SOURCE_COMPAT_ROLE_NAME" \
  --data-urlencode "subject_token=$ID_TOKEN" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:id_token" \
  > "$WORKDIR/id-jag.json"

jq -r .access_token "$WORKDIR/id-jag.json"
'
```

**Result**: An ID-JAG JWT with the mapped Athenz principal.

```json
{
  "iss": "https://athenz-zts-server.athenz:4443/zts/v1",
  "sub": "keycloak:ext.athenz_user@athenz.io",
  "aud": "https://athenz-zts-server.athenz:4443/zts/v1",
  "scope": "agentbroker:role.downstream-agents agentbroker:role.mcp-clients",
  "scp": [
    "agentbroker:role.downstream-agents",
    "agentbroker:role.mcp-clients"
  ],
  "client_id": "keycloak.downstream.agent",
  "email": "athenz_user@athenz.io",
  "iat": 1781269291,
  "exp": 1781276491
}
```

Request parameters:

| Parameter | Value |
| --- | --- |
| endpoint | `https://athenz-zts-server.athenz:4443/zts/v1/oauth2/token` |
| client authentication | mTLS with the Downstream Remote Agent `keycloak.downstream.agent` Service Cert |
| `grant_type` | `urn:ietf:params:oauth:grant-type:token-exchange` (RFC 8693 Section 2.1) |
| `requested_token_type` | `urn:ietf:params:oauth:token-type:id-jag` (Athenz-specific ID-JAG token type) |
| `audience` | `https://athenz-zts-server.athenz:4443/zts/v1` |
| `scope` | `agentbroker:role.downstream-agents agentbroker:role.mcp-clients` |
| `subject_token` | Keycloak ID Token (JWT) |
| `subject_token_type` | `urn:ietf:params:oauth:token-type:id_token` (RFC 8693 Section 2.1) |

Response example:

```json
{
  "access_token": "<ID-JAG JWT>",
  "token_type": "N_A",
  "expires_in": 7200,
  "scope": "agentbroker:role.downstream-agents agentbroker:role.mcp-clients",
  "issued_token_type": "urn:ietf:params:oauth:token-type:id-jag"
}
```

Decoded JWT header example:

```json
{
  "kid": "athenz-zts-server-5c5969456-hnvjc",
  "typ": "oauth-id-jag+jwt",
  "alg": "RS256"
}
```

Important checks:

- `typ` is `oauth-id-jag+jwt` (Athenz ID-JAG token type identifier).
- `sub` is mapped from Keycloak UUID to `keycloak:ext.athenz_user@athenz.io` via the `email` claim.
- `scope` includes `agentbroker:role.downstream-agents` and `agentbroker:role.mcp-clients`.
- `scope` does not include `mcp:role.mcp-clients`; that target role is issued only after the Access Token=>Access Token exchange.
- The response `issued_token_type` is `urn:ietf:params:oauth:token-type:id-jag`.

**Identity Chaining checkpoint**: The `sub` claim has changed from Keycloak UUID to `keycloak:ext.athenz_user@athenz.io`. This mapped identity will persist through all subsequent exchanges. The `typ` header is `oauth-id-jag+jwt`.

## 5. Exchange ID-JAG for Athenz Access Token

**What happens**: ZTS converts the ID-JAG JWT into a standard Athenz Access Token. The `sub` remains `keycloak:ext.athenz_user@athenz.io`, but the `aud` changes to `agentbroker` (the source role domain) and the `scope` contains the simple role names `downstream-agents` and `mcp-clients`.

**Command**:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
ID_JAG=$(jq -r .access_token "$WORKDIR/id-jag.json")

curl -sfS -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/downstream-agent.key.pem" \
  --cert "$WORKDIR/downstream-agent.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
  --data-urlencode "assertion=$ID_JAG" \
  > "$WORKDIR/access-token.json"

jq -r .access_token "$WORKDIR/access-token.json"
'
```

**Result**: An Athenz Access Token JWT scoped to the `agentbroker` audience.

```json
{
  "iss": "https://athenz-zts-server.athenz:4443/zts/v1",
  "sub": "keycloak:ext.athenz_user@athenz.io",
  "aud": "agentbroker",
  "scope": "downstream-agents mcp-clients",
  "scp": [
    "downstream-agents",
    "mcp-clients"
  ],
  "client_id": "keycloak.downstream.agent",
  "uid": "keycloak:ext.athenz_user@athenz.io",
  "iat": 1781269291,
  "exp": 1781276491
}
```

Request parameters:

| Parameter | Value |
| --- | --- |
| endpoint | `https://athenz-zts-server.athenz:4443/zts/v1/oauth2/token` |
| client authentication | mTLS with the Downstream Remote Agent `keycloak.downstream.agent` Service Cert |
| `grant_type` | `urn:ietf:params:oauth:grant-type:jwt-bearer` (RFC 7523 Section 2.1) |
| `assertion` | ID-JAG JWT |

Response example:

```json
{
  "access_token": "<Athenz Access Token JWT>",
  "token_type": "Bearer",
  "expires_in": 7200
}
```

Decoded JWT header example:

```json
{
  "kid": "athenz-zts-server-5c5969456-hnvjc",
  "typ": "at+jwt",
  "alg": "RS256"
}
```

Important checks:

- `typ` is `at+jwt` (Athenz Access Token type identifier).
- `sub` and `uid` are `keycloak:ext.athenz_user@athenz.io`.
- `aud` is the source role domain, `agentbroker`.
- `scope` is converted from fully-qualified role names (`agentbroker:role.downstream-agents`) to simple role names (`downstream-agents`).
- This token still does not grant `mcp:role.mcp-clients`; `mcp-clients` is scoped to the `agentbroker` audience in this first Access Token.

**Identity Chaining checkpoint**: The `sub` and `uid` are still `keycloak:ext.athenz_user@athenz.io`. The token is scoped to `agentbroker` audience with roles `downstream-agents` and `mcp-clients`. The target `mcp:role.mcp-clients` is not yet available — it will appear only after the next exchange. The `typ` header is `at+jwt`.

## 6. Exchange the Access Token for Another Domain/Role Access Token

**What happens**: The Upstream Agent exchanges the first Access Token (audience `agentbroker`) for a new Access Token (audience `mcp`) with the target role `mcp-clients`. The `sub` remains `keycloak:ext.athenz_user@athenz.io` — this is where Identity Chaining delivers the final token to the MCP domain.

**Why two agents?**: The Downstream Agent is the Keycloak OAuth client that initiated the ID-JAG flow. The Upstream Agent is authorized to exchange tokens from `agentbroker` audience to `mcp` audience. Separation of duties keeps the ID-JAG client and the token exchange client distinct.

**Authorization**: ZTS checks two permissions for this exchange:

| Permission | Domain | Resource | Purpose |
| --- | --- | --- | --- |
| `zts.token_source_exchange` | `agentbroker` | `agentbroker:mcp` | Allows exchanging from `agentbroker` to `mcp` audience |
| `zts.token_target_exchange` | `mcp` | `mcp:agentbroker:role.mcp-clients` | Allows requesting `mcp-clients` role from `agentbroker` source |

**Command**:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
TARGET_DOMAIN=mcp
TARGET_ROLE_NAME=mcp-clients
SOURCE_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")

curl -sfS -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/upstream-agent.key.pem" \
  --cert "$WORKDIR/upstream-agent.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:access_token" \
  --data-urlencode "audience=$TARGET_DOMAIN" \
  --data-urlencode "scope=$TARGET_DOMAIN:role.$TARGET_ROLE_NAME" \
  --data-urlencode "subject_token=$SOURCE_ACCESS_TOKEN" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:access_token" \
  > "$WORKDIR/exchanged-access-token.json"

jq -r .access_token "$WORKDIR/exchanged-access-token.json"
'
```

**Result**: An Athenz Access Token JWT scoped to the `mcp` audience.

```json
{
  "iss": "athenz-zts-server-5c5969456-hnvjc",
  "sub": "keycloak:ext.athenz_user@athenz.io",
  "aud": "mcp",
  "scope": "mcp-clients",
  "scp": [
    "mcp-clients"
  ],
  "client_id": "agentbroker.upstream.agent",
  "uid": "agentbroker.upstream.agent",
  "cnf": {
    "x5t#S256": "<Upstream Remote Agent certificate thumbprint>"
  },
  "iat": 1781269291,
  "exp": 1781276491
}
```

Request parameters:

| Parameter | Value |
| --- | --- |
| endpoint | `https://athenz-zts-server.athenz:4443/zts/v1/oauth2/token` |
| client authentication | mTLS with the Upstream Remote Agent `agentbroker.upstream.agent` Service Cert |
| `grant_type` | `urn:ietf:params:oauth:grant-type:token-exchange` (RFC 8693 Section 2.1) |
| `requested_token_type` | `urn:ietf:params:oauth:token-type:access_token` (RFC 8693 Section 2.1) |
| `audience` | `mcp` |
| `scope` | `mcp:role.mcp-clients` |
| `subject_token` | The first Athenz Access Token issued from the ID-JAG token |
| `subject_token_type` | `urn:ietf:params:oauth:token-type:access_token` (RFC 8693 Section 2.1) |

Response example:

```json
{
  "access_token": "<Exchanged Athenz Access Token JWT>",
  "token_type": "Bearer",
  "expires_in": 7200,
  "scope": "mcp:role.mcp-clients"
}
```

Decoded JWT header example:

```json
{
  "kid": "athenz-zts-server-5c5969456-hnvjc",
  "typ": "at+jwt",
  "alg": "RS256"
}
```

Important checks:

- `typ` is `at+jwt` (Athenz Access Token type identifier).
- `sub` remains the source Access Token subject, `keycloak:ext.athenz_user@athenz.io`.
- `aud` is changed from `agentbroker` to `mcp`.
- The target full role is `mcp:role.mcp-clients`.
- The JWT `scope` claim is `mcp-clients`, because Athenz Access Tokens carry role names in `scope` and the target role name must be a subset of the source Access Token roles.
- `client_id` and `uid` identify the Upstream Remote Agent service principal, `agentbroker.upstream.agent`.
- The `cnf` claim contains the certificate thumbprint of the Upstream Remote Agent (RFC 8705 Section 3).

**Exchange path note**: This procedure uses the Access Token as `subject_token` without `actor_token`, so ZTS handles it as an impersonation-style access-token exchange (RFC 8693 Section 2.1). In that path, the Service Cert authenticates the Upstream Remote Agent, but it does not replace the source-domain authorization check. ZTS evaluates both `zts.token_source_exchange` and `zts.token_target_exchange`.

A `zts.token_source_exchange`-free Access Token Exchange can only be constructed through the delegation path (RFC 8693 Section 2.1), where the request includes `actor_token` and `actor_token_type`, and the `subject_token` already has `may_act.sub` matching the actor identity. The Access Token issued from ID-JAG in step 5 does not contain `may_act`, so this end-to-end procedure intentionally keeps `zts.token_source_exchange`.

**Identity Chaining checkpoint**: The `sub` is still `keycloak:ext.athenz_user@athenz.io` — the original Keycloak user's identity has been preserved through four token exchanges. The `aud` is now `mcp`, and the `scope` contains `mcp-clients` (the role name) plus `mcp:action.write` (the action scope from the `mcp_write_access` template). This is the token that will be presented to the MCP server.

## 7. JWT Decode Helper

Use this helper to inspect JWT headers and payloads inside the pod. This is useful for verifying the Identity Chaining checkpoints at each stage.

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example

jwt_part() {
  token=$1
  part=$2
  value=$(printf "%s" "$token" | cut -d. -f "$part" | tr "_-" "/+")
  case $((${#value} % 4)) in
    2) value="${value}==" ;;
    3) value="${value}=" ;;
    1) value="${value}===" ;;
  esac
  printf "%s" "$value" | base64 -d 2>/dev/null
}

ID_TOKEN=$(jq -r .id_token "$WORKDIR/keycloak-token.json")
ID_JAG=$(jq -r .access_token "$WORKDIR/id-jag.json")
ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")
EXCHANGED_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/exchanged-access-token.json")

echo "KEYCLOAK_ID_TOKEN_PAYLOAD"
jwt_part "$ID_TOKEN" 2 | jq "{iss,sub,aud,email,email_verified,name,iat,exp}"

echo "ID_JAG_HEADER"
jwt_part "$ID_JAG" 1 | jq .

echo "ID_JAG_PAYLOAD"
jwt_part "$ID_JAG" 2 | jq "{iss,sub,aud,scope,scp,client_id,email,iat,exp}"

echo "ATHENZ_ACCESS_TOKEN_HEADER"
jwt_part "$ACCESS_TOKEN" 1 | jq .

echo "ATHENZ_ACCESS_TOKEN_PAYLOAD"
jwt_part "$ACCESS_TOKEN" 2 | jq "{iss,sub,aud,scope,scp,client_id,uid,iat,exp}"

echo "EXCHANGED_ATHENZ_ACCESS_TOKEN_HEADER"
jwt_part "$EXCHANGED_ACCESS_TOKEN" 1 | jq .

echo "EXCHANGED_ATHENZ_ACCESS_TOKEN_PAYLOAD"
jwt_part "$EXCHANGED_ACCESS_TOKEN" 2 | jq "{iss,sub,aud,scope,scp,client_id,uid,iat,exp}"
'
```

## 8. End-to-End Script

This script runs the full Identity Chaining flow in one shot — from preparing ZMS domains through issuing all four tokens. It also decodes the JWT payloads and verifies that only the final exchanged Access Token carries the `mcp` audience with the `mcp-clients` role.

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=$(mktemp -d /dev/shm/jag-flow.XXXXXX)
KEY_ID=$(date +%s)
KEY_ID2=$((KEY_ID + 1))
ZMS=https://athenz-zms-server.athenz:4443/zms/v1
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
ADMIN_KEY=/var/run/athenz/athenz_admin.private.pem
ADMIN_CERT=/var/run/athenz/athenz_admin.cert.pem
PARENT_DOMAIN=keycloak
DOWNSTREAM_SUBDOMAIN=downstream
DOWNSTREAM_DOMAIN=$PARENT_DOMAIN.$DOWNSTREAM_SUBDOMAIN
UPSTREAM_PARENT_DOMAIN=agentbroker
UPSTREAM_SUBDOMAIN=upstream
UPSTREAM_DOMAIN=$UPSTREAM_PARENT_DOMAIN.$UPSTREAM_SUBDOMAIN
SOURCE_DOMAIN=$UPSTREAM_PARENT_DOMAIN
TARGET_DOMAIN=mcp
AGENT_SERVICE=agent
DOWNSTREAM_AGENT=$DOWNSTREAM_DOMAIN.$AGENT_SERVICE
UPSTREAM_AGENT=$UPSTREAM_DOMAIN.$AGENT_SERVICE
SOURCE_ROLE_NAME=downstream-agents
SOURCE_COMPAT_ROLE_NAME=mcp-clients
TARGET_ROLE_NAME=mcp-clients
ADMIN_USER=user.athenz_admin
SUBJECT_PRINCIPAL=keycloak:ext.athenz_user@athenz.io

http_post() {
  out=$1
  shift
  code=$(curl -sS -o "$out" -w "%{http_code}" "$@")
  if [ "$code" -lt 200 ] || [ "$code" -ge 300 ]; then
    echo "HTTP_ERROR status=$code output=$out" >&2
    cat "$out" >&2 || true
    exit 1
  fi
}

post_zms_json() {
  out=$1
  url=$2
  data=$3
  code=$(curl -sS -o "$out" -w "%{http_code}" \
    -X POST "$url" \
    --cacert "$CA" \
    --key "$ADMIN_KEY" \
    --cert "$ADMIN_CERT" \
    -H "Content-Type: application/json" \
    -d "$data")
  case "$code" in
    2*) ;;
    *)
      if grep -q "Domain name conflict" "$out"; then
        :
      else
        echo "HTTP_ERROR status=$code output=$out" >&2
        cat "$out" >&2 || true
        exit 1
      fi
      ;;
  esac
}

jwt_payload() {
  token=$1
  payload=$(printf "%s" "$token" | cut -d. -f2 | tr "_-" "/+")
  case $((${#payload} % 4)) in
    0) ;;
    2) payload="${payload}==" ;;
    3) payload="${payload}=" ;;
    *) echo "Invalid JWT payload length" >&2; exit 1 ;;
  esac
  printf "%s" "$payload" | base64 -d
}

openssl genrsa -out "$WORKDIR/downstream-agent.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/downstream-agent.key.pem" \
  -pubout -out "$WORKDIR/downstream-agent.pub.pem" >/dev/null 2>&1
openssl genrsa -out "$WORKDIR/upstream-agent.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/upstream-agent.key.pem" \
  -pubout -out "$WORKDIR/upstream-agent.pub.pem" >/dev/null 2>&1

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$PARENT_DOMAIN" >"$WORKDIR/add-keycloak-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-keycloak-domain.out" "$ZMS/domain" \
    "{\"name\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$DOWNSTREAM_DOMAIN" >"$WORKDIR/add-downstream-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-downstream-domain.out" "$ZMS/subdomain/$PARENT_DOMAIN" \
    "{\"name\":\"$DOWNSTREAM_SUBDOMAIN\",\"parent\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$UPSTREAM_PARENT_DOMAIN" >"$WORKDIR/add-upstream-parent-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-upstream-parent-domain.out" "$ZMS/domain" \
    "{\"name\":\"$UPSTREAM_PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$UPSTREAM_DOMAIN" >"$WORKDIR/add-upstream-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-upstream-domain.out" "$ZMS/subdomain/$UPSTREAM_PARENT_DOMAIN" \
    "{\"name\":\"$UPSTREAM_SUBDOMAIN\",\"parent\":\"$UPSTREAM_PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  add-domain "$TARGET_DOMAIN" >"$WORKDIR/add-target-domain-cli.out" 2>&1 \
  || post_zms_json "$WORKDIR/add-target-domain.out" "$ZMS/domain" \
    "{\"name\":\"$TARGET_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-service "$AGENT_SERVICE" "$KEY_ID" "$WORKDIR/downstream-agent.pub.pem" >"$WORKDIR/add-downstream-service.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-public-key "$AGENT_SERVICE" "$KEY_ID" "$WORKDIR/downstream-agent.pub.pem" >"$WORKDIR/add-downstream-pubkey.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  set-service-client-id "$AGENT_SERVICE" id-jag-client >"$WORKDIR/set-downstream-client-id.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  set-domain-template identity_provisioning \
  instanceprovider=sys.auth.zts service="$AGENT_SERVICE" >"$WORKDIR/set-downstream-template.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-service "$AGENT_SERVICE" "$KEY_ID2" "$WORKDIR/upstream-agent.pub.pem" >"$WORKDIR/add-upstream-service.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-public-key "$AGENT_SERVICE" "$KEY_ID2" "$WORKDIR/upstream-agent.pub.pem" >"$WORKDIR/add-upstream-pubkey.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  set-domain-template identity_provisioning \
  instanceprovider=sys.auth.zts service="$AGENT_SERVICE" >"$WORKDIR/set-upstream-template.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role "$SOURCE_ROLE_NAME" "$SUBJECT_PRINCIPAL" >"$WORKDIR/add-source-role.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-member "$SOURCE_ROLE_NAME" "$SUBJECT_PRINCIPAL" >"$WORKDIR/add-source-member.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role "$SOURCE_COMPAT_ROLE_NAME" "$SUBJECT_PRINCIPAL" >"$WORKDIR/add-source-compat-role.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-member "$SOURCE_COMPAT_ROLE_NAME" "$SUBJECT_PRINCIPAL" >"$WORKDIR/add-source-compat-member.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role jag_exchanger_admin "$DOWNSTREAM_AGENT" >"$WORKDIR/add-jag-role.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-policy jag_exchange_downstream_agents grant zts.jag_exchange to jag_exchanger_admin on role.$SOURCE_ROLE_NAME >"$WORKDIR/add-jag-source-policy.out" 2>&1 \
  || zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
    -d "$SOURCE_DOMAIN" \
    add-assertion jag_exchange_downstream_agents grant zts.jag_exchange to jag_exchanger_admin on role.$SOURCE_ROLE_NAME >>"$WORKDIR/add-jag-source-policy.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-policy jag_exchange_mcp_clients grant zts.jag_exchange to jag_exchanger_admin on role.$SOURCE_COMPAT_ROLE_NAME >"$WORKDIR/add-jag-compat-policy.out" 2>&1 \
  || zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
    -d "$SOURCE_DOMAIN" \
    add-assertion jag_exchange_mcp_clients grant zts.jag_exchange to jag_exchanger_admin on role.$SOURCE_COMPAT_ROLE_NAME >>"$WORKDIR/add-jag-compat-policy.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-regular-role "$TARGET_ROLE_NAME" "$SUBJECT_PRINCIPAL" >"$WORKDIR/add-target-role.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-member "$TARGET_ROLE_NAME" "$SUBJECT_PRINCIPAL" >"$WORKDIR/add-target-member.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  set-domain-template mcp_write_access >"$WORKDIR/add-mcp-write-access.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role token_source_exchanger "$UPSTREAM_AGENT" >"$WORKDIR/add-token-source-role.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-policy token_source_exchange grant zts.token_source_exchange to token_source_exchanger on "$TARGET_DOMAIN" >"$WORKDIR/add-token-source-policy.out" 2>&1 \
  || zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
    -d "$SOURCE_DOMAIN" \
    add-assertion token_source_exchange grant zts.token_source_exchange to token_source_exchanger on "$TARGET_DOMAIN" >>"$WORKDIR/add-token-source-policy.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-regular-role token_target_exchanger "$UPSTREAM_AGENT" >"$WORKDIR/add-token-target-role.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-policy token_target_exchange grant zts.token_target_exchange to token_target_exchanger on "$TARGET_DOMAIN:$SOURCE_DOMAIN:role.$TARGET_ROLE_NAME" >"$WORKDIR/add-token-target-policy.out" 2>&1 \
  || zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
    -d "$TARGET_DOMAIN" \
    add-assertion token_target_exchange grant zts.token_target_exchange to token_target_exchanger on "$TARGET_DOMAIN:$SOURCE_DOMAIN:role.$TARGET_ROLE_NAME" >>"$WORKDIR/add-token-target-policy.out" 2>&1 || true

sleep 10

zms-svctoken \
  -domain "$DOWNSTREAM_DOMAIN" \
  -service "$AGENT_SERVICE" \
  -private-key "$WORKDIR/downstream-agent.key.pem" \
  -key-version "$KEY_ID" | tr -d "\n" > "$WORKDIR/downstream-agent.ntoken"

zts-svccert \
  -zts "$ZTS" \
  -cacert "$CA" \
  -domain "$DOWNSTREAM_DOMAIN" \
  -service "$AGENT_SERVICE" \
  -provider sys.auth.zts \
  -instance "$DOWNSTREAM_AGENT" \
  -attestation-data "$WORKDIR/downstream-agent.ntoken" \
  -dns-domain zts.athenz.cloud \
  -private-key "$WORKDIR/downstream-agent.key.pem" \
  -key-version "$KEY_ID" \
  -cert-file "$WORKDIR/downstream-agent.cert.pem" \
  -signer-cert-file "$WORKDIR/downstream-agent-signer-ca.cert.pem"

zms-svctoken \
  -domain "$UPSTREAM_DOMAIN" \
  -service "$AGENT_SERVICE" \
  -private-key "$WORKDIR/upstream-agent.key.pem" \
  -key-version "$KEY_ID2" | tr -d "\n" > "$WORKDIR/upstream-agent.ntoken"

zts-svccert \
  -zts "$ZTS" \
  -cacert "$CA" \
  -domain "$UPSTREAM_DOMAIN" \
  -service "$AGENT_SERVICE" \
  -provider sys.auth.zts \
  -instance "$UPSTREAM_AGENT" \
  -attestation-data "$WORKDIR/upstream-agent.ntoken" \
  -dns-domain zts.athenz.cloud \
  -private-key "$WORKDIR/upstream-agent.key.pem" \
  -key-version "$KEY_ID2" \
  -cert-file "$WORKDIR/upstream-agent.cert.pem" \
  -signer-cert-file "$WORKDIR/upstream-agent-signer-ca.cert.pem"

http_post "$WORKDIR/keycloak-token.json" \
  -X POST "http://keycloakx-http.keycloak:8080/realms/athenz/protocol/openid-connect/token" \
  -u "id-jag-client:id-jag-client" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "scope=openid profile email" \
  --data-urlencode "username=athenz_user@athenz.io" \
  --data-urlencode "password=password"

ID_TOKEN=$(jq -r .id_token "$WORKDIR/keycloak-token.json")

http_post "$WORKDIR/id-jag.json" \
  -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/downstream-agent.key.pem" \
  --cert "$WORKDIR/downstream-agent.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:id-jag" \
  --data-urlencode "audience=$ZTS" \
  --data-urlencode "scope=$SOURCE_DOMAIN:role.$SOURCE_ROLE_NAME $SOURCE_DOMAIN:role.$SOURCE_COMPAT_ROLE_NAME" \
  --data-urlencode "subject_token=$ID_TOKEN" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:id_token"

ID_JAG=$(jq -r .access_token "$WORKDIR/id-jag.json")

http_post "$WORKDIR/access-token.json" \
  -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/downstream-agent.key.pem" \
  --cert "$WORKDIR/downstream-agent.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
  --data-urlencode "assertion=$ID_JAG"

SOURCE_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")

http_post "$WORKDIR/exchanged-access-token.json" \
  -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/upstream-agent.key.pem" \
  --cert "$WORKDIR/upstream-agent.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:access_token" \
  --data-urlencode "audience=$TARGET_DOMAIN" \
  --data-urlencode "scope=$TARGET_DOMAIN:role.$TARGET_ROLE_NAME" \
  --data-urlencode "subject_token=$SOURCE_ACCESS_TOKEN" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:access_token"

jwt_payload "$ID_JAG" > "$WORKDIR/id-jag.payload.json"
jwt_payload "$SOURCE_ACCESS_TOKEN" > "$WORKDIR/access-token.payload.json"
jwt_payload "$(jq -r .access_token "$WORKDIR/exchanged-access-token.json")" \
  > "$WORKDIR/exchanged-access-token.payload.json"

jq -e \
  --arg aud "$ZTS" \
  --arg source_role "$SOURCE_DOMAIN:role.$SOURCE_ROLE_NAME" \
  --arg compat_role "$SOURCE_DOMAIN:role.$SOURCE_COMPAT_ROLE_NAME" \
  --arg target_role "$TARGET_DOMAIN:role.$TARGET_ROLE_NAME" \
  ".aud == \$aud
   and ((.scp | sort) == ([\$source_role, \$compat_role] | sort))
   and ((.scp | index(\$target_role)) | not)" \
  "$WORKDIR/id-jag.payload.json" >/dev/null

jq -e \
  --arg aud "$SOURCE_DOMAIN" \
  --arg source_role "$SOURCE_ROLE_NAME" \
  --arg compat_role "$SOURCE_COMPAT_ROLE_NAME" \
  ".aud == \$aud
   and ((.scp | sort) == ([\$source_role, \$compat_role] | sort))" \
  "$WORKDIR/access-token.payload.json" >/dev/null

jq -e \
  --arg aud "$TARGET_DOMAIN" \
  --arg target_role "$TARGET_ROLE_NAME" \
  --arg client "$UPSTREAM_AGENT" \
  ".aud == \$aud
   and ((.scp | sort) == ([\$target_role] | sort))
   and .client_id == \$client" \
  "$WORKDIR/exchanged-access-token.payload.json" >/dev/null

echo "WORKDIR=$WORKDIR"
echo "KEYCLOAK_ID_TOKEN=$(jq -r .id_token "$WORKDIR/keycloak-token.json")"
echo "ID_JAG=$(jq -r .access_token "$WORKDIR/id-jag.json")"
echo "ATHENZ_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")"
echo "EXCHANGED_ATHENZ_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/exchanged-access-token.json")"
'
```

## 9. Deploy the MCP Server

**What happens**: Deploys a FastMCP-based MCP server that validates Athenz Access Tokens and authorizes MCP operations based on token scope. The server uses a built-in `JWTVerifier` that checks token signature and issuer against the ZTS JWKS endpoint, and a scope authorization middleware that checks the `mcp:action.write` scope for write operations.

**Command**:

```sh
make -C kubernetes deploy-athenz-mcp-server
```

Wait for the deployment to become ready:

```sh
kubectl -n athenz wait --for=condition=available --timeout=60s deployment/athenz-mcp-server
```

The server listens on port 8000 and exposes the MCP SSE endpoint at `/mcp`.

## 10. Test Read Access (tools/list)

**What happens**: Calls `tools/list` on the MCP server with the exchanged Access Token. This is a read-only operation that succeeds for any valid Athenz Access Token with audience `mcp`, regardless of the token's role scope.

**Command**:

From the `athenz-cli` pod, obtain the exchanged Access Token from Step 6 and call `tools/list`:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example
ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/exchanged-access-token.json")

curl -sfS "http://athenz-mcp-server.athenz:8000/mcp" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
'
```

Expected response (HTTP 200):

```json
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [
      {"name": "get_server_info", "description": "..."},
      {"name": "read_data", "description": "..."},
      {"name": "write_data", "description": "..."}
    ]
  },
  "id": 1
}
```

The JWTVerifier validates the token signature and issuer against the ZTS JWKS endpoint. The scope authorization middleware permits `tools/list` without checking the role scope.

## 11. Test Write Access (tools/call)

**What happens**: Calls `tools/call` on the MCP server with the exchanged Access Token. The scope authorization middleware checks that the token's `scope` includes `mcp:action.write`. Because the `mcp_write_access` template was configured in Step 2, ZTS includes `mcp:action.write` in the token scope during the exchange.

**Command**:

Call `tools/call` with the exchanged Access Token from Step 6:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example
ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/exchanged-access-token.json")

curl -sfS "http://athenz-mcp-server.athenz:8000/mcp" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '"'"'{"jsonrpc":"2.0","method":"tools/call","params":{"name":"write_data","arguments":{"key":"test","value":"hello"}},"id":2}'"'"'
'
```

Expected response (HTTP 200):

```json
{
  "jsonrpc": "2.0",
  "result": {
    "content": [{"type": "text", "text": "{\"status\": \"success\", \"key\": \"test\", \"value\": \"hello\"}"}]
  },
  "id": 2
}
```

The token's scope includes `mcp:action.write` (granted by the `mcp_write_access` template), so the write succeeds immediately.

## 12. Verify Token Scope

**What happens**: Decodes the exchanged Access Token to verify that the Identity Chaining has preserved the original Keycloak user identity and that the scope contains both the role name and the action scope.

**Command**:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
WORKDIR=/dev/shm/jag-flow.example
ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/exchanged-access-token.json")
printf "%s" "$ACCESS_TOKEN" | cut -d. -f2 | tr "_-" "/+" | base64 -d 2>/dev/null | jq "{sub,aud,scope,client_id}"
'
```

Expected output:

```json
{
  "sub": "keycloak:ext.athenz_user@athenz.io",
  "aud": "mcp",
  "scope": "mcp-clients mcp:action.write",
  "client_id": "agentbroker.upstream.agent"
}
```

Key observations:

- `sub` is the mapped Keycloak principal (`keycloak:ext.athenz_user@athenz.io`), propagated through the entire ID-JAG and token exchange chain.
- `scope` contains both `mcp-clients` (the role name) and `mcp:action.write` (the action scope from the `mcp_write_access`).
- `client_id` identifies the Upstream Remote Agent that performed the exchange.

## 13. Verify MCP Server Logs

**What happens**: Checks the MCP server logs to confirm that the JWT claims are visible. The logs show the original Keycloak user identity (`keycloak:ext.athenz_user@athenz.io`) preserved in the `sub` claim throughout the entire token exchange chain.

**Command**:

```sh
kubectl -n athenz logs deployment/athenz-mcp-server --tail=20
```

Expected log output:

```
INFO:athenz-mcp-server:MCP request: method=tools/list tool=- sub=keycloak:ext.athenz_user@athenz.io client_id=agentbroker.upstream.agent aud=mcp scope=mcp-clients mcp:action.write
INFO:athenz-mcp-server:MCP request: method=tools/call tool=write_data sub=keycloak:ext.athenz_user@athenz.io client_id=agentbroker.upstream.agent aud=mcp scope=mcp-clients mcp:action.write
INFO:athenz-mcp-server:write_data called: key=test value=hello
```

The logs demonstrate the end-to-end ID-JAG benefit: the original Keycloak user identity (`keycloak:ext.athenz_user@athenz.io`) is preserved in the `sub` claim throughout the entire token exchange chain (Keycloak ID Token → ID-JAG → Access Token → Exchanged Access Token), and the `scope` carries both the Athenz role membership and the action-level permissions granted by the `mcp_write_access`.

## Summary: Identity Chaining End-to-End

```
Keycloak Login          →  ID-JAG Exchange       →  Access Token       →  Token Exchange      →  MCP Server
                                                                     
sub: 1e5a4f3c...        sub: keycloak:ext.       sub: keycloak:ext.   sub: keycloak:ext.   sub: keycloak:ext.
      (Keycloak UUID)        athenz_user@athenz.io   athenz_user@athenz.io  athenz_user@athenz.io  athenz_user@athenz.io
 aud: id-jag-client      aud: ZTS                 aud: agentbroker      aud: mcp               aud: mcp
                                                                        scope: mcp-clients     scope: mcp-clients
                                                                        + mcp:action.write     + mcp:action.write
```

**What Identity Chaining means for Agent and MCP users**:

1. **Single login**: The user authenticates once with Keycloak. No separate Athenz login is needed.
2. **Identity preserved**: The original Keycloak user identity (`keycloak:ext.athenz_user@athenz.io`) flows through every token exchange without modification.
3. **Audience-scoped**: Each token is scoped to a specific audience (`id-jag-client` → `ZTS` → `agentbroker` → `mcp`), ensuring least-privilege access.
4. **Role-aware**: The token scope carries Athenz role membership (`mcp-clients`) and action permissions (`mcp:action.write`), enabling fine-grained authorization at the MCP server.
5. **Auditable**: The MCP server logs show the original user identity, the client that performed the exchange, and the scope — providing full audit trail from login to MCP operation.

This is Identity Chaining: a single Keycloak login propagates through the entire token exchange chain, arriving at the MCP server with the original user identity intact and the appropriate permissions for authorization.

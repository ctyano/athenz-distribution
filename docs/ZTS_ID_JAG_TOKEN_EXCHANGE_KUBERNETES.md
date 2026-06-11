# Dex ID Token to Athenz ID-JAG and Chained Access Token Exchange on Kubernetes

This document describes how to use the `athenz-cli` pod on Kubernetes to obtain an ID Token from Dex, exchange that ID Token with Athenz ZTS for an ID-JAG token, use the ID-JAG token as a JWT bearer assertion to issue an Athenz Access Token, and then exchange that Access Token for another Access Token in a different fully-qualified Athenz Domain/Role.

Runtime environment assumed by the commands:

- namespace: `athenz`
- Dex issuer: `http://127.0.0.1:5556/dex`
- Dex service endpoint from pod: `http://oauth2.athenz:5556/dex`
- ZMS endpoint: `https://athenz-zms-server.athenz:4443/zms/v1`
- ZTS endpoint: `https://athenz-zts-server.athenz:4443/zts/v1`
- Working directory inside the `athenz-cli` pod: `/dev/shm/jag-flow.*`
- Dex user: `athenz_admin@athenz.io`
- Dex client: `athenz-user-cert`
- Downstream Remote Agent service: `email.downstream.agent`
- Downstream role scope: `email.downstream:role.admin`
- Upstream Remote Agent service: `email.upstream.agent`
- Upstream role scope: `email.upstream:role.admin`

## 1. ZTS OAuth Provider Setup

To allow ZTS to trust Dex ID Tokens and issue ID-JAG tokens, configure the ZTS OAuth provider config.

Dex `sub` values cannot be used directly as Athenz principals in this setup, so this procedure adds a `TokenExchangeIdentityProvider` that maps the Dex ID Token `email` claim to `email:ext.<email>`. With this provider, the Dex user `athenz_admin@athenz.io` is treated as the Athenz principal `email:ext.athenz_admin@athenz.io`.

Provider class:

```java
package com.yahoo.athenz.auth.impl;

import com.yahoo.athenz.auth.TokenExchangeIdentityProvider;
import com.yahoo.athenz.auth.token.OAuth2Token;
import java.util.Collections;
import java.util.List;
import java.util.Locale;

public class DexEmailTokenExchangeIdentityProvider implements TokenExchangeIdentityProvider {
    @Override
    public String getTokenIdentity(OAuth2Token token) {
        Object emailClaim = token.getClaim("email");
        if (emailClaim == null) {
            return null;
        }
        String email = emailClaim.toString().trim().toLowerCase(Locale.ROOT);
        return email.isEmpty() ? null : "email:ext." + email;
    }

    @Override
    public String getTokenAudience(OAuth2Token token) {
        return token.getAudience();
    }

    @Override
    public List<String> getTokenExchangeClaims() {
        return Collections.singletonList("email");
    }
}
```

ZTS OAuth provider config:

```json
[
  {
    "issuerUri": "http://127.0.0.1:5556/dex",
    "jwksUri": "http://oauth2.athenz:5556/dex/keys",
    "providerClassName": "com.yahoo.athenz.auth.impl.DexEmailTokenExchangeIdentityProvider"
  }
]
```

Apply the Kubernetes settings as follows.

```sh
kubectl -n athenz get configmap athenz-zts-conf -o json \
  | jq '.data["zts.properties"] |=
      if contains("athenz.zts.oauth_provider_config_file=") then .
      else . + "\n# Dex provider for ID-JAG token exchange\nathenz.zts.oauth_provider_config_file=/opt/athenz/zts/oauth-provider-config/oauth-provider-config.json\n"
      end' \
  | kubectl apply -f -

kubectl -n athenz create configmap zts-oauth-provider-config \
  --from-file=oauth-provider-config.json=/path/to/oauth-provider-config.json \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n athenz create configmap zts-dex-email-provider \
  --from-file=dex-email-provider.jar=/path/to/dex-email-provider.jar \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n athenz patch deployment athenz-zts-server --type strategic -p '{
  "spec": {
    "template": {
      "spec": {
        "volumes": [
          {
            "name": "zts-oauth-provider-config",
            "configMap": {
              "name": "zts-oauth-provider-config"
            }
          },
          {
            "name": "zts-dex-email-provider",
            "configMap": {
              "name": "zts-dex-email-provider"
            }
          }
        ],
        "containers": [
          {
            "name": "athenz-zts-server",
            "volumeMounts": [
              {
                "name": "zts-oauth-provider-config",
                "mountPath": "/opt/athenz/zts/oauth-provider-config",
                "readOnly": true
              },
              {
                "name": "zts-dex-email-provider",
                "mountPath": "/athenz/dex-email-provider",
                "readOnly": true
              }
            ]
          }
        ]
      }
    }
  }
}'

kubectl -n athenz set env deployment/athenz-zts-server \
  USER_CLASSPATH='/usr/lib/jars/*:/athenz/plugins/*:/athenz/dex-email-provider/*'

kubectl -n athenz rollout restart deployment/athenz-zts-server
kubectl -n athenz rollout status deployment/athenz-zts-server --timeout=180s
```

Verification command:

```sh
kubectl -n athenz exec deployment/athenz-zts-server -- /bin/sh -lc '
echo "USER_CLASSPATH=$USER_CLASSPATH"
ls -l /athenz/dex-email-provider /athenz/dex-email-provider/dex-email-provider.jar
'
```

## 2. Prepare ZMS Objects and Permissions

This procedure uses two Remote Agents:

| Agent | Athenz domain | Athenz service principal | Responsibility |
| --- | --- | --- | --- |
| Downstream Remote Agent | `email.downstream` | `email.downstream.agent` | Sends the ID-JAG token to ZTS and obtains the first Athenz Access Token. |
| Upstream Remote Agent | `email.upstream` | `email.upstream.agent` | Sends the first Athenz Access Token to ZTS and exchanges it for a second Athenz Access Token. |

Create `email` as the parent top-level domain, then create `email.downstream` and `email.upstream` as subdomains under it. Register an Athenz service named `agent` in each subdomain, and issue a Copper Argos Service Cert for each service through the pre-registered `sys.auth.zts` identity provider. The commands below use `curl` for the top-level domain and subdomain creation calls, matching the existing Kubernetes CLI documentation for this distribution.

The Downstream Remote Agent is also the OAuth client that requests ID-JAG tokens, so configure `email.downstream.agent` with the Dex client ID `athenz-user-cert`.

Grant `email.downstream.agent` the `zts.jag_exchange` permission on `email.downstream:role.admin`. The role itself is created in the `email.downstream` subdomain and contains the mapped Dex principal `email:ext.athenz_admin@athenz.io`.

Create all token-exchange roles in `email.downstream` and `email.upstream`; no personal or bootstrap subdomain is used for those roles.

The later Access Token Exchange step uses `email.downstream:role.admin` as the source role and `email.upstream:role.admin` as the target role. Because the Access Token issued from ID-JAG in this procedure does not contain `may_act` and the exchange request does not send `actor_token`, ZTS treats the Access Token Exchange as impersonation and requires both source and target exchange policies:

| Policy action | Policy domain | Token-exchange role | Resource checked by ZTS | Authorized service |
| --- | --- | --- | --- | --- |
| `zts.token_source_exchange` | `email.downstream` | `token_source_exchanger` | `email.downstream:email.upstream` | `email.upstream.agent` |
| `zts.token_target_exchange` | `email.upstream` | `token_target_exchanger` | `email.upstream:email.downstream:role.admin` | `email.upstream.agent` |

A `zts.token_source_exchange`-free Access Token Exchange can only be constructed through the delegation path, where the request includes `actor_token` and the `subject_token` already has `may_act.sub` matching the actor identity. The ID-JAG-to-Access-Token step in this document does not issue a source Access Token with `may_act`, so the end-to-end procedure below intentionally keeps `zts.token_source_exchange`.

Note: pass the `zms-cli add-policy` assertion as separate arguments, not as one quoted argument.

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

PARENT_DOMAIN=email
DOWNSTREAM_SUBDOMAIN=downstream
UPSTREAM_SUBDOMAIN=upstream
DOWNSTREAM_DOMAIN=$PARENT_DOMAIN.$DOWNSTREAM_SUBDOMAIN
UPSTREAM_DOMAIN=$PARENT_DOMAIN.$UPSTREAM_SUBDOMAIN
AGENT_SERVICE=agent
DOWNSTREAM_AGENT=$DOWNSTREAM_DOMAIN.$AGENT_SERVICE
UPSTREAM_AGENT=$UPSTREAM_DOMAIN.$AGENT_SERVICE
ROLE_NAME=admin
ADMIN_USER=user.athenz_admin
SUBJECT_PRINCIPAL=email:ext.athenz_admin@athenz.io

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
    2*|409) ;;
    *)
      echo "HTTP_ERROR status=$code output=$out" >&2
      cat "$out" >&2 || true
      exit 1
      ;;
  esac
}

openssl genrsa -out "$WORKDIR/downstream-agent.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/downstream-agent.key.pem" \
  -pubout -out "$WORKDIR/downstream-agent.pub.pem" >/dev/null 2>&1

openssl genrsa -out "$WORKDIR/upstream-agent.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/upstream-agent.key.pem" \
  -pubout -out "$WORKDIR/upstream-agent.pub.pem" >/dev/null 2>&1

post_zms_json "$WORKDIR/add-email-domain.out" "$ZMS/domain" \
  "{\"name\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

post_zms_json "$WORKDIR/add-downstream-domain.out" "$ZMS/subdomain/$PARENT_DOMAIN" \
  "{\"name\":\"$DOWNSTREAM_SUBDOMAIN\",\"parent\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

post_zms_json "$WORKDIR/add-upstream-domain.out" "$ZMS/subdomain/$PARENT_DOMAIN" \
  "{\"name\":\"$UPSTREAM_SUBDOMAIN\",\"parent\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-service "$AGENT_SERVICE" "$KEY_ID" "$WORKDIR/downstream-agent.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-public-key "$AGENT_SERVICE" "$KEY_ID" "$WORKDIR/downstream-agent.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  set-service-client-id "$AGENT_SERVICE" athenz-user-cert

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
  -d "$DOWNSTREAM_DOMAIN" \
  add-member "$ROLE_NAME" "$SUBJECT_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-regular-role jag_exchanger_admin "$DOWNSTREAM_AGENT" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-policy jag_exchange_admin grant zts.jag_exchange to jag_exchanger_admin on role.admin || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-member "$ROLE_NAME" "$SUBJECT_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-regular-role token_source_exchanger "$UPSTREAM_AGENT" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-policy token_source_exchange grant zts.token_source_exchange to token_source_exchanger on "$UPSTREAM_DOMAIN" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-regular-role token_target_exchanger "$UPSTREAM_AGENT" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-policy token_target_exchange grant zts.token_target_exchange to token_target_exchanger on "$UPSTREAM_DOMAIN:$DOWNSTREAM_DOMAIN:role.$ROLE_NAME" || true

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

## 3. Request Dex ID Token

Issue an ID Token from Dex with the password grant.

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example

curl -sfS -X POST "http://oauth2.athenz:5556/dex/token" \
  -u "athenz-user-cert:athenz-user-cert" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "scope=openid profile email" \
  --data-urlencode "username=athenz_admin@athenz.io" \
  --data-urlencode "password=password" \
  > "$WORKDIR/dex-token.json"

jq -r .id_token "$WORKDIR/dex-token.json"
'
```

Request parameters:

| Parameter | Value |
| --- | --- |
| endpoint | `http://oauth2.athenz:5556/dex/token` |
| auth | HTTP Basic: `athenz-user-cert:athenz-user-cert` |
| `grant_type` | `password` |
| `scope` | `openid profile email` |
| `username` | `athenz_admin@athenz.io` |
| `password` | `password` |

Response field used in the next step:

| Field | Meaning |
| --- | --- |
| `id_token` | OIDC ID Token issued by Dex. Use this value as the ZTS token exchange `subject_token`. |

Decoded JWT payload example:

```json
{
  "iss": "http://127.0.0.1:5556/dex",
  "sub": "CgxhdGhlbnpfYWRtaW4SBWxvY2Fs",
  "aud": "athenz-user-cert",
  "email": "athenz_admin@athenz.io",
  "email_verified": true,
  "name": "athenz_admin",
  "iat": 1781007285,
  "exp": 1781093685
}
```

## 4. Exchange Dex ID Token for ID-JAG

Pass the Dex ID Token to ZTS `/oauth2/token` as the `subject_token` and request an ID-JAG token.

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
ID_TOKEN=$(jq -r .id_token "$WORKDIR/dex-token.json")

curl -sfS -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/downstream-agent.key.pem" \
  --cert "$WORKDIR/downstream-agent.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:id-jag" \
  --data-urlencode "audience=$ZTS" \
  --data-urlencode "scope=email.downstream:role.admin" \
  --data-urlencode "subject_token=$ID_TOKEN" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:id_token" \
  > "$WORKDIR/id-jag.json"

jq -r .access_token "$WORKDIR/id-jag.json"
'
```

Request parameters:

| Parameter | Value |
| --- | --- |
| endpoint | `https://athenz-zts-server.athenz:4443/zts/v1/oauth2/token` |
| client authentication | mTLS with the Downstream Remote Agent `email.downstream.agent` Service Cert |
| `grant_type` | `urn:ietf:params:oauth:grant-type:token-exchange` |
| `requested_token_type` | `urn:ietf:params:oauth:token-type:id-jag` |
| `audience` | `https://athenz-zts-server.athenz:4443/zts/v1` |
| `scope` | `email.downstream:role.admin` |
| `subject_token` | Dex ID Token |
| `subject_token_type` | `urn:ietf:params:oauth:token-type:id_token` |

Response example:

```json
{
  "access_token": "<ID-JAG JWT>",
  "token_type": "N_A",
  "expires_in": 7200,
  "scope": "email.downstream:role.admin",
  "issued_token_type": "urn:ietf:params:oauth:token-type:id-jag"
}
```

Decoded JWT header example:

```json
{
  "kid": "athenz-zts-server-6b4767ff86-x5kmf",
  "typ": "oauth-id-jag+jwt",
  "alg": "RS256"
}
```

Decoded JWT payload example:

```json
{
  "iss": "https://athenz-zts-server.athenz:4443/zts/v1",
  "sub": "email:ext.athenz_admin@athenz.io",
  "aud": "https://athenz-zts-server.athenz:4443/zts/v1",
  "scope": "email.downstream:role.admin",
  "scp": [
    "email.downstream:role.admin"
  ],
  "client_id": "email.downstream.agent",
  "email": "athenz_admin@athenz.io",
  "iat": 1781007285,
  "exp": 1781014485
}
```

Important checks:

- `typ` is `oauth-id-jag+jwt`.
- `sub` is mapped to `email:ext.athenz_admin@athenz.io`.
- `scope` is `email.downstream:role.admin`.
- The response `issued_token_type` is `urn:ietf:params:oauth:token-type:id-jag`.

## 5. Exchange ID-JAG for Athenz Access Token

Pass the ID-JAG token to ZTS `/oauth2/token` as a JWT bearer assertion and issue an Athenz Access Token.

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

Request parameters:

| Parameter | Value |
| --- | --- |
| endpoint | `https://athenz-zts-server.athenz:4443/zts/v1/oauth2/token` |
| client authentication | mTLS with the Downstream Remote Agent `email.downstream.agent` Service Cert |
| `grant_type` | `urn:ietf:params:oauth:grant-type:jwt-bearer` |
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
  "kid": "athenz-zts-server-6b4767ff86-x5kmf",
  "typ": "at+jwt",
  "alg": "RS256"
}
```

Decoded JWT payload example:

```json
{
  "iss": "https://athenz-zts-server.athenz:4443/zts/v1",
  "sub": "email:ext.athenz_admin@athenz.io",
  "aud": "email.downstream",
  "scope": "admin",
  "scp": [
    "admin"
  ],
  "client_id": "email.downstream.agent",
  "uid": "email:ext.athenz_admin@athenz.io",
  "iat": 1781007285,
  "exp": 1781014485
}
```

Important checks:

- `typ` is `at+jwt`.
- `sub` and `uid` are `email:ext.athenz_admin@athenz.io`.
- `aud` is the role domain, `email.downstream`.
- `scope` is converted to the role name, `admin`.

## 6. Exchange the Access Token for Another Domain/Role Access Token

The previous step issued an Access Token with:

- subject: `email:ext.athenz_admin@athenz.io`
- audience: `email.downstream`
- scope: `admin`
- client: `email.downstream.agent`

This step is performed by the Upstream Remote Agent. It uses the first Access Token as the `subject_token` and exchanges it for another Access Token in `email.upstream:role.admin`. The exchange request is authenticated with the Upstream Remote Agent Service Cert for `email.upstream.agent`.

This is the standard OAuth 2.0 Token Exchange path in ZTS, not the ID-JAG JWT bearer path. This procedure uses the Access Token issued in step 5 as `subject_token` and does not send `actor_token`, so ZTS handles it as an impersonation-style access-token exchange. In that path, the Service Cert authenticates the Upstream Remote Agent, but it does not replace the source-domain authorization check. ZTS evaluates both of these permissions:

| Policy action | Policy domain | Resource checked by ZTS | Purpose |
| --- | --- | --- | --- |
| `zts.token_source_exchange` | source domain, `email.downstream` | `email.downstream:email.upstream` | Allows the Upstream Remote Agent to exchange a token from the downstream audience to the upstream audience. |
| `zts.token_target_exchange` | target domain, `email.upstream` | `email.upstream:email.downstream:role.admin` | Allows the Upstream Remote Agent to request the upstream target role for tokens whose source audience is `email.downstream`. |

The target role must include the source Access Token subject, because ZTS verifies that the subject principal has access to the requested target role before issuing the exchanged Access Token.

The target fully-qualified role is different from the source fully-qualified role: the source is `email.downstream:role.admin`, and the target is `email.upstream:role.admin`. The simple role name intentionally remains `admin` because ZTS validates the requested role names against the source Access Token `scope`. Since the first Access Token has `scope=admin`, a request for `email.upstream:role.admin` passes the subset check. To request a target role such as `email.upstream:role.exchange_target`, first issue the source Access Token with `exchange_target` included in its scope.

`zts.token_source_exchange` is not evaluated only in the delegation-style access-token exchange path. That path requires all of the following:

- The exchange request includes `actor_token` and `actor_token_type`.
- The authenticated principal from the actor token matches the actor token `sub`.
- The `subject_token` contains `may_act.sub`, and that value matches the actor token `sub`.

In that delegation path, ZTS evaluates `zts.token_target_exchange` for the target role, but not `zts.token_source_exchange`. The Access Token issued from ID-JAG in step 5 does not contain `may_act`, and the ID-JAG JWT bearer exchange path does not add `may_act` from an `actor` request parameter. Therefore, this end-to-end Dex ID Token -> ID-JAG -> Access Token -> Access Token procedure cannot omit `zts.token_source_exchange` without changing how the source Access Token is issued.

The subdomains, services, Copper Argos Service Certs, target role, and exchange policies were prepared in step 2. Exchange the first Access Token for an Access Token in the upstream target domain and role:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/dev/shm/jag-flow.example
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
UPSTREAM_DOMAIN=email.upstream
ROLE_NAME=admin
SOURCE_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")

curl -sfS -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/upstream-agent.key.pem" \
  --cert "$WORKDIR/upstream-agent.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:access_token" \
  --data-urlencode "audience=$UPSTREAM_DOMAIN" \
  --data-urlencode "scope=$UPSTREAM_DOMAIN:role.$ROLE_NAME" \
  --data-urlencode "subject_token=$SOURCE_ACCESS_TOKEN" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:access_token" \
  > "$WORKDIR/exchanged-access-token.json"

jq -r .access_token "$WORKDIR/exchanged-access-token.json"
'
```

Request parameters:

| Parameter | Value |
| --- | --- |
| endpoint | `https://athenz-zts-server.athenz:4443/zts/v1/oauth2/token` |
| client authentication | mTLS with the Upstream Remote Agent `email.upstream.agent` Service Cert |
| `grant_type` | `urn:ietf:params:oauth:grant-type:token-exchange` |
| `requested_token_type` | `urn:ietf:params:oauth:token-type:access_token` |
| `audience` | `email.upstream` |
| `scope` | `email.upstream:role.admin` |
| `subject_token` | The first Athenz Access Token issued from the ID-JAG token |
| `subject_token_type` | `urn:ietf:params:oauth:token-type:access_token` |

Response example:

```json
{
  "access_token": "<Exchanged Athenz Access Token JWT>",
  "token_type": "Bearer",
  "expires_in": 7200,
  "scope": "email.upstream:role.admin"
}
```

Decoded JWT header example:

```json
{
  "kid": "athenz-zts-server-6b4767ff86-x5kmf",
  "typ": "at+jwt",
  "alg": "RS256"
}
```

Decoded JWT payload example:

```json
{
  "iss": "https://athenz-zts-server.athenz:4443/zts/v1",
  "sub": "email:ext.athenz_admin@athenz.io",
  "aud": "email.upstream",
  "scope": "admin",
  "scp": [
    "admin"
  ],
  "client_id": "email.upstream.agent",
  "uid": "email.upstream.agent",
  "iat": 1781007285,
  "exp": 1781014485
}
```

Important checks:

- `typ` is `at+jwt`.
- `sub` remains the source Access Token subject, `email:ext.athenz_admin@athenz.io`.
- `aud` is changed from `email.downstream` to `email.upstream`.
- The full role changes from `email.downstream:role.admin` to `email.upstream:role.admin`.
- The JWT `scope` claim remains `admin`, because Athenz Access Tokens carry role names in `scope` and the target role name must be a subset of the source Access Token roles.
- `client_id` and `uid` identify the Upstream Remote Agent service principal, `email.upstream.agent`.

## 7. JWT Decode Helper

Use this helper to inspect JWT headers and payloads inside the pod.

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

ID_TOKEN=$(jq -r .id_token "$WORKDIR/dex-token.json")
ID_JAG=$(jq -r .access_token "$WORKDIR/id-jag.json")
ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")
EXCHANGED_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/exchanged-access-token.json")

echo "DEX_ID_TOKEN_PAYLOAD"
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

The script below runs the full flow, from preparing the ZMS subdomains and Remote Agent services through issuing all four tokens.

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
PARENT_DOMAIN=email
DOWNSTREAM_SUBDOMAIN=downstream
UPSTREAM_SUBDOMAIN=upstream
DOWNSTREAM_DOMAIN=$PARENT_DOMAIN.$DOWNSTREAM_SUBDOMAIN
UPSTREAM_DOMAIN=$PARENT_DOMAIN.$UPSTREAM_SUBDOMAIN
AGENT_SERVICE=agent
DOWNSTREAM_AGENT=$DOWNSTREAM_DOMAIN.$AGENT_SERVICE
UPSTREAM_AGENT=$UPSTREAM_DOMAIN.$AGENT_SERVICE
ROLE_NAME=admin
ADMIN_USER=user.athenz_admin
SUBJECT_PRINCIPAL=email:ext.athenz_admin@athenz.io

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
    2*|409) ;;
    *)
      echo "HTTP_ERROR status=$code output=$out" >&2
      cat "$out" >&2 || true
      exit 1
      ;;
  esac
}

openssl genrsa -out "$WORKDIR/downstream-agent.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/downstream-agent.key.pem" \
  -pubout -out "$WORKDIR/downstream-agent.pub.pem" >/dev/null 2>&1
openssl genrsa -out "$WORKDIR/upstream-agent.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/upstream-agent.key.pem" \
  -pubout -out "$WORKDIR/upstream-agent.pub.pem" >/dev/null 2>&1

post_zms_json "$WORKDIR/add-email-domain.out" "$ZMS/domain" \
  "{\"name\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

post_zms_json "$WORKDIR/add-downstream-domain.out" "$ZMS/subdomain/$PARENT_DOMAIN" \
  "{\"name\":\"$DOWNSTREAM_SUBDOMAIN\",\"parent\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

post_zms_json "$WORKDIR/add-upstream-domain.out" "$ZMS/subdomain/$PARENT_DOMAIN" \
  "{\"name\":\"$UPSTREAM_SUBDOMAIN\",\"parent\":\"$PARENT_DOMAIN\",\"adminUsers\":[\"$ADMIN_USER\"]}"

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-service "$AGENT_SERVICE" "$KEY_ID" "$WORKDIR/downstream-agent.pub.pem" >"$WORKDIR/add-downstream-service.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-public-key "$AGENT_SERVICE" "$KEY_ID" "$WORKDIR/downstream-agent.pub.pem" >"$WORKDIR/add-downstream-pubkey.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  set-service-client-id "$AGENT_SERVICE" athenz-user-cert >"$WORKDIR/set-downstream-client-id.out" 2>&1 || true

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
  -d "$DOWNSTREAM_DOMAIN" \
  add-member "$ROLE_NAME" "$SUBJECT_PRINCIPAL" >"$WORKDIR/add-downstream-member.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-regular-role jag_exchanger_admin "$DOWNSTREAM_AGENT" >"$WORKDIR/add-jag-role.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-policy jag_exchange_admin grant zts.jag_exchange to jag_exchanger_admin on role.admin >"$WORKDIR/add-jag-policy.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-member "$ROLE_NAME" "$SUBJECT_PRINCIPAL" >"$WORKDIR/add-upstream-member.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-regular-role token_source_exchanger "$UPSTREAM_AGENT" >"$WORKDIR/add-token-source-role.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$DOWNSTREAM_DOMAIN" \
  add-policy token_source_exchange grant zts.token_source_exchange to token_source_exchanger on "$UPSTREAM_DOMAIN" >"$WORKDIR/add-token-source-policy.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-regular-role token_target_exchanger "$UPSTREAM_AGENT" >"$WORKDIR/add-token-target-role.out" 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$UPSTREAM_DOMAIN" \
  add-policy token_target_exchange grant zts.token_target_exchange to token_target_exchanger on "$UPSTREAM_DOMAIN:$DOWNSTREAM_DOMAIN:role.$ROLE_NAME" >"$WORKDIR/add-token-target-policy.out" 2>&1 || true

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

http_post "$WORKDIR/dex-token.json" \
  -X POST "http://oauth2.athenz:5556/dex/token" \
  -u "athenz-user-cert:athenz-user-cert" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "scope=openid profile email" \
  --data-urlencode "username=athenz_admin@athenz.io" \
  --data-urlencode "password=password"

ID_TOKEN=$(jq -r .id_token "$WORKDIR/dex-token.json")

http_post "$WORKDIR/id-jag.json" \
  -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/downstream-agent.key.pem" \
  --cert "$WORKDIR/downstream-agent.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:id-jag" \
  --data-urlencode "audience=$ZTS" \
  --data-urlencode "scope=$DOWNSTREAM_DOMAIN:role.$ROLE_NAME" \
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
  --data-urlencode "audience=$UPSTREAM_DOMAIN" \
  --data-urlencode "scope=$UPSTREAM_DOMAIN:role.$ROLE_NAME" \
  --data-urlencode "subject_token=$SOURCE_ACCESS_TOKEN" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:access_token"

echo "WORKDIR=$WORKDIR"
echo "DEX_ID_TOKEN=$(jq -r .id_token "$WORKDIR/dex-token.json")"
echo "ID_JAG=$(jq -r .access_token "$WORKDIR/id-jag.json")"
echo "ATHENZ_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")"
echo "EXCHANGED_ATHENZ_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/exchanged-access-token.json")"
'
```

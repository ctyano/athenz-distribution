# Dex ID Token to Athenz ID-JAG and Chained Access Token Exchange on Kubernetes

This document describes how to use the `athenz-cli` pod on Kubernetes to obtain an ID Token from Dex, exchange that ID Token with Athenz ZTS for an ID-JAG token, use the ID-JAG token as a JWT bearer assertion to issue an Athenz Access Token, and then exchange that Access Token for another Access Token in a different fully-qualified Athenz Domain/Role.

Verified runtime environment:

- namespace: `athenz`
- Dex issuer: `http://127.0.0.1:5556/dex`
- Dex service endpoint from pod: `http://oauth2.athenz:5556/dex`
- ZMS endpoint: `https://athenz-zms-server.athenz:4443/zms/v1`
- ZTS endpoint: `https://athenz-zts-server.athenz:4443/zts/v1`
- Dex user: `athenz_admin@athenz.io`
- Dex client: `athenz-user-cert`
- Athenz service used as OAuth client: `home.athenz_admin.jag-client`
- Requested role scope: `email:role.admin`
- Athenz service used for downstream access-token exchange: `home.athenz_admin.token-exchanger`
- Downstream target role scope: `home.athenz_admin:role.admin`

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

Create `home.athenz_admin.jag-client` as the OAuth client that requests ID-JAG tokens, and apply the `identity_provisioning` template so that a service certificate can be issued for it.

Also grant `home.athenz_admin.jag-client` the `zts.jag_exchange` permission on `email:role.admin`.

Note: pass the `zms-cli add-policy` assertion as separate arguments, not as one quoted argument.

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=$(mktemp -d /tmp/jag-flow.XXXXXX)
KEY_ID=$(date +%s)
ZMS=https://athenz-zms-server.athenz:4443/zms/v1
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
ADMIN_KEY=/var/run/athenz/athenz_admin.private.pem
ADMIN_CERT=/var/run/athenz/athenz_admin.cert.pem

openssl genrsa -out "$WORKDIR/jag-client.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/jag-client.key.pem" \
  -pubout -out "$WORKDIR/jag-client.pub.pem" >/dev/null 2>&1

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  add-service jag-client "$KEY_ID" "$WORKDIR/jag-client.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  add-public-key jag-client "$KEY_ID" "$WORKDIR/jag-client.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  set-service-client-id jag-client athenz-user-cert

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  set-domain-template identity_provisioning \
  instanceprovider=sys.auth.zts service=jag-client

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d email \
  add-member admin email:ext.athenz_admin@athenz.io || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d email \
  add-regular-role jag_exchanger_admin home.athenz_admin.jag-client || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d email \
  add-policy jag_exchange_admin grant zts.jag_exchange to jag_exchanger_admin on role.admin || true

sleep 10

zms-svctoken \
  -domain home.athenz_admin \
  -service jag-client \
  -private-key "$WORKDIR/jag-client.key.pem" \
  -key-version "$KEY_ID" | tr -d "\n" > "$WORKDIR/jag-client.ntoken"

zts-svccert \
  -zts "$ZTS" \
  -cacert "$CA" \
  -domain home.athenz_admin \
  -service jag-client \
  -provider sys.auth.zts \
  -instance jag-client \
  -attestation-data "$WORKDIR/jag-client.ntoken" \
  -dns-domain zts.athenz.cloud \
  -private-key "$WORKDIR/jag-client.key.pem" \
  -key-version "$KEY_ID" \
  -cert-file "$WORKDIR/jag-client.cert.pem" \
  -signer-cert-file "$WORKDIR/jag-signer-ca.cert.pem"

echo "WORKDIR=$WORKDIR"
'
```

The split examples below use the `jag-client.key.pem` and `jag-client.cert.pem` files created in the `WORKDIR` printed by the previous command. The examples use `WORKDIR=/tmp/jag-flow.GcPobi` from the verified run; replace it with the value printed in your own environment when you rerun the procedure.

## 3. Request Dex ID Token

Issue an ID Token from Dex with the password grant.

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/tmp/jag-flow.GcPobi

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

WORKDIR=/tmp/jag-flow.GcPobi
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
ID_TOKEN=$(jq -r .id_token "$WORKDIR/dex-token.json")

curl -sfS -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/jag-client.key.pem" \
  --cert "$WORKDIR/jag-client.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:id-jag" \
  --data-urlencode "audience=$ZTS" \
  --data-urlencode "scope=email:role.admin" \
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
| client authentication | mTLS with `home.athenz_admin.jag-client` service certificate |
| `grant_type` | `urn:ietf:params:oauth:grant-type:token-exchange` |
| `requested_token_type` | `urn:ietf:params:oauth:token-type:id-jag` |
| `audience` | `https://athenz-zts-server.athenz:4443/zts/v1` |
| `scope` | `email:role.admin` |
| `subject_token` | Dex ID Token |
| `subject_token_type` | `urn:ietf:params:oauth:token-type:id_token` |

Response example:

```json
{
  "access_token": "<ID-JAG JWT>",
  "token_type": "N_A",
  "expires_in": 7200,
  "scope": "email:role.admin",
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
  "scope": "email:role.admin",
  "scp": [
    "email:role.admin"
  ],
  "client_id": "home.athenz_admin.jag-client",
  "email": "athenz_admin@athenz.io",
  "iat": 1781007285,
  "exp": 1781014485
}
```

Important checks:

- `typ` is `oauth-id-jag+jwt`.
- `sub` is mapped to `email:ext.athenz_admin@athenz.io`.
- `scope` is `email:role.admin`.
- The response `issued_token_type` is `urn:ietf:params:oauth:token-type:id-jag`.

## 5. Exchange ID-JAG for Athenz Access Token

Pass the ID-JAG token to ZTS `/oauth2/token` as a JWT bearer assertion and issue an Athenz Access Token.

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/tmp/jag-flow.GcPobi
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
ID_JAG=$(jq -r .access_token "$WORKDIR/id-jag.json")

curl -sfS -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/jag-client.key.pem" \
  --cert "$WORKDIR/jag-client.cert.pem" \
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
| client authentication | mTLS with `home.athenz_admin.jag-client` service certificate |
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
  "aud": "email",
  "scope": "admin",
  "scp": [
    "admin"
  ],
  "client_id": "home.athenz_admin.jag-client",
  "uid": "email:ext.athenz_admin@athenz.io",
  "iat": 1781007285,
  "exp": 1781014485
}
```

Important checks:

- `typ` is `at+jwt`.
- `sub` and `uid` are `email:ext.athenz_admin@athenz.io`.
- `aud` is the role domain, `email`.
- `scope` is converted to the role name, `admin`.

## 6. Exchange the Access Token for Another Domain/Role Access Token

The previous step issued an Access Token with:

- subject: `email:ext.athenz_admin@athenz.io`
- audience: `email`
- scope: `admin`
- client: `home.athenz_admin.jag-client`

This step uses that Access Token as the `subject_token` and exchanges it for another Access Token in a different fully-qualified Athenz Domain/Role. The exchange request is authenticated with a second service certificate for `home.athenz_admin.token-exchanger`.

This is the standard OAuth 2.0 Token Exchange path in ZTS, not the ID-JAG JWT bearer path. For an impersonation-style access-token exchange without `actor_token`, ZTS evaluates both of these permissions:

| Policy action | Policy domain | Resource checked by ZTS | Purpose |
| --- | --- | --- | --- |
| `zts.token_source_exchange` | source domain, `email` | `email:home.athenz_admin` | Allows the exchanger service to exchange a token from the source audience to the target audience. |
| `zts.token_target_exchange` | target domain, `home.athenz_admin` | `home.athenz_admin:email:role.admin` | Allows the exchanger service to request the target role for tokens whose source audience is `email`. |

The target role must include the source Access Token subject, because ZTS verifies that the subject principal has access to the requested target role before issuing the exchanged Access Token.

The target fully-qualified role is different from the source fully-qualified role: the source is `email:role.admin`, and the target is `home.athenz_admin:role.admin`. The simple role name intentionally remains `admin` because ZTS validates the requested role names against the source Access Token `scope`. Since the first Access Token has `scope=admin`, a request for `home.athenz_admin:role.admin` passes the subset check. To request a target role such as `home.athenz_admin:role.exchange_target`, first issue the source Access Token with `exchange_target` included in its scope.

`zts.token_source_exchange` is not evaluated only in the delegation-style access-token exchange path. That path requires all of the following:

- The exchange request includes `actor_token` and `actor_token_type`.
- The authenticated principal from the actor token matches the actor token `sub`.
- The `subject_token` contains `may_act.sub`, and that value matches the actor token `sub`.

In that delegation path, ZTS evaluates `zts.token_target_exchange` for the target role, but not `zts.token_source_exchange`. The Access Token issued from ID-JAG in step 5 does not contain `may_act`, and the ID-JAG JWT bearer exchange path does not add `may_act` from an `actor` request parameter. Therefore, this end-to-end Dex ID Token -> ID-JAG -> Access Token -> Access Token procedure cannot omit `zts.token_source_exchange` without changing how the source Access Token is issued.

Prepare the second service certificate, the target role, and the exchange policies:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/tmp/jag-flow.GcPobi
KEY_ID=$(date +%s)
KEY_ID2=$((KEY_ID + 1))
ZMS=https://athenz-zms-server.athenz:4443/zms/v1
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
ADMIN_KEY=/var/run/athenz/athenz_admin.private.pem
ADMIN_CERT=/var/run/athenz/athenz_admin.cert.pem

SOURCE_DOMAIN=email
TARGET_DOMAIN=home.athenz_admin
TARGET_ROLE=admin
SOURCE_SUBJECT=email:ext.athenz_admin@athenz.io
EXCHANGER_SERVICE=token-exchanger
EXCHANGER_PRINCIPAL=home.athenz_admin.token-exchanger

openssl genrsa -out "$WORKDIR/token-exchanger.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/token-exchanger.key.pem" \
  -pubout -out "$WORKDIR/token-exchanger.pub.pem" >/dev/null 2>&1

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  add-service "$EXCHANGER_SERVICE" "$KEY_ID2" "$WORKDIR/token-exchanger.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  add-public-key "$EXCHANGER_SERVICE" "$KEY_ID2" "$WORKDIR/token-exchanger.pub.pem" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  set-domain-template identity_provisioning \
  instanceprovider=sys.auth.zts service="$EXCHANGER_SERVICE" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-member "$TARGET_ROLE" "$SOURCE_SUBJECT" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role token_source_exchanger "$EXCHANGER_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-policy token_source_exchange grant zts.token_source_exchange to token_source_exchanger on "$TARGET_DOMAIN" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-regular-role token_target_exchanger "$EXCHANGER_PRINCIPAL" || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-policy token_target_exchange grant zts.token_target_exchange to token_target_exchanger on "$TARGET_DOMAIN:$SOURCE_DOMAIN:role.$TARGET_ROLE" || true

sleep 10

zms-svctoken \
  -domain home.athenz_admin \
  -service "$EXCHANGER_SERVICE" \
  -private-key "$WORKDIR/token-exchanger.key.pem" \
  -key-version "$KEY_ID2" | tr -d "\n" > "$WORKDIR/token-exchanger.ntoken"

zts-svccert \
  -zts "$ZTS" \
  -cacert "$CA" \
  -domain home.athenz_admin \
  -service "$EXCHANGER_SERVICE" \
  -provider sys.auth.zts \
  -instance "$EXCHANGER_SERVICE" \
  -attestation-data "$WORKDIR/token-exchanger.ntoken" \
  -dns-domain zts.athenz.cloud \
  -private-key "$WORKDIR/token-exchanger.key.pem" \
  -key-version "$KEY_ID2" \
  -cert-file "$WORKDIR/token-exchanger.cert.pem" \
  -signer-cert-file "$WORKDIR/token-exchanger-signer-ca.cert.pem"
'
```

Then exchange the first Access Token for an Access Token in the target domain and role:

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/tmp/jag-flow.GcPobi
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
TARGET_DOMAIN=home.athenz_admin
TARGET_ROLE=admin
SOURCE_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")

curl -sfS -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/token-exchanger.key.pem" \
  --cert "$WORKDIR/token-exchanger.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:access_token" \
  --data-urlencode "audience=$TARGET_DOMAIN" \
  --data-urlencode "scope=$TARGET_DOMAIN:role.$TARGET_ROLE" \
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
| client authentication | mTLS with `home.athenz_admin.token-exchanger` service certificate |
| `grant_type` | `urn:ietf:params:oauth:grant-type:token-exchange` |
| `requested_token_type` | `urn:ietf:params:oauth:token-type:access_token` |
| `audience` | `home.athenz_admin` |
| `scope` | `home.athenz_admin:role.admin` |
| `subject_token` | The first Athenz Access Token issued from the ID-JAG token |
| `subject_token_type` | `urn:ietf:params:oauth:token-type:access_token` |

Response example:

```json
{
  "access_token": "<Exchanged Athenz Access Token JWT>",
  "token_type": "Bearer",
  "expires_in": 7200,
  "scope": "home.athenz_admin:role.admin"
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
  "aud": "home.athenz_admin",
  "scope": "admin",
  "scp": [
    "admin"
  ],
  "client_id": "home.athenz_admin.token-exchanger",
  "uid": "home.athenz_admin.token-exchanger",
  "iat": 1781007285,
  "exp": 1781014485
}
```

Important checks:

- `typ` is `at+jwt`.
- `sub` remains the source Access Token subject, `email:ext.athenz_admin@athenz.io`.
- `aud` is changed from `email` to `home.athenz_admin`.
- The full role changes from `email:role.admin` to `home.athenz_admin:role.admin`.
- The JWT `scope` claim remains `admin`, because Athenz Access Tokens carry role names in `scope` and the target role name must be a subset of the source Access Token roles.
- `client_id` and `uid` identify the second service certificate principal, `home.athenz_admin.token-exchanger`.

## 7. JWT Decode Helper

Use this helper to inspect JWT headers and payloads inside the pod.

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=/tmp/jag-flow.GcPobi

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

The script below runs the full flow, from preparing the ZMS objects through issuing all four tokens.

```sh
kubectl -n athenz exec deployment/athenz-cli -- /bin/sh -lc '
set -eu

WORKDIR=$(mktemp -d /tmp/jag-flow.XXXXXX)
KEY_ID=$(date +%s)
KEY_ID2=$((KEY_ID + 1))
ZMS=https://athenz-zms-server.athenz:4443/zms/v1
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
CA=/etc/ssl/certs/ca-certificates.crt
ADMIN_KEY=/var/run/athenz/athenz_admin.private.pem
ADMIN_CERT=/var/run/athenz/athenz_admin.cert.pem
SOURCE_DOMAIN=email
TARGET_DOMAIN=home.athenz_admin
TARGET_ROLE=admin
SOURCE_SUBJECT=email:ext.athenz_admin@athenz.io
EXCHANGER_SERVICE=token-exchanger
EXCHANGER_PRINCIPAL=home.athenz_admin.token-exchanger

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

openssl genrsa -out "$WORKDIR/jag-client.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/jag-client.key.pem" \
  -pubout -out "$WORKDIR/jag-client.pub.pem" >/dev/null 2>&1
openssl genrsa -out "$WORKDIR/token-exchanger.key.pem" 2048 >/dev/null 2>&1
openssl rsa -in "$WORKDIR/token-exchanger.key.pem" \
  -pubout -out "$WORKDIR/token-exchanger.pub.pem" >/dev/null 2>&1

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  add-service jag-client "$KEY_ID" "$WORKDIR/jag-client.pub.pem" >/tmp/add-service.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  add-public-key jag-client "$KEY_ID" "$WORKDIR/jag-client.pub.pem" >/tmp/add-pubkey.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  set-service-client-id jag-client athenz-user-cert >/tmp/set-client-id.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  set-domain-template identity_provisioning \
  instanceprovider=sys.auth.zts service=jag-client >/tmp/set-template.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d email \
  add-member admin email:ext.athenz_admin@athenz.io >/tmp/add-email-member.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d email \
  add-regular-role jag_exchanger_admin home.athenz_admin.jag-client >/tmp/add-jag-role.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d email \
  add-policy jag_exchange_admin grant zts.jag_exchange to jag_exchanger_admin on role.admin >/tmp/add-jag-policy.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  add-service "$EXCHANGER_SERVICE" "$KEY_ID2" "$WORKDIR/token-exchanger.pub.pem" >/tmp/add-exchanger-service.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  add-public-key "$EXCHANGER_SERVICE" "$KEY_ID2" "$WORKDIR/token-exchanger.pub.pem" >/tmp/add-exchanger-pubkey.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d home.athenz_admin \
  set-domain-template identity_provisioning \
  instanceprovider=sys.auth.zts service="$EXCHANGER_SERVICE" >/tmp/set-exchanger-template.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-member "$TARGET_ROLE" "$SOURCE_SUBJECT" >/tmp/add-target-member.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-regular-role token_source_exchanger "$EXCHANGER_PRINCIPAL" >/tmp/add-token-source-role.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$SOURCE_DOMAIN" \
  add-policy token_source_exchange grant zts.token_source_exchange to token_source_exchanger on "$TARGET_DOMAIN" >/tmp/add-token-source-policy.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-regular-role token_target_exchanger "$EXCHANGER_PRINCIPAL" >/tmp/add-token-target-role.out 2>&1 || true

zms-cli -z "$ZMS" -key "$ADMIN_KEY" -cert "$ADMIN_CERT" -c "$CA" \
  -d "$TARGET_DOMAIN" \
  add-policy token_target_exchange grant zts.token_target_exchange to token_target_exchanger on "$TARGET_DOMAIN:$SOURCE_DOMAIN:role.$TARGET_ROLE" >/tmp/add-token-target-policy.out 2>&1 || true

sleep 10

zms-svctoken \
  -domain home.athenz_admin \
  -service jag-client \
  -private-key "$WORKDIR/jag-client.key.pem" \
  -key-version "$KEY_ID" | tr -d "\n" > "$WORKDIR/jag-client.ntoken"

zts-svccert \
  -zts "$ZTS" \
  -cacert "$CA" \
  -domain home.athenz_admin \
  -service jag-client \
  -provider sys.auth.zts \
  -instance jag-client \
  -attestation-data "$WORKDIR/jag-client.ntoken" \
  -dns-domain zts.athenz.cloud \
  -private-key "$WORKDIR/jag-client.key.pem" \
  -key-version "$KEY_ID" \
  -cert-file "$WORKDIR/jag-client.cert.pem" \
  -signer-cert-file "$WORKDIR/jag-signer-ca.cert.pem"

zms-svctoken \
  -domain home.athenz_admin \
  -service "$EXCHANGER_SERVICE" \
  -private-key "$WORKDIR/token-exchanger.key.pem" \
  -key-version "$KEY_ID2" | tr -d "\n" > "$WORKDIR/token-exchanger.ntoken"

zts-svccert \
  -zts "$ZTS" \
  -cacert "$CA" \
  -domain home.athenz_admin \
  -service "$EXCHANGER_SERVICE" \
  -provider sys.auth.zts \
  -instance "$EXCHANGER_SERVICE" \
  -attestation-data "$WORKDIR/token-exchanger.ntoken" \
  -dns-domain zts.athenz.cloud \
  -private-key "$WORKDIR/token-exchanger.key.pem" \
  -key-version "$KEY_ID2" \
  -cert-file "$WORKDIR/token-exchanger.cert.pem" \
  -signer-cert-file "$WORKDIR/token-exchanger-signer-ca.cert.pem"

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
  --key "$WORKDIR/jag-client.key.pem" \
  --cert "$WORKDIR/jag-client.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:id-jag" \
  --data-urlencode "audience=$ZTS" \
  --data-urlencode "scope=email:role.admin" \
  --data-urlencode "subject_token=$ID_TOKEN" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:id_token"

ID_JAG=$(jq -r .access_token "$WORKDIR/id-jag.json")

http_post "$WORKDIR/access-token.json" \
  -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/jag-client.key.pem" \
  --cert "$WORKDIR/jag-client.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
  --data-urlencode "assertion=$ID_JAG"

SOURCE_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")

http_post "$WORKDIR/exchanged-access-token.json" \
  -X POST "$ZTS/oauth2/token" \
  --key "$WORKDIR/token-exchanger.key.pem" \
  --cert "$WORKDIR/token-exchanger.cert.pem" \
  --cacert "$CA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:access_token" \
  --data-urlencode "audience=$TARGET_DOMAIN" \
  --data-urlencode "scope=$TARGET_DOMAIN:role.$TARGET_ROLE" \
  --data-urlencode "subject_token=$SOURCE_ACCESS_TOKEN" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:access_token"

echo "WORKDIR=$WORKDIR"
echo "DEX_ID_TOKEN=$(jq -r .id_token "$WORKDIR/dex-token.json")"
echo "ID_JAG=$(jq -r .access_token "$WORKDIR/id-jag.json")"
echo "ATHENZ_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/access-token.json")"
echo "EXCHANGED_ATHENZ_ACCESS_TOKEN=$(jq -r .access_token "$WORKDIR/exchanged-access-token.json")"
'
```

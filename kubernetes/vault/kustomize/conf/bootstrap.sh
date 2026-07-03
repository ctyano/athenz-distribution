#!/bin/sh
set -e

echo "Waiting for Vault to be ready..."
for i in $(seq 1 30); do
  if vault status >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

vault auth list | grep -q "^approle/" || vault auth enable -path=approle approle

vault secrets list | grep -q "^pki/" || vault secrets enable -path=pki pki

if ! vault read -field=certificate pki/cert/ca >/dev/null 2>&1; then
  vault write -field=certificate pki/root/generate/internal \
    common_name="Athenz Vault PKI CA" ttl=87600h >/dev/null
fi

vault write pki/config/urls \
  issuing_certificates="http://vault.vault.svc.cluster.local:8200/v1/pki/ca" \
  crl_distribution_points="http://vault.vault.svc.cluster.local:8200/v1/pki/crl" \
  >/dev/null

vault write pki/roles/athenz \
  allow_any_name=true \
  max_ttl=43200m >/dev/null

vault secrets list | grep -q "^rootca/" || vault secrets enable -path=rootca pki

if ! vault read -field=certificate rootca/cert/ca >/dev/null 2>&1; then
  vault write -field=certificate rootca/root/generate/internal \
    common_name="Athenz Vault Root CA" ttl=87600h >/dev/null
fi

vault write rootca/config/urls \
  issuing_certificates="http://vault.vault.svc.cluster.local:8200/v1/rootca/ca" \
  crl_distribution_points="http://vault.vault.svc.cluster.local:8200/v1/rootca/crl" \
  >/dev/null

vault write rootca/roles/issuers \
  allow_any_name=true \
  max_ttl=43200m >/dev/null

vault write auth/approle/role/athenz \
  secret_id_ttl=0 \
  token_ttl=0 \
  token_max_ttl=0 \
  policies=athenz >/dev/null

vault read -field=role_id auth/approle/role/athenz/role-id > /vault/bootstrap/role_id
vault write -f -field=secret_id auth/approle/role/athenz/secret-id > /vault/bootstrap/secret_id

echo "Creating admin policy..."
vault policy write admin - <<'EOF'
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

echo "Creating athenz policy..."
vault policy write athenz - <<'EOF'
path "pki/issue/athenz" {
  capabilities = ["create", "update"]
}
path "pki/sign/athenz" {
  capabilities = ["create", "update"]
}
path "pki/roles/athenz" {
  capabilities = ["read", "list"]
}
EOF

echo "Configuring OIDC auth methods..."

# ----- Dex (default) -----
vault auth list | grep -q "^dex/" || vault auth enable -path=dex oidc

vault write auth/dex/config \
  oidc_discovery_url="http://127.0.0.1:5556/dex" \
  oidc_client_id="vault" \
  oidc_client_secret="vault" \
  default_role="dex" \
  redirect_addr="http://localhost:8200"

vault write auth/dex/role/dex \
  user_claim="email" \
  oidc_scopes="openid,email" \
  allowed_redirect_uris="http://localhost:8200/v1/auth/dex/oidc/callback" \
  allowed_redirect_uris="http://127.0.0.1:8200/v1/auth/dex/oidc/callback" \
  allowed_redirect_uris="http://localhost:8200/ui/vault/auth/dex/oidc/callback" \
  allowed_redirect_uris="http://127.0.0.1:8200/ui/vault/auth/dex/oidc/callback" \
  policies="admin" \
  listing_visibility="unauth"

vault auth tune -listing-visibility=unauth dex/ >/dev/null

echo "Dex OIDC configured"

# ----- Keycloak (alternative) -----
vault auth list | grep -q "^keycloak/" || vault auth enable -path=keycloak oidc

vault write auth/keycloak/config \
  oidc_discovery_url="http://127.0.0.1:18080/realms/athenz" \
  oidc_client_id="vault" \
  oidc_client_secret="vault" \
  default_role="keycloak" \
  redirect_addr="http://localhost:8200"

vault write auth/keycloak/role/keycloak \
  user_claim="email" \
  oidc_scopes="openid,email" \
  allowed_redirect_uris="http://localhost:8200/v1/auth/keycloak/oidc/callback" \
  allowed_redirect_uris="http://127.0.0.1:8200/v1/auth/keycloak/oidc/callback" \
  allowed_redirect_uris="http://localhost:8200/ui/vault/auth/keycloak/oidc/callback" \
  allowed_redirect_uris="http://127.0.0.1:8200/ui/vault/auth/keycloak/oidc/callback" \
  policies="admin" \
  listing_visibility="unauth"

vault auth tune -listing-visibility=unauth keycloak/ >/dev/null

echo "Keycloak OIDC configured"

echo "Vault bootstrap completed"
echo "role_id: $(cat /vault/bootstrap/role_id)"
echo "secret_id: $(cat /vault/bootstrap/secret_id)"

sleep infinity

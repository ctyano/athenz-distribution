#!/bin/sh
set -e

apk add --no-cache jq >/dev/null 2>&1 || true

echo "Waiting for Vault to be ready..."
for i in $(seq 1 30); do
  if vault status >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

vault auth enable -path=approle approle 2>/dev/null || echo "AppRole already enabled"

vault secrets enable -path=pki pki 2>/dev/null || echo "PKI at pki already enabled"

if ! vault read -field=certificate pki/cert/ca >/dev/null 2>&1; then
  vault write -field=certificate pki/root/generate/internal \
    common_name="Athenz Vault PKI CA" ttl=87600h >/dev/null
fi

vault write pki/config/urls \
  issuing_certificates="http://vault.vault.svc.cluster.local:8200/v1/pki/ca" \
  crl_distribution_points="http://vault.vault.svc.cluster.local:8200/v1/pki/crl" \
  >/dev/null 2>&1 || echo "PKI URLs already configured"

vault write pki/roles/athenz \
  allow_any_name=true \
  max_ttl=43200m >/dev/null 2>&1 || echo "Role athenz already exists"

vault secrets enable -path=rootca pki 2>/dev/null || echo "PKI at rootca already enabled"

if ! vault read -field=certificate rootca/cert/ca >/dev/null 2>&1; then
  vault write -field=certificate rootca/root/generate/internal \
    common_name="Athenz Vault Root CA" ttl=87600h >/dev/null
fi

vault write rootca/config/urls \
  issuing_certificates="http://vault.vault.svc.cluster.local:8200/v1/rootca/ca" \
  crl_distribution_points="http://vault.vault.svc.cluster.local:8200/v1/rootca/crl" \
  >/dev/null 2>&1 || echo "RootCA URLs already configured"

vault write rootca/roles/issuers \
  allow_any_name=true \
  max_ttl=43200m >/dev/null 2>&1 || echo "Role issuers already exists"

vault write auth/approle/role/athenz \
  secret_id_ttl=0 \
  token_ttl=0 \
  token_max_ttl=0 \
  policies=default >/dev/null 2>&1 || echo "AppRole athenz already exists"

vault read -field=role_id auth/approle/role/athenz/role-id > /vault/bootstrap/role_id
vault write -f -field=secret_id auth/approle/role/athenz/secret-id > /vault/bootstrap/secret_id

echo "Vault bootstrap completed"
echo "role_id: $(cat /vault/bootstrap/role_id)"
echo "secret_id: $(cat /vault/bootstrap/secret_id)"

sleep infinity

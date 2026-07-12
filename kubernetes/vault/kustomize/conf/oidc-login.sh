#!/bin/bash
# Initiate Vault OIDC login.
# Usage: ./oidc-login.sh [dex|keycloak]
# Requires: kubectl, curl, VAULT_ADDR=http://localhost:8200

set -e

PROVIDER="${1:-dex}"
PORT_FORWARD_PID=""

cleanup() {
  if [ -n "$PORT_FORWARD_PID" ]; then
    kill "$PORT_FORWARD_PID" 2>/dev/null || true
  fi
  if [ -n "$PF_PID" ]; then
    kill "$PF_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Start port-forward if not already running
if ! curl -sf http://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
  echo "Starting Vault port-forward..."
  kubectl -n vault port-forward service/vault 8200:8200 &
  PORT_FORWARD_PID=$!
  echo "Waiting for port-forward..."
  for i in $(seq 1 10); do
    if curl -sf http://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
fi

# Set provider-specific parameters
case "$PROVIDER" in
  dex)
    REDIRECT_URI="http://localhost:8200/v1/auth/dex/oidc/callback"
    AUTH_URL_PATH="auth/dex/oidc/auth_url"
    PORT_FORWARD_DEX_CMD="kubectl -n athenz port-forward service/oauth2 5556:5556"
    ;;
  keycloak)
    REDIRECT_URI="http://localhost:8200/v1/auth/keycloak/oidc/callback"
    AUTH_URL_PATH="auth/keycloak/oidc/auth_url"
    PORT_FORWARD_DEX_CMD="kubectl -n keycloak port-forward service/keycloakx-http 18080:80"
    ;;
  *)
    echo "Usage: $0 [dex|keycloak]"
    exit 1
    ;;
esac

# Start provider port-forward
echo "Starting $PROVIDER port-forward..."
$PORT_FORWARD_DEX_CMD &
PF_PID=$!
# We don't wait for it - it'll run in background

echo "Getting OIDC auth URL for provider: $PROVIDER"
RESPONSE=$(curl -sf -X POST \
  -d "role=$PROVIDER&redirect_uri=$REDIRECT_URI" \
  "http://127.0.0.1:8200/v1/$AUTH_URL_PATH")

AUTH_URL=$(echo "$RESPONSE" | jq -r '.data.auth_url')

echo "Opening browser for OIDC login..."
echo "Auth URL: $AUTH_URL"

case "$(uname -s)" in
  Darwin) open "$AUTH_URL" ;;
  Linux)  xdg-open "$AUTH_URL" 2>/dev/null || sensible-browser "$AUTH_URL" 2>/dev/null || echo "Open URL manually in browser" ;;
  *)      echo "Open URL manually in browser" ;;
esac

echo ""
echo "After logging in with $PROVIDER, you will be redirected back to Vault."
echo "Check the Vault UI for the authenticated session."
echo ""
echo "Press Ctrl+C to stop port-forwards when done."
wait

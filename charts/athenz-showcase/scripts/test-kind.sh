#!/usr/bin/env bash
# Run the same functional checks as the Kustomize workflows against Helm releases.
set -euo pipefail

scenario=${1:?usage: test-kind.sh basic|crypki|syncer|userauth|vault}
case "$scenario" in
  basic|crypki|syncer|userauth|vault) ;;
  *) echo "Unknown showcase scenario: $scenario" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/../../.."
chart=charts/athenz-showcase
image_tag=${ATHENZ_IMAGE_TAG:-latest}
helm_values=()
if [[ -n "${HELM_VALUES_FILE:-}" ]]; then
  helm_values=(-f "$HELM_VALUES_FILE")
fi

install_phase() {
  local phase=$1
  shift
  helm upgrade --install "showcase-$phase" "$chart" --namespace default \
    "${helm_values[@]}" \
    --set "phase=$phase" \
    --set-string "registries.internal=${DOCKER_REGISTRY:-ghcr.io/ctyano/}" \
    --set-string "registries.external=${DOCKER_REGISTRY_EXTERNAL:-ghcr.io/ctyano/}" \
    --set-string "registries.dockerio=${DOCKERIO_REGISTRY:-docker.io}" \
    --set-string "registries.quayio=${QUAYIO_REGISTRY:-quay.io}" \
    --set-string "athenzImageTag=$image_tag" \
    --wait --timeout 15m "$@"
}

wait_for_scheduled_sync() {
  local since=$1
  local resource=$2
  local deadline=$((SECONDS + 180))
  local state run_time run_status run_epoch
  while (( SECONDS < deadline )); do
    if state=$(make --no-print-directory show-kubernetes-athenz-zms-syncer-status); then
      run_time=$(jq -r '."run-time" // empty' <<<"$state" 2>/dev/null || true)
      run_status=$(jq -r '."run-status" // empty' <<<"$state" 2>/dev/null || true)
      run_epoch=$(python3 -c 'import datetime, sys; print(int(datetime.datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00")).timestamp()))' "$run_time" 2>/dev/null || echo 0)
      if [[ -n "$run_time" && "$run_epoch" -gt "$since" && "$run_status" == 0 ]]; then
        echo "Scheduled ZMS sync completed after $resource registration at $run_time"
        return
      fi
    fi
    sleep 5
  done
  echo "Timed out waiting for scheduled ZMS sync after $resource registration" >&2
  echo "${state:-}" >&2
  return 1
}

check_workload_routes() {
  local route attempt
  for route in client2extauthz client2extauthzmtls \
      client2webhookauthzmtls client2webhookauthzjwt client2webhookauthzmtlsjwt \
      client2filterauthzmtls client2filterauthzjwt client2filterauthzmtlsjwt \
      client2authzproxy; do
    for attempt in {1..12}; do
      if kubectl -n athenz exec deployment/athenz-cli -c athenz-cli -- \
          curl -fsS "https://client.athenz.svc.cluster.local/$route" | jq -e '.request' >/dev/null; then
        echo "Verified $route"
        break
      fi
      if (( attempt == 12 )); then
        echo "Workload route failed: $route" >&2
        return 1
      fi
      sleep 5
    done
  done
}

install_phase pki

case "$scenario" in
  crypki|userauth)
    install_phase crypki
    make test-kubernetes-crypki-softhsm
    signer=crypki
    ;;
  vault)
    install_phase vault
    make check-kubernetes-vault test-kubernetes-vault-pki
    signer=vault
    ;;
  *) signer=keystore ;;
esac

install_phase core --set "zts.certSigner=$signer"
make check-kubernetes-athenz

if [[ "$scenario" == syncer ]]; then
  install_phase rustfs
  make test-kubernetes-rustfs
  install_phase syncer
  make test-kubernetes-athenz-zms-syncer
  helm upgrade showcase-core "$chart" --namespace default --reuse-values \
    "${helm_values[@]}" \
    --set zts.changeLogStore=s3 --wait --timeout 15m
  make test-kubernetes-athenz test-kubernetes-athenz-solution-template-reload
else
  make test-kubernetes-athenz
  if [[ "$scenario" == basic ]]; then
    make test-kubernetes-athenz-solution-template-reload
  fi
fi

install_phase identityprovider
if [[ "$scenario" == syncer ]]; then
  since_identityprovider=$(date -u +%s)
  wait_for_scheduled_sync "$since_identityprovider" identityprovider
fi
make test-kubernetes-athenz-identityprovider

install_phase workloads
if [[ "$scenario" == syncer ]]; then
  since_workloads=$(date -u +%s)
  wait_for_scheduled_sync "$since_workloads" workloads
fi

if [[ "$scenario" == basic || "$scenario" == crypki || "$scenario" == syncer ]]; then
  for test in authorizer authzenvoy authzwebhook authzproxy client \
      envoy2envoyextauthz envoy2envoywebhook envoy2envoyfilter envoy2authzproxy; do
    make "test-kubernetes-athenz-$test"
  done
fi

check_workload_routes

if [[ "$scenario" == userauth || "$scenario" == vault ]]; then
  install_phase oauth2
  make test-kubernetes-athenz-oauth2
fi

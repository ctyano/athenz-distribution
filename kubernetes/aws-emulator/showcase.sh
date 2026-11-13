#!/bin/sh
set -eu

cd "$(dirname "$0")"

ACCOUNT=000000000000
DOMAIN=awsshowcase
ROLE=showcaserole
AWS_CLI_IMAGE=${AWS_CLI_IMAGE:-docker.io/amazon/aws-cli:latest}
ZMS=https://athenz-zms-server.athenz:4443/zms/v1
ZTS=https://athenz-zts-server.athenz:4443/zts/v1
EMULATOR=https://aws-emulator.athenz:9297

zms_cli() {
    kubectl -n athenz exec deployment/athenz-cli -- zms-cli -z "$ZMS" -d "$DOMAIN" "$@"
}

# Run a short-lived AWS CLI pod. Do not log its environment: it contains only
# credentials minted by this local emulator, but they still must stay private.
aws_cli() {
    name="aws-emulator-cli-$(date +%s)-$$"
    kubectl -n athenz run "$name" --restart=Never \
        --image="$AWS_CLI_IMAGE" --image-pull-policy=IfNotPresent \
        --env="AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
        --env="AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
        --env="AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN:-}" \
        --env=AWS_EC2_METADATA_DISABLED=true \
        --env=AWS_DEFAULT_REGION=us-east-1 \
        -- --endpoint-url "$EMULATOR" --no-verify-ssl "$@" >/dev/null

    result=1
    for attempt in $(seq 1 60); do
        phase=$(kubectl -n athenz get pod "$name" -o jsonpath='{.status.phase}')
        case "$phase" in
            Succeeded) result=0; break ;;
            Failed) break ;;
        esac
        sleep 2
    done
    kubectl -n athenz logs "$name" || true
    kubectl -n athenz delete pod "$name" --ignore-not-found --wait=false >/dev/null
    return "$result"
}

read_emulator_credentials() {
    credentials=$(kubectl -n athenz exec deployment/athenz-zts-server -c aws-emulator -- \
        cat /home/emulator/.aws/emulator/9297/emulator_credentials)
    AWS_ACCESS_KEY_ID=$(printf '%s\n' "$credentials" | sed -n 's/^aws_access_key_id[[:space:]]*=[[:space:]]*//p')
    AWS_SECRET_ACCESS_KEY=$(printf '%s\n' "$credentials" | sed -n 's/^aws_secret_access_key[[:space:]]*=[[:space:]]*//p')
    test -n "$AWS_ACCESS_KEY_ID" && test -n "$AWS_SECRET_ACCESS_KEY"
}

setup() {
    kubectl apply -k .
    kubectl -n athenz patch deployment athenz-zts-server --type strategic --patch-file patch-zts.yaml
    kubectl -n athenz rollout status deployment/athenz-zts-server --timeout=180s
    read_emulator_credentials

    trust='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"sts:AssumeRole"}]}'
    if ! output=$(aws_cli iam create-role --role-name "$ROLE" --assume-role-policy-document "$trust" 2>&1); then
        printf '%s\n' "$output" | grep -q EntityAlreadyExists || {
            printf '%s\n' "$output" >&2
            exit 1
        }
    fi

    if ! zms_cli show-domain "$DOMAIN" >/dev/null 2>&1; then
        kubectl -n athenz exec deployment/athenz-cli -- curl -fsS \
            --key /var/run/athenz/athenz_admin.private.pem \
            --cert /var/run/athenz/athenz_admin.cert.pem \
            --cacert /etc/ssl/certs/ca-certificates.crt \
            -H 'Content-Type: application/json' \
            -d '{"name":"awsshowcase","adminUsers":["user.athenz_admin"]}' \
            "$ZMS/domain" >/dev/null
    fi
    zms_cli set-aws-account "$ACCOUNT"
    if ! zms_cli show-role assumers >/dev/null 2>&1; then
        zms_cli add-regular-role assumers user.athenz_admin
    fi
    if ! zms_cli show-policy allowassume >/dev/null 2>&1; then
        zms_cli add-policy allowassume grant assume_aws_role to assumers on "$ROLE"
    fi
}

test_credentials() {
    for attempt in $(seq 1 60); do
        if response=$(kubectl -n athenz exec deployment/athenz-cli -- curl -fsS \
            --key /var/run/athenz/athenz_admin.private.pem \
            --cert /var/run/athenz/athenz_admin.cert.pem \
            --cacert /etc/ssl/certs/ca-certificates.crt \
            "$ZTS/domain/$DOMAIN/role/$ROLE/creds" 2>/dev/null); then
            break
        fi
        sleep 2
    done
    test -n "${response:-}" || { echo 'ZTS did not return AWS credentials' >&2; exit 1; }
    printf '%s\n' "$response" | jq -e \
        '([.accessKeyId, .secretAccessKey, .sessionToken] | all(. != null and length > 0)) and .expiration != null' >/dev/null

    kubectl apply -f test-pod.yaml >/dev/null
    trap 'kubectl -n athenz delete pod aws-emulator-client --ignore-not-found --wait=false >/dev/null' EXIT
    kubectl -n athenz wait --for=condition=Ready pod/aws-emulator-client --timeout=120s >/dev/null
    identity=
    for attempt in $(seq 1 60); do
        if identity=$(kubectl -n athenz exec pod/aws-emulator-client -c aws-cli -- \
            aws --endpoint-url "$EMULATOR" --no-verify-ssl sts get-caller-identity 2>/dev/null); then
            break
        fi
        sleep 2
    done
    test -n "$identity" || { echo 'AWS CLI could not use the IMDSv2 credentials' >&2; exit 1; }
    printf '%s\n' "$identity" | jq -e --arg account "$ACCOUNT" --arg role "$ROLE" \
        '.Account == $account and (.Arn | startswith("arn:aws:sts::" + $account + ":assumed-role/" + $role + "/"))' >/dev/null

    status=$(kubectl -n athenz exec deployment/athenz-cli -- curl -sS \
        --key /var/run/athenz/athenz_admin.private.pem \
        --cert /var/run/athenz/athenz_admin.cert.pem \
        --cacert /etc/ssl/certs/ca-certificates.crt \
        -o /dev/null -w '%{http_code}' \
        "$ZTS/domain/$DOMAIN/role/unauthorized/creds")
    test "$status" = 403
    echo 'ZTS returned usable AWS temporary credentials and denied an unauthorized role.'
}

case "${1:-}" in
    setup) setup ;;
    test) test_credentials ;;
    *) echo "usage: $0 setup|test" >&2; exit 2 ;;
esac

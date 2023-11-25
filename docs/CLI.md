# CLI Instruction

## Testing with Kubernetes environment

### Prerequisite

- docker
- kubectl
- jq
- step

### Athenz Domain Management 

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        list-domain

kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d sys.auth \
        show-domain
```

### Retriving identity certificate

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-svctoken \
        -domain home.athenz_admin \
        -service showcase \
        -private-key /var/run/athenz/athenz_admin.private.pem \
        -key-version 0 \
    | tr -d '\n' \
    | tee /tmp/.ntoken

kubectl -n athenz exec deployment/athenz-cli -it -- \
    zts-svccert \
      -zts https://athenz-zts-server.athenz:4443/zts/v1 \
      -domain home.athenz_admin \
      -service showcase \
      -provider sys.auth.zts \
      -instance $(hostname) \
      -attestation-data /tmp/.ntoken \
      -dns-domain zts.athenz.cloud \
      -private-key /var/run/athenz/athenz_admin.private.pem \
      -key-version 0 \
      -cert-file /tmp/home.athenz_admin.showcase.cert.pem \
      -signer-cert-file /tmp/ca.cert.pem
```

### Retriving tokens

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zts-roletoken \
        -zts https://athenz-zts-server.athenz:4443/zts/v1 \
        -svc-key-file /var/run/athenz/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
        -domain sys.auth \
        -role admin \
        | rev | cut -d';' -f2- | rev \
        | tr ';' '\n'

kubectl -n athenz exec deployment/athenz-cli -it -- \
    zts-accesstoken \
        -zts https://athenz-zts-server.athenz:4443/zts/v1 \
        -svc-key-file /var/run/athenz/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
        -domain sys.auth \
        -roles admin \
        | jq -r .access_token \
        | jq -Rr 'split(".") | .[0,1] | @base64d' \
        | jq -r .
```

### Retriving public keys

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    athenz-conf \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -t https://athenz-zts-server.athenz:4443/zts/v1 \
        -svc-key-file /var/run/athenz/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
        -o /dev/stdout

kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -s \
        -H"Content-type: application/json" \
        --key /var/run/athenz/athenz_admin.private.pem \
        --cert /var/run/athenz/athenz_admin.cert.pem \
        "https://athenz-zts-server.athenz:4443/zts/v1/oauth2/keys?rfc=true" \
| tee keys/jwks.json
```

### Retriving Policies

https://datatracker.ietf.org/doc/html/draft-smith-oauth-json-web-document-00

```
DOMAIN=sys.auth \
; kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -sXPOST \
        -H "Content-type: application/json" \
        -d"{\"policyVersions\":{\"\":\"\"}}" \
        --key /var/run/athenz/athenz_admin.private.pem \
        --cert /var/run/athenz/athenz_admin.cert.pem \
        "https://athenz-zts-server.athenz:4443/zts/v1/domain/${DOMAIN:-sys.auth}/policy/signed" \
| jq -r '[.protected,.payload,.signature] | join(".")' \
| step crypto jws verify --jwks=keys/jwks.json \
&& printf "\nValid Policy\n" || printf "\nInvalid Policy\n"
```

## Testing with Docker environment

### Athenz Domain Management 

```
docker exec -it athenz-cli \
    zms-cli \
        -c /admin/ca.cert.pem \
        -key /admin/athenz_admin.private.pem \
        -cert /admin/athenz_admin.cert.pem \
        -z https://athenz-zms-server:4443/zms/v1 \
        list-domain

docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /admin/ca.cert.pem \
        -key /admin/athenz_admin.private.pem \
        -cert /admin/athenz_admin.cert.pem \
        -d sys.auth \
        show-domain
```

### Retriving identity certificate

```
docker exec -it athenz-cli /bin/sh -c \
    zms-svctoken \
        -domain home.athenz_admin \
        -service showcase \
        -private-key /admin/athenz_admin.private.pem \
        -key-version 0 \
    | tr -d '\n' \
    | tee /admin/.ntoken

docker exec -it athenz-cli /bin/sh -c \
    zts-svccert \
      -zts https://athenz-zts-server:4443/zts/v1 \
      -domain home.athenz_admin \
      -service showcase \
      -provider sys.auth.zts \
      -instance $(hostname) \
      -attestation-data /admin/.ntoken \
      -dns-domain zts.athenz.cloud \
      -private-key /admin/athenz_admin.private.pem \
      -key-version 0 \
      -cert-file /admin/home.athenz_admin.showcase.cert.pem \
      -signer-cert-file /admin/ca.cert.pem
```

### Retriving tokens

```
docker exec -it athenz-cli \
    zts-roletoken \
        -zts https://athenz-zts-server:8443/zts/v1 \
        -svc-cacert-file /admin/ca.cert.pem \
        -svc-key-file /admin/athenz_admin.private.pem \
        -svc-cert-file /admin/athenz_admin.cert.pem \
        -domain sys.auth \
        -role admin \
        | rev | cut -d';' -f2- | rev \
        | tr ';' '\n'

docker exec -it athenz-cli \
    zts-accesstoken \
        -zts https://athenz-zts-server:8443/zts/v1 \
        -svc-cacert-file /admin/ca.cert.pem \
        -svc-key-file /admin/athenz_admin.private.pem \
        -svc-cert-file /admin/athenz_admin.cert.pem \
        -domain sys.auth \
        -roles admin \
        | jq -r .access_token \
        | jq -Rr 'split(".") | .[0,1] | @base64d' \
        | jq -r .
```

### Retriving public keys

```
docker exec -it athenz-cli /bin/sh -c \
    "athenz-conf \
        -c /admin/ca.cert.pem \
        -svc-key-file /admin/athenz_admin.private.pem \
        -svc-cert-file /admin/athenz_admin.cert.pem \
        -z https://athenz-zms-server:4443/zms/v1 \
        -t https://athenz-zts-server:8443/zts/v1 \
        -o /dev/stdout

docker exec -it \
    -e ATHENZ_DOMAIN="home.athenz_admin" \
    athenz-cli \
    curl \
        -s \
        -H"Content-type: application/json" \
        --cacert admin/ca.cert.pem \
        --key admin/athenz_admin.private.pem \
        --cert admin/athenz_admin.cert.pem \
        "https://athenz-zts-server.athenz:4443/zts/v1/oauth2/keys?rfc=true" \
| tee ./admin/jwks.json
```

### Retriving Policies

https://datatracker.ietf.org/doc/html/draft-smith-oauth-json-web-document-00

```
docker exec -it \
    -e ATHENZ_DOMAIN="home.athenz_admin" \
    athenz-cli \
    curl \
        -H "Content-type: application/json" \
        -sXPOST \
        -d"{\"policyVersions\":{\"\":\"\"}}" \
        --cacert admin/ca.cert.pem \
        --key admin/athenz_admin.private.pem \
        --cert admin/athenz_admin.cert.pem \
        https://athenz-zts-server.athenz:4443/zts/v1/domain/${ATHENZ_DOMAIN}/policy/signed \
| jq -r '[.protected,.payload,.signature] | join(".")' \
| step crypto jws verify --jwks=/var/run/athenz/jwks.json; \
printf "\n%s\n" $?
```


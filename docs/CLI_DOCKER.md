# CLI Instruction for Docker

## Testing with Docker environment

### Prerequisite

- [docker](https://www.docker.com/)
- [jq](https://jqlang.github.io/jq/)
- [step](https://smallstep.com/docs/step-cli/)

### Athenz Domain Management 

```
docker exec -it athenz-cli \
    zms-cli \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        -z https://athenz-zms-server:4443/zms/v1 \
        list-domain
```

```
docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        -d sys.auth \
        show-domain
```

### Retriving identity certificate

```
docker exec -it athenz-cli \
    /bin/sh -c \
        "
        zms-svctoken \
            -domain home.athenz_admin \
            -service showcase \
            -private-key /var/run/athenz/keys/athenz_admin.private.pem \
            -key-version 0 \
        | tr -d '\n' \
        | tee /var/run/athenz/.ntoken \
        "
```

```
docker exec -it athenz-cli /bin/sh -c \
    zts-svccert \
        -zts https://athenz-zts-server:4443/zts/v1 \
        -domain home.athenz_admin \
        -service showcase \
        -provider sys.auth.zts \
        -instance $(hostname) \
        -attestation-data /var/run/athenz/.ntoken \
        -dns-domain zts.athenz.cloud \
        -private-key /var/run/athenz/keys/athenz_admin.private.pem \
        -key-version 0 \
        -cert-file /var/run/athenz/home.athenz_admin.showcase.cert.pem \
        -signer-cert-file /var/run/athenz/certs/ca.cert.pem
```

### Retriving role token

```
docker exec -it athenz-cli \
    zts-roletoken \
        -zts https://athenz-zts-server:8443/zts/v1 \
        -svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
        -svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
        -domain sys.auth \
        -role admin \
    | rev | cut -d';' -f2- | rev \
    | tr ';' '\n'
```

### Retriving public keys

```
docker exec -it athenz-cli \
    athenz-conf \
        -c /var/run/athenz/certs/ca.cert.pem \
        -svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
        -z https://athenz-zms-server:4443/zms/v1 \
        -t https://athenz-zts-server:8443/zts/v1 \
        -o /dev/stdout
```

```
docker exec -it \
    -e ATHENZ_DOMAIN="home.athenz_admin" \
    athenz-cli \
    curl \
        -s \
        -H"Content-type: application/json" \
        --cacert /var/run/athenz/certs/ca.cert.pem \
        --key /var/run/athenz/keys/athenz_admin.private.pem \
        --cert /var/run/athenz/certs/athenz_admin.cert.pem \
        https://athenz-zts-server:8443/zts/v1/oauth2/keys?rfc=true \
    | tee keys/jwks.json
```

### Retriving access token

```
docker exec -it athenz-cli \
    zts-accesstoken \
        -zts https://athenz-zts-server:8443/zts/v1 \
        -svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
        -svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
        -domain sys.auth \
        -roles admin \
    | jq -r .access_token \
    | jq -Rr 'split(".") | .[0,1] | @base64d' \
    | jq -r .
```

```
docker exec -it athenz-cli \
    zts-accesstoken \
        -zts https://athenz-zts-server:8443/zts/v1 \
        -svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
        -svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
        -domain sys.auth \
        -roles admin \
    | jq -r .access_token \
    | step crypto jws verify --jwks=keys/jwks.json \
    && printf "\nValid Access Token\n" || printf "\nInvalid Access Token\n"
```

### Retriving Policies

https://datatracker.ietf.org/doc/html/draft-smith-oauth-json-web-document-00

```
docker exec -it \
    -e ATHENZ_DOMAIN="sys.auth" \
    athenz-cli \
    curl \
        -H"Content-type: application/json" \
        -sXPOST \
        -d"{\"policyVersions\":{\"\":\"\"}}" \
        --cacert /var/run/athenz/certs/ca.cert.pem \
        --key /var/run/athenz/keys/athenz_admin.private.pem \
        --cert /var/run/athenz/certs/athenz_admin.cert.pem \
        https://athenz-zts-server:8443/zts/v1/domain/${ATHENZ_DOMAIN:-sys.auth}/policy/signed \
    | jq -r '[.protected,.payload,.signature] | join(".")' \
    | step crypto jws verify --jwks=keys/jwks.json \
    && printf "\nValid Policy\n" || printf "\nInvalid Policy\n"
```


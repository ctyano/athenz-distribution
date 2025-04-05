# CLI Instruction for Docker

## Testing with Docker environment

### Prerequisite

- [docker](https://www.docker.com/)
- [jq](https://jqlang.github.io/jq/)
- [step](https://smallstep.com/docs/step-cli/)

### Athenz Domain Management 

#### Listing existing domains

```
docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        list-domain
```

#### Showing an existing domain

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

#### Creating an Athenz Top-Level Domain (TLD)

Currently the zms-cli is not working in this usage, so you will need to add it with your own http client(e.g. curl).

```
docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        add-domain \
        athenz
```

```
docker exec -it athenz-cli \
    curl \
        -sv \
        -d"{\"name\":\"athenz\",\"adminUsers\":[\"user.athenz_admin\"]}" \
        -H"Content-Type: application/json" \
        --cacert /var/run/athenz/certs/ca.cert.pem \
        --key /var/run/athenz/keys/athenz_admin.private.pem \
        --cert /var/run/athenz/certs/athenz_admin.cert.pem \
        "https://athenz-zms-server.athenz:4443/zms/v1/domain"
```

#### Creating an Athenz Sub Domain

Currently the zms-cli is not working in this usage, so you will need to add it with your own http client(e.g. curl).

```
docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        add-domain \
        athenz.demo
```

```
docker exec -it athenz-cli \
    curl \
        -sv \
        -d"{\"name\":\"demo\",\"parent\":\"athenz\",\"adminUsers\":[\"user.athenz_admin\"]}" \
        -H"Content-Type: application/json" \
        --cacert /var/run/athenz/certs/ca.cert.pem \
        --key /var/run/athenz/keys/athenz_admin.private.pem \
        --cert /var/run/athenz/certs/athenz_admin.cert.pem \
        "https://athenz-zms-server.athenz:4443/zms/v1/subdomain/athenz"
```

#### Creating an Athenz Personal Domain (a.k.a home domain)

```
docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        add-domain \
        home.athenz_admin
```

### Athenz Service Management 

#### Creating an Athenz Service with a Solution Template

```
docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        -d \
        athenz.demo \
        set-domain-template \
        identity_provisioning \
        instanceprovider="sys.auth.zts" \
        service="example-application"
```

#### Creating an Athenz Service

```
docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        -d \
        athenz.demo \
        add-service \
        example-application
```

### Retriving identity certificate

#### Retriving with an Athenz service token

First, you will need to generate a Athenz service token.

```
docker exec -it athenz-cli \
    /bin/sh -c " \
        zms-svctoken \
            -domain home.athenz_admin \
            -service showcase \
            -private-key /var/run/athenz/keys/athenz_admin.private.pem \
            -key-version 0 \
        | tr -d '\n' \
        | tee /var/run/athenz/.ntoken \
    "
```

Next, you can get an Athenz service X.509 certificate by sending the service token.

```
docker exec -it athenz-cli \
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
        -cert-file /var/run/athenz/certs/home.athenz_admin.showcase.cert.pem \
        -signer-cert-file /var/run/athenz/certs/ca.cert.pem
```

```
docker exec -it athenz-cli \
    /bin/sh -c " \
        cat /var/run/athenz/certs/home.athenz_admin.showcase.cert.pem \
        | step certificate inspect --short --bundle \
    "
```

Alternatively, you can get an Athenz service X.509 certificate by sending an identity document that is issued by Athenz or other compatible identity providers.

#### Retriving with an Athenz identity document

First, you will need to retrieve a Athenz identity document jwt.

```
docker exec -it athenz-cli \
    zts-svccert \
        -get-instance-register-token \
        -zts https://athenz-zts-server:4443/zts/v1 \
        -domain home.athenz_admin \
        -service showcase \
        -provider sys.auth.zts \
        -instance $(hostname) \
        -attestation-data /var/run/athenz/.identitydocument.jwt \
        -dns-domain zts.athenz.cloud \
        -svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem
```

Next, you can get an Athenz service X.509 certificate by sending the identity document.

```
docker exec -it athenz-cli \
    zts-svccert \
        -zts https://athenz-zts-server:4443/zts/v1 \
        -domain home.athenz_admin \
        -service showcase \
        -provider sys.auth.zts \
        -instance $(hostname) \
        -attestation-data /var/run/athenz/.identitydocument.jwt \
        -dns-domain zts.athenz.cloud \
        -private-key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert-file /var/run/athenz/certs/home.athenz_admin.showcase.cert.pem \
        -signer-cert-file /var/run/athenz/certs/ca.cert.pem
```

```
docker exec -it athenz-cli \
    /bin/sh -c " \
        cat /var/run/athenz/certs/home.athenz_admin.showcase.cert.pem \
        | step certificate inspect --short --bundle \
    "
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
docker exec -it athenz-cli \
    -e ATHENZ_DOMAIN="home.athenz_admin" \
    /bin/sh -c " \
        curl \
            -s \
            -H\"Content-type: application/json\" \
            --cacert /var/run/athenz/certs/ca.cert.pem \
            --key /var/run/athenz/keys/athenz_admin.private.pem \
            --cert /var/run/athenz/certs/athenz_admin.cert.pem \
            https://athenz-zts-server:8443/zts/v1/oauth2/keys?rfc=true \
        | tee keys/jwks.json \
    "
```

### Athenz Role Management 

```
docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        -d athenz.demo \
        add-group-role \
        clients
```

### Retriving RBAC token or Role cert

There are two types of RBAC tokens in Athenz.

The legacy Role Tokens, and the RFC 8705 standardized OAuth 2.0 based Access Tokens.

#### Retriving Role Token

```
docker exec -it athenz-cli \
    /bin/sh -c " \
        zts-roletoken \
            -zts https://athenz-zts-server:8443/zts/v1 \
            -svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
            -svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
            -svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
            -domain sys.auth \
            -role admin \
        | rev | cut -d';' -f2- | rev \
        | tr ';' '\n' \
    "
```

#### Retriving Access Token

```
docker exec -it athenz-cli \
    /bin/sh -c " \
        zts-accesstoken \
            -zts https://athenz-zts-server:8443/zts/v1 \
            -svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
            -svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
            -svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
            -domain sys.auth \
            -roles admin \
        | jq -r .access_token \
        | jq -Rr 'split(".") | .[0,1] | @base64d' \
        | jq -r . \
    "
```

```
docker exec -it athenz-cli \
    /bin/sh -c " \
        zts-accesstoken \
            -zts https://athenz-zts-server:8443/zts/v1 \
            -svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
            -svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
            -svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
            -domain sys.auth \
            -roles admin \
        | jq -r .access_token \
        | step crypto jws verify --jwks=keys/jwks.json \
        && printf \"\nValid Access Token\n\" || printf \"\nInvalid Access Token\n\" \
    "
```

#### Retriving Role Cert

```
docker exec -it athenz-cli \
    zts-rolecert \
        -zts https://athenz-zts-server:8443/zts/v1 \
        -svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
        -svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
        -role-domain athenz.demo \
        -role-name clients \
        -dns-domain zts.athenz.cloud \
        -role-key-file /var/run/athenz/keys/athenz_admin.private.pem \
        -role-cert-file /var/run/athenz/certs/athenz.demo:role.clients.cert.pem
```

```
docker exec -it athenz-cli \
    /bin/sh -c " \
        cat /var/run/athenz/certs/athenz.demo:role.clients.cert.pem \
        | step certificate inspect --short --bundle \
    "
```

### Athenz Policy Management 

```
docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /var/run/athenz/certs/ca.cert.pem \
        -key /var/run/athenz/keys/athenz_admin.private.pem \
        -cert /var/run/athenz/certs/athenz_admin.cert.pem \
        -d athenz.demo \
        add-policy \
        clients \
        grant get to clients on /authz*
```

### Retriving and Verifying Json Web Document(JWD) Policies

https://datatracker.ietf.org/doc/html/draft-smith-oauth-json-web-document-00

```
docker exec -it athenz-cli \
    -e ATHENZ_DOMAIN="sys.auth" \
    /bin/sh -c " \
        curl \
            -H\"Content-type: application/json\" \
            -sXPOST \
            -d\"{\"policyVersions\":{\"\":\"\"}}\" \
            --cacert /var/run/athenz/certs/ca.cert.pem \
            --key /var/run/athenz/keys/athenz_admin.private.pem \
            --cert /var/run/athenz/certs/athenz_admin.cert.pem \
            https://athenz-zts-server:8443/zts/v1/domain/${ATHENZ_DOMAIN:-sys.auth}/policy/signed \
        | jq -r '[.protected,.payload,.signature] | join(".")' \
        | step crypto jws verify --jwks=keys/jwks.json \
        && printf \"\nValid Policy\n\" || printf \"\nInvalid Policy\n\" \
    "
```


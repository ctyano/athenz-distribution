# CLI Instruction for Kubernetes

## Testing with Kubernetes environment

### Prerequisite

- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [jq](https://jqlang.github.io/jq/)
- [step](https://smallstep.com/docs/step-cli/)

### Athenz Domain Management 

#### Creating an Athenz Top-Level Domain (TLD)

Currently the zms-cli is not working in this usage, so you will need to add it with your own http client(e.g. curl).

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        add-domain \
        athenz
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -sv \
        -d"{\"name\":\"athenz\",\"adminUsers\":[\"user.athenz_admin\"]}" \
        -H"Content-Type: application/json" \
        --key /var/run/athenz/athenz_admin.private.pem \
        --cert /var/run/athenz/athenz_admin.cert.pem \
        "https://athenz-zms-server.athenz:4443/zms/v1/domain"
```

#### Listing existing domains

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        list-domain
```

#### Showing an existing domain

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d sys.auth \
        show-domain
```

#### Creating an Athenz Sub Domain

Currently the zms-cli is not working in this usage, so you will need to add it with your own http client(e.g. curl).

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        add-domain \
        athenz.demo
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -sv \
        -d"{\"name\":\"demo\",\"adminUsers\":[\"user.athenz_admin\"]}" \
        -H"Content-Type: application/json" \
        --key /var/run/athenz/athenz_admin.private.pem \
        --cert /var/run/athenz/athenz_admin.cert.pem \
        "https://athenz-zms-server.athenz:4443/zms/v1/subdomain/athenz"
```

#### Creating an Athenz Personal Domain (a.k.a home domain)

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        add-domain \
        home.athenz_admin
```

### Retriving identity certificate

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        add-domain \
        home.athenz_admin
```

#### Creating an Athenz Personal Domain (a.k.a home domain)

Currently the zms-cli is not working in this usage, so you will need to add it with your own http client(e.g. curl).

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        add-domain \
        sys.test
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -sv \
        -d"{\"name\":\"demo\",\"parent\":\"athenz\",\"adminUsers\":[\"user.athenz_admin\"]}" \
        -H"Content-Type: application/json" \
        --key /var/run/athenz/athenz_admin.private.pem \
        --cert /var/run/athenz/athenz_admin.cert.pem \
        "https://athenz-zms-server.athenz:4443/zms/v1/domain"
```

### Retriving identity certificate

First, you will need to generate a Athenz service token.

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    /bin/sh -c " \
        zms-svctoken \
            -domain home.athenz_admin \
            -service showcase \
            -private-key /var/run/athenz/athenz_admin.private.pem \
            -key-version 0 \
        | tr -d '\n' \
        | tee /tmp/.ntoken
    "
```

Next, you can get an Athenz service X.509 certificate by sending the service token.

```
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

Alternatively, you can get an Athenz service X.509 certificate by sending an identity document that is issued by Athenz or other compatible identity providers.

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zts-svccert \
        -get-instance-register-token \
        -zts https://athenz-zts-server.athenz:4443/zts/v1 \
        -domain home.athenz_admin \
        -service showcase \
        -provider sys.auth.zts \
        -instance $(hostname) \
        -attestation-data /tmp/.identitydocument.jwt \
        -dns-domain zts.athenz.cloud \
        -svc-key-file /var/run/athenz/athenz_admin.private.pem \
        -svc-cert-file /tmp/home.athenz_admin.showcase.cert.pem
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
```

```
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

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zts-accesstoken \
        -zts https://athenz-zts-server.athenz:4443/zts/v1 \
        -svc-key-file /var/run/athenz/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
        -domain sys.auth \
        -roles admin \
    | jq -r .access_token \
    | step crypto jws verify --jwks=keys/jwks.json \
    && printf "\nValid Access Token\n" || printf "\nInvalid Access Token\n"
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
```

```
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
kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -H "Content-type: application/json" \
        -sXPOST \
        -d"{\"policyVersions\":{\"\":\"\"}}" \
        --key /var/run/athenz/athenz_admin.private.pem \
        --cert /var/run/athenz/athenz_admin.cert.pem \
        "https://athenz-zts-server.athenz:4443/zts/v1/domain/${DOMAIN:-sys.auth}/policy/signed" \
    | jq -r '[.protected,.payload,.signature] | join(".")' \
    | step crypto jws verify --jwks=keys/jwks.json \
    && printf "\nValid Policy\n" || printf "\nInvalid Policy\n"
```


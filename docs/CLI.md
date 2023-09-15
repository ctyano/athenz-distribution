# CLI Instruction

## Testing with Kubernetes environment

### Prerequisite

- kubectl
- jq
- step

### Athenz Domain Management 

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        list-domain

kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d sys.auth \
        add-service zts 0 zts/keys/zts_public.pem

kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -s \
        -H"Content-type: application/json" \
        -H"X-Auth-Request-Preferred-Username: user.athenz_admin" \
        --cacert /etc/ssl/certs/ca.cert.pem \
        https://athenz-zms-server:4443/zms/v1/domain \
    | jq -r .

kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -s \
        -H"Content-type: application/json" \
        -H"X-Auth-Request-Preferred-Username: user.athenz_admin" \
        --cacert /etc/ssl/certs/ca.cert.pem \
        https://athenz-zts-server:4443/zts/v1/domain/sys.auth/service \
    | jq -r .
```

### Retriving tokens and public keys

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    athenz-conf \
        -z https://athenz-zms-server:4443/zms/v1 \
        -t https://athenz-zts-server:4443/zts/v1 \
        -svc-key-file /var/run/athenz/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
        -o /dev/stdout

kubectl -n athenz exec deployment/athenz-cli -it -- \
    zts-roletoken \
        -zts https://athenz-zts-server:4443/zts/v1 \
        -svc-key-file /var/run/athenz/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
        -domain sys.auth \
        -role admin \
        | rev | cut -d';' -f2- | rev \
        | tr ';' '\n'

kubectl -n athenz exec deployment/athenz-cli -it -- \
    zts-accesstoken \
        -zts https://athenz-zts-server:4443/zts/v1 \
        -svc-key-file /var/run/athenz/athenz_admin.private.pem \
        -svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
        -domain sys.auth \
        -roles admin \
        | jq -r .access_token \
        | jq -Rr 'split(".") | .[0,1] | @base64d' \
        | jq -r .
```

### Retriving Policies

https://datatracker.ietf.org/doc/html/draft-smith-oauth-json-web-document-00

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -s \
        -H"Content-type: application/json" \
        --cacert /etc/ssl/certs/ca.cert.pem \
        --key /var/run/athenz/athenz_admin.private.pem \
        --cert /var/run/athenz/athenz_admin.cert.pem \
        "https://athenz-zts-server:4443/zts/v1/oauth2/keys?rfc=true" \
| tee ./jwks.json

echo -n sys.auth \
| kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
        -sXPOST \
        -H "Content-type: application/json" \
        -d"{\"policyVersions\":{\"\":\"\"}}" \
        --cacert /etc/ssl/certs/ca.cert.pem \
        --key /var/run/athenz/athenz_admin.private.pem \
        --cert /var/run/athenz/athenz_admin.cert.pem \
        "https://athenz-zts-server:4443/zts/v1/domain/$(cat /dev/stdin)/policy/signed" \
| jq -r '[.protected,.payload,.signature] | join(".")' \
| step crypto jws verify --jwks=jwks.json \
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
        add-service zts 0 zts/keys/zts_public.pem

docker exec -it athenz-cli \
    zms-cli \
        -z https://athenz-zms-server:4443/zms/v1 \
        -c /admin/ca.cert.pem \
        -key /admin/athenz_admin.private.pem \
        -cert /admin/athenz_admin.cert.pem \
        -d sys.auth \
        show-domain
```

### Retriving tokens and public keys

```
docker exec -it athenz-cli /bin/sh -c \
    "athenz-conf \
        -c /admin/ca.cert.pem \
        -svc-key-file /admin/athenz_admin.private.pem \
        -svc-cert-file /admin/athenz_admin.cert.pem \
        -z https://athenz-zms-server:4443/zms/v1 \
        -t https://athenz-zts-server:8443/zts/v1 \
        -o /admin/athenz.conf \
        && cat /admin/athenz.conf" \
    | tee docker/zts/conf/athenz.conf

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

### Retriving Policies

https://datatracker.ietf.org/doc/html/draft-smith-oauth-json-web-document-00

```
docker exec -it \
    -e ATHENZ_DOMAIN="home.athenz_admin" \
    athenz-cli \
    curl \
        -s \
        -H"Content-type: application/json" \
        --cacert admin/ca.cert.pem \
        --key admin/athenz_admin.private.pem \
        --cert admin/athenz_admin.cert.pem \
        https://athenz-zts-server.athenz:4443/zts/v1/oauth2/keys?rfc=true > ./admin/jwks.json

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


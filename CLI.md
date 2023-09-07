# CLI Instruction

## Testing with athenz-cli

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


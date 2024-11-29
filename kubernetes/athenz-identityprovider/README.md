# athenz-identityprovider

## Configuration

Files below must be configured for each use cases accordingly

1. [athenz-identityprovider.env](kustomize/athenz-identityprovider.env)
1. [athenz-sia.env](kustomize/athenz-sia/athenz-sia.env)
1. [config.yaml](kustomize/athenz-identityprovider/policy/config.yaml)
1. [secret.yaml](#creating-tls-server-certificate-secret)

## Deployment

```
kubectl -n athenz apply -k kustomize
```

## Registering Identity Provider Service to Athenz as Athenz Admin

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    curl \
    -sv \
    -d"{\"name\":\"$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g')\",\"adminUsers\":[\"user.athenz_admin\"]}" \
    -H"Content-Type: application/json" \
    --key /var/run/athenz/athenz_admin.private.pem \
    --cert /var/run/athenz/athenz_admin.cert.pem \
    "https://athenz-zms-server.athenz:4443/zms/v1/domain"
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d \
        sys.auth \
        set-domain-template \
        instance_provider \
        provider="$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)/\1/g')" \
        dnssuffix="$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^DNS_SUFFIX | sed -e 's/DNS_SUFFIX=\(.*\)/\1/g')"
```

## Setting up Instance Provider Service

```
openssl genrsa -out - 4096 | openssl pkey -traditional -out private.key.pem
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d \
        $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        add-service \
        $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\2/g') \
        0 \
        $(openssl rsa -in private.key.pem -pubout | base64 | tr -d '\r\n' | tr '\+\=\/' '\.\-\_')
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d \
        $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        set-service-endpoint \
        $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\2/g') \
        https://$(cat kustomize/athenz-identityprovider.env | grep -E ^IDENTITYPROVIDER_ENDPOINT_HOST | sed -e 's/IDENTITYPROVIDER_ENDPOINT_HOST=\(.*\)/\1/g')/v0/data/identityprovider
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d \
        $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        set-domain-template \
        identity_provisioning \
        instanceprovider="sys.auth.zts" \
        service="$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\2/g')"
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d \
        $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        set-domain-template \
        identity_provisioning \
        instanceprovider="$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)/\1/g')" \
        service="$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\2/g')"
```

## Preparing TLS Server Certificate Secret

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    sh \
    -c \
    "echo $(cat private.key.pem | tr '\n' '%') | tr '%' '\n' > /tmp/private.key.pem"
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    sh \
    -c \
    " \
    zms-svctoken \
        -domain $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        -service $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\2/g') \
        -private-key /tmp/private.key.pem \
        -key-version 0 \
    | tr -d '\n' \
    | tee /tmp/.ntoken \
    "
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zts-svccert \
        -zts $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^ENDPOINT | sed -e 's/ENDPOINT=\(.*\)/\1/g') \
        -domain $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        -service $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\2/g') \
        -provider sys.auth.zts \
        -instance $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)/\1/g') \
        -dns-domain zts.athenz.cloud \
        -key-version 0 \
        -private-key /tmp/private.key.pem \
        -attestation-data /tmp/.ntoken \
        -cert-file /tmp/$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)/\1/g').cert.pem \
        -signer-cert-file /tmp/ca.cert.pem
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    cat /tmp/$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)/\1/g').cert.pem \
    > service.cert.pem
```

```
kubectl \
    -n \
    $(cat kustomize/athenz-identityprovider.env | grep -E ^IDENTITYPROVIDER_NAMESPACE | sed -e 's/IDENTITYPROVIDER_NAMESPACE=\(.*\)/\1/g') \
    create \
    secret \
    tls \
    $(cat kustomize/athenz-sia/athenz-sia.env | grep CERT_SECRET | sed -e 's/CERT_SECRET=\(.*\)/\1/g') \
    --key \
    private.key.pem \
    --cert \
    service.cert.pem \
    --dry-run=client \
    -o \
    yaml \
| tee kustomize/secret.yaml
```

## Debugging

```
kubectl -n athenz exec deployment/athenz-cli -it -- \ zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        add-group-role \
        envoyclients \
        $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)/\1/g')
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        add-policy \
        envoyclients \
        grant get to envoyclients on /server*
```

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        show-domain
```

```
kubectl -n athenz exec -it deployment/identityprovider-deployment -c kubectl -- /bin/sh -c "curl -sv http://localhost:8080/helloworld"
```

```
kubectl -n athenz exec -it deployment/identityprovider-deployment -c kubectl -- /bin/sh -c "curl -sv http://localhost:8080/client | jq -r .request"
```

```
kubectl -n athenz exec -it deployment/identityprovider-deployment -c kubectl -- /bin/sh -c "curl -sv http://localhost:8080/client2server | jq -r .request"
```

```
kubectl -n athenz exec -it deployment/identityprovider-deployment -c kubectl -- /bin/sh -c "curl -sv http://localhost:8080/client2echoservermtls | jq -r .request"
```

```
kubectl -n athenz exec -it deployment/identityprovider-deployment -c kubectl -- /bin/sh -c "curl -sv --cacert /var/run/athenz/ca.crt --resolve identityprovider.athenz.zts.athenz.cloud:443:127.0.0.1 https://identityprovider.athenz.zts.athenz.cloud/health"
```

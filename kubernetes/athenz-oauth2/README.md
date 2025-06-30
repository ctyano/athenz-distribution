# athenz-oauth2

## Configuration

Files below must be configured for each use cases accordingly

1. [athenz-oauth2.env](kustomize/athenz-oauth2/athenz-oauth2.env)
1. [athenz-sia.env](kustomize/athenz-sia/athenz-sia.env)
1. [config.yaml](kustomize/athenz-oauth2/policy/config.yaml)

## Deployment

```
kubectl -n athenz apply -k kustomize
```

## Registering Authorizer Service to Athenz

```
make register-athenz-oauth2
```

confirm registration with:

```
kubectl -n athenz exec deployment/athenz-cli -it -- \
    zms-cli \
        -z https://athenz-zms-server.athenz:4443/zms/v1 \
        -key /var/run/athenz/athenz_admin.private.pem \
        -cert /var/run/athenz/athenz_admin.cert.pem \
        -d $(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
        show-domain
```

## Debugging

```
~/go/bin/athenz-user-cert -csr http://localhost:10000/v3/sig/x509-cert/keys/x509-key -cn athenz_admin | step certificate inspect --bundle
```

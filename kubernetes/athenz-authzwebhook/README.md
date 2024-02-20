# athenz-authzwebhook

## Configuration

Files below must be configured for each use cases accordingly

1. [athenz-sia.env](kustomize/athenz-sia/athenz-sia.env)
1. [config.yaml](kustomize/envoy/config.yaml)

## Deployment

```
kubectl -n athenz apply -k kustomize
```

## Registering Authzenvoy Service to Athenz

```
make register-athenz-authzwebhook
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
kubectl -n athenz exec -it deployment/authzwebhook-deployment -c athenz-cli -- /bin/sh -c "curl -sv --resolve authzwebhook.athenz.svc.cluster.local:443:127.0.0.1 https://authzwebhook.athenz.svc.cluster.local/echoserver | jq -r .request"
```

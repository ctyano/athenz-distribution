# athenz-k8sclient

## Configuration

Files below must be configured for each use cases accordingly

1. [athenz-sia.env](kustomize/athenz-sia/athenz-sia.env)

## Deployment

```
kubectl -n athenz apply -k kustomize
```

## Registering Client Service to Athenz

```
make register-athenz-k8sclient
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
kubectl -n athenz exec -it deployment/k8sclient-deployment -c athenz-cli -- /bin/sh -c "curl -sv http://localhost:8080/echoserver | jq -r .request"
```

```
kubectl -n athenz exec -it deployment/k8sclient-deployment -c athenz-cli -- /bin/sh -c "curl -sv http://localhost:8080/k8sclient2echoserver | jq -r .request"
```

```
kubectl -n athenz exec -it deployment/k8sclient-deployment -c athenz-cli -- /bin/sh -c "curl -sv http://localhost:8080/k8sclient2server | jq -r .request"
```

```
kubectl -n athenz exec -it deployment/k8sclient-deployment -c athenz-cli -- /bin/sh -c "curl -sv http://localhost:8080/k8sclient2echoservermtls | jq -r .request"
```

```
kubectl -n athenz exec -it deployment/k8sclient-deployment -c athenz-cli -- /bin/sh -c "curl -sv --resolve k8sclient.athenz.svc.cluster.local:443:127.0.0.1 https://k8sclient.athenz.svc.cluster.local/echoserver | jq -r .request"
```

# athenz-client

## Configuration

Files below must be configured for each use cases accordingly

1. [athenz-client.env](kustomize/athenz-client/athenz-client.env)
1. [athenz-sia.env](kustomize/athenz-sia/athenz-sia.env)
1. [config.yaml](kustomize/athenz-client/policy/config.yaml)

## Deployment

```
kubectl -n athenz apply -k kustomize
```

## Registering Client Service to Athenz

```
make register-athenz-client
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
kubectl -n athenz exec -it deployment/client-deployment -c kubectl -- /bin/sh -c "curl -s http://localhost:8080/client | jq -r ."
```

```
kubectl -n athenz exec -it deployment/client-deployment -c kubectl -- /bin/sh -c "curl -sv http://localhost:8080/client2server"
```

```
kubectl -n athenz exec -it deployment/client-deployment -c kubectl -- /bin/sh -c "curl -sv http://localhost:8080/helloworld"
```

```
kubectl -n athenz exec -it deployment/client-deployment -c kubectl -- /bin/sh -c "curl -s http://localhost:8080/client2echoservermtls" | jq -r .
```

```
kubectl -n athenz exec -it deployment/client-deployment -c kubectl -- /bin/sh -c "curl -s --cacert /var/run/athenz/ca.crt --resolve client.athenz.zts.athenz.cloud:4443:127.0.0.1 https://client.athenz.zts.athenz.cloud:4443/echoserver" | jq -r .
```

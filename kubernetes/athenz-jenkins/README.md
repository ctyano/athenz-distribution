# athenz-jenkins

## Configuration

Files below must be configured for each use cases accordingly

1. [values.yaml](kustomize/helm/values.yaml)

## Deployment

```
kustomize build --enable-helm ./kustomize | kubectl apply -f -
```

## Registering Authorizer Service to Athenz

```
make register-athenz-jenkins
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

You may access Jenkins UI at http://localhost:8080 by forwarding requests.

```
kubectl -n jenkins-system port-forward service/jenkins 8080:8080
```

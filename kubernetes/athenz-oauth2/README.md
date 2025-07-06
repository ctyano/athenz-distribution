# athenz-oauth2

## Configuration

Files below must be configured for each use cases accordingly

1. [config.yaml](kustomize/athenz-oauth2/dex/config.yaml)

## Deployment

```
kubectl -n athenz apply -k kustomize
```

confirm deployment with:

```
kubectl -n athenz exec deployment/oauth2-deployment -it -c dex -- nc -vz 127.0.0.1 5556
```


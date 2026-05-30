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

## Password Grant

Showcase purposes only:

```bash
kubectl -n athenz port-forward deployment/oauth2-deployment 5556:5556
```

```bash
curl -L -X POST 'http://127.0.0.1:5556/dex/token' \
  -u 'athenz-user-cert:athenz-user-cert' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=password' \
  --data-urlencode 'scope=openid profile email' \
  --data-urlencode 'username=athenz_admin@athenz.io' \
  --data-urlencode 'password=password'
```

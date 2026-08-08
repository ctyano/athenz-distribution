# athenz-oauth2

## Configuration

Files below must be configured for each use cases accordingly

1. [config.yaml](kustomize/athenz-user-cert/config.yaml) - athenzusercert CLI configuration (keycloak OIDC + ZTS external member certificate endpoint)
2. [envoy/config.yaml](kustomize/envoy/config.yaml) - envoy proxies to crypki, and to keycloak (HTTP on 18080 for the CLI/browser, HTTPS on 10001 for the ZTS backend)

## Deployment

```
kubectl -n athenz apply -k kustomize
```

confirm deployment with:

```
kubectl -n athenz exec deployment/oauth2-deployment -it -c athenz-user-cert -- nc -vz 127.0.0.1 18080
```

## Password Grant

Showcase purposes only:

```bash
kubectl -n keycloak port-forward service/keycloakx-http 18080:80
```

```bash
curl -L -X POST 'http://127.0.0.1:18080/realms/athenz/protocol/openid-connect/token' \
  -d 'grant_type=password' \
  -d 'client_id=athenz-user-cert' \
  -d 'client_secret=athenz-user-cert' \
  -d 'scope=openid profile email' \
  -d 'username=athenz_admin@athenz.io' \
  -d 'password=password'
```

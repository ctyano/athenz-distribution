# keycloak

## kustomization

```
kustomize build --enable-helm ./kustomize | kubectl -n keycloak apply -f -
```

## accessing keycloak web ui

```
kubectl -n keycloak port-forward service/keycloakx-http 8080:80
```

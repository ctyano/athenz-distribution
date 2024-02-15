# Showcases for Kubernetes

## Prerequisite

- A Kubernetes Cluster
- kubectl

## Full setup on a Kubernetes cluster ⎈

```
make clean-kubernetes-athenz load-kubernetes-images deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads
```

You may access Athenz UI at http://localhost:3000 by forwarding requests.

```
kubectl -n athenz port-forward deployment/athenz-ui 3000:3000
```

## How to try them out

To try the authorization checks in various showcases:

```
make test-kubernetes-athenz-showcases
```


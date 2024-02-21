# Showcases for Kubernetes

## Prerequisite

- A Kubernetes Cluster
- kubectl

Other required dependencies will be automatically installed.

## Full setup on a Kubernetes cluster ⎈

```
make clean-kubernetes-athenz load-docker-images deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads
```

- `clean-kubernetes-athenz` cleans up the keys and certs and all Kubernetes resources with `athenz` namespace.
- `load-docker-images` pulls container images from remote registry.
- `deploy-kubernetes-athenz` deploys `athenz-db`, `athenz-zms-server`, `athenz-zts-server`, `athenz-cli`, and `athenz-cli`.
- `deploy-kubernetes-athenz-identityprovider` deploys copper-argos identity provider.
- `deploy-kubernetes-athenz-workloads` deploys miscellaneous workload applications for authentication/authorization showcases.

You may access Athenz UI at http://localhost:3000 by forwarding requests.

```
kubectl -n athenz port-forward deployment/athenz-ui 3000:3000
```

## How to try them out

To try the authorization checks in various showcases:

```
make test-kubernetes-athenz-showcases
```

## How to try load testing

To deploy applications to try load testing:

```
make deploy-kubernetes-athenz-loadtest
```

To execute load testing:

```
make test-kubernetes-athenz-loadtest
```


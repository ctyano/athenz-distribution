# Showcases for Kubernetes

## Prerequisite

- A Kubernetes Cluster
- kubectl

Other required dependencies will be automatically installed.

## Full setup on a Kubernetes cluster ⎈

```
make clean-kubernetes-athenz load-docker-images load-kubernetes-images deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads
```

### Each steps in Makefile

- `clean-kubernetes-athenz` cleans up the keys and certs and all Kubernetes resources within `athenz` namespace.
- `load-docker-images` pulls container images from remote registry.
- `load-kubernetes-images` loads container images to kind cluster.
- `deploy-kubernetes-athenz` prepares the keys and the certs locally and deploys `athenz-db`, `athenz-zms-server`, `athenz-zts-server`, `athenz-cli`, and `athenz-ui`.
- `deploy-kubernetes-athenz-identityprovider` registers required informations to athenz and deploys copper argos identity provider.
- `deploy-kubernetes-athenz-workloads` registers required informations to athenz for the each showcase and deploys miscellaneous workload applications for authentication/authorization showcases.

## After completing the setup

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

The loadtest results will be printed to html files in the current directory.


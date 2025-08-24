# Showcases for Kubernetes

## Prerequisite

- A running Kubernetes cluster
- kubectl

Other required dependencies will be automatically installed.

## Full setup on a Kubernetes cluster ⎈

```
make clean-kubernetes-athenz load-docker-images load-kubernetes-images deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads
```

Running Athenz together with [crypki](https://github.com/theparanoids/crypki), every certificates will be signed by [softhsm](https://github.com/ctyano/crypki-softhsm).

To use crypki:

```
make clean-kubernetes-athenz load-docker-images load-kubernetes-images deploy-kubernetes-crypki-softhsm use-kubernetes-crypki-softhsm deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads
```

### Each steps in Makefile

- `clean-kubernetes-athenz` cleans up the keys and certs and all Kubernetes resources within `athenz` namespace.
- `load-docker-images` pulls container images from remote registry.
- `load-kubernetes-images` loads container images to kind cluster.
- `deploy-kubernetes-crypki-softhsm` prepares the keys and the certs locally and deploys `crypki-softhsm` and then renews the certs issued with crypki-softhsm.
- `use-kubernetes-crypki-softhsm` prepares the keys and the certs issued with crypki and then overwrites the certs locally generated.
- `deploy-kubernetes-athenz` prepares the keys and the certs locally (if they do not exist) and deploys `athenz-db`, `athenz-zms-server`, `athenz-zts-server`, `athenz-cli`, and `athenz-ui`.
- `deploy-kubernetes-athenz-identityprovider` registers required informations to athenz and deploys copper argos identity provider.
- `deploy-kubernetes-athenz-workloads` registers required informations to athenz for the each showcase and deploys miscellaneous workload applications for authentication/authorization showcases.

## After completing the setup

You may access Athenz UI at http://localhost:3000 by forwarding requests.

```
kubectl -n athenz port-forward deployment/athenz-ui 3000:3000
```

## How to try them out

After deploying workload components, you can run some test to see how Athenz authorization processes work.

To try the authorization checks in various showcases:

```
make test-kubernetes-athenz-showcases
```

## How to try load testing

This showcase includes some senarios to benchmark the performance of Athenz authorization process.

To deploy applications to try load testing:

```
make deploy-kubernetes-athenz-loadtest
```

To execute load testing:

```
make test-kubernetes-athenz-loadtest
```

The loadtest results will be printed to html files in the current directory.


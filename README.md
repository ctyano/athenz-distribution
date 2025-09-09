# athenz-distribution

This is an unofficial repository to provide tools, packages and instructions for [Athenz](https://www.athenz.io).

This repository is currently privately owned and maintained by [ctyano](https://github.com/ctyano).

Stars ⭐️ and Pull Requests ❤️  are always welcome.

To learn more about this repository, you may refer to [the documentation of this repository](docs).

## Minimum setup on a Kubernetes cluster ⎈

⚠️  Prerequisite: A [Kubernetes](https://kubernetes.io/) Cluster must be set up before continuing to further steps.

```
make clean-kubernetes-athenz deploy-kubernetes-athenz
```

You can access Athenz UI at http://localhost:3000 by forwarding requests.

```
kubectl -n athenz port-forward deployment/athenz-ui 3000:3000
```

To see how Athenz authorization scenarios work, check out the [Kubernetes Showcase](docs/SHOWCASES_KUBERNETES.md) to run the entire ecosystem.

## Minimum setup on Docker 🐳

⚠️  Prerequisite: [Docker compose](https://docs.docker.com/compose/) must be set up before continuing to further steps.

```
make clean-docker-athenz deploy-docker-athenz
```

You can access Athenz UI at http://localhost:3000 by forwarding requests.

```
docker compose -f docker/docker-compose.yaml start ghostunnel
```


# athenz-distribution

This is an unofficial repository to provide tools, packages and instructions for [Athenz](https://www.athenz.io).

This repository is currently privately owned and maintained by [ctyano](https://github.com/ctyano).

Pull requests are always welcome. ❤️❤️

## Minimum setup on a Kubernetes cluster ⎈

⚠️  Prerequisite: A Kubernetes Cluster must be set up before continuing to further steps.

```
make clean-kubernetes-athenz deploy-kubernetes-athenz
```

You may access Athenz UI at http://localhost:3000 by forwarding requests.

```
kubectl -n athenz port-forward deployment/athenz-ui 3000:3000
```

## Minimum setup on Docker 🐳

⚠️  Prerequisite: Docker compose must be set up before continuing to further steps.

```
make clean-docker-athenz deploy-docker-athenz
```

You may access Athenz UI at http://localhost:3000 by forwarding requests.

```
docker compose -f docker/docker-compose.yaml start ghostunnel
```

## Miscellaneous documents

- [How to generate keys and certificates](docs/CERTIFICATES.md)
- [CLI instruction](docs/CLI.md)
- [List of Athenz package distribution](docs/DISTRIBUTIONS.md)
- [How to generate keys and retrieve certificates (**Identity Provisioning**)](docs/IDENTITYPROVISIONING.md)
- [Envoy Ambassador Instruction for Kubernetes](docs/ENVOY.md)
- [Showcases for Kubernetes](docs/SHOWCASES_KUBERNETES.md)


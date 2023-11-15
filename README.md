# athenz-distribution

This is an unofficial repository to provide tools, packages and instructions for [Athenz](https://www.athenz.io).

It is currently owned and maintained by [ctyano](https://github.com/ctyano).

## Minimum Setup Instruction on a Kubernetes Cluster ⎈

⚠️  Prerequisite: A Kubernetes Cluster must be set up before continuing to further steps.

```
make clean-k8s-athenz deploy-k8s-athenz
```

You may access Athenz UI by forwarding requests: http://localhost:3000

```
kubectl -n athenz port-forward deployment/athenz-ui 3000:3000
```

## Minimum Setup Instruction on Docker Compose 🐳

⚠️  Prerequisite: Docker compose must be set up before continuing to further steps.

```
make clean-docker-athenz deploy-docker-athenz
```

You may access Athenz UI by forwarding requests: http://localhost:3000

```
make -f Makefile.docker start-ghostunnel
```

## Documentation

- [Credential Preparation](docs/CREDS.md)
- [CLI instruction](docs/CLI.md)
- [Distribution](docs/DIST.md)

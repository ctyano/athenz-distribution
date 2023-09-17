# athenz-distribution

This is an unofficial repository to provide tools, packages and instructions for [Athenz](https://www.athenz.io).

It is currently owned and maintained by [ctyano](https://github.com/ctyano).

## Minimum Setup Instruction on a Kubernetes Cluster ⎈

⚠️  Prerequisite: A Kubernetes Cluster must be set up before continuing to further steps.

```
make clean-athenz
```

```
make generate-certificates copy-to-kustomization
```

```
make setup-athenz
```

or

```
make deploy-athenz
```

## Documentation

- [Credential Preparation](docs/CREDS.md)
- [CLI instruction](docs/CLI.md)
- [Distribution](docs/DIST.md)


# Athenz Kubernetes showcase Helm chart

This chart installs the Kubernetes setups described in [`SHOWCASES_KUBERNETES.md`](../../docs/SHOWCASES_KUBERNETES.md) and [`SHOWCASES_USERAUTH_KUBERNETES.md`](../../docs/SHOWCASES_USERAUTH_KUBERNETES.md) with Helm. It bundles the Kustomize resources and configuration in the chart, and uses Helm hook Jobs to create certificates, register Athenz resources, and create the RustFS bucket. No long-running operator is required.

Install Helm releases in the `default` namespace so their release records remain outside the `athenz`, `crypki`, and `keycloak` namespaces created by the chart. Each phase uses `--wait` and proceeds after the previous phase's Pods or hook Jobs finish. A cluster and `helm` are required. Creating a KinD cluster and loading local images are outside the scope of this chart.

## Installation

Run the following commands from the repository root. Add the same `-f my-values.yaml` to every command to share registry and storage settings across phases.

### Basic setup

```sh
helm upgrade --install showcase-pki charts/athenz-showcase -n default --set phase=pki --wait --timeout 15m
helm upgrade --install showcase-core charts/athenz-showcase -n default --set phase=core --wait --timeout 15m
helm upgrade --install showcase-identityprovider charts/athenz-showcase -n default --set phase=identityprovider --wait --timeout 15m
helm upgrade --install showcase-workloads charts/athenz-showcase -n default --set phase=workloads --wait --timeout 15m
```

### Crypki and user authentication

For a new installation, install Crypki before Athenz. The `crypki` phase's hook Job waits for Crypki to become ready and then re-signs the Athenz certificates.

```sh
helm upgrade --install showcase-pki charts/athenz-showcase -n default --set phase=pki --wait --timeout 15m
helm upgrade --install showcase-crypki charts/athenz-showcase -n default --set phase=crypki --wait --timeout 15m
helm upgrade --install showcase-core charts/athenz-showcase -n default --set phase=core --set zts.certSigner=crypki --wait --timeout 15m
helm upgrade --install showcase-oauth2 charts/athenz-showcase -n default --set phase=oauth2 --wait --timeout 15m
```

For the full setup, also install `showcase-identityprovider` and `showcase-workloads` from the basic setup after `showcase-core`. The `oauth2` phase installs Dex, Envoy, Keycloak, and a Postgres sidecar, then registers Keycloak's external users in Athenz. The original showcase realm is bundled with Keycloak.

### ZMS Domain Syncer

```sh
helm upgrade --install showcase-pki charts/athenz-showcase -n default --set phase=pki --wait --timeout 15m
helm upgrade --install showcase-core charts/athenz-showcase -n default --set phase=core --wait --timeout 15m
helm upgrade --install showcase-rustfs charts/athenz-showcase -n default --set phase=rustfs --wait --timeout 15m
helm upgrade --install showcase-syncer charts/athenz-showcase -n default --set phase=syncer --wait --timeout 15m
helm upgrade showcase-core charts/athenz-showcase -n default --reuse-values --set zts.changeLogStore=s3 --wait --timeout 15m
```

The `rustfs` phase adds a virtual hosted-style S3 rewrite rule to CoreDNS and creates a bucket in RustFS. The `syncer` phase creates a PVC and CronJob, then runs an initial sync Job using the same Pod definition. After the initial sync succeeds, the final `helm upgrade` switches ZTS to the S3 change log store. Without `syncer`, ZTS continues to fetch data directly from ZMS.

### Vault certificate signing

```sh
helm upgrade --install showcase-pki charts/athenz-showcase -n default --set phase=pki --wait --timeout 15m
helm upgrade --install showcase-vault charts/athenz-showcase -n default --set phase=vault --wait --timeout 15m
helm upgrade --install showcase-core charts/athenz-showcase -n default --set phase=core --set zts.certSigner=vault --wait --timeout 15m
helm upgrade --install showcase-identityprovider charts/athenz-showcase -n default --set phase=identityprovider --wait --timeout 15m
helm upgrade --install showcase-workloads charts/athenz-showcase -n default --set phase=workloads --wait --timeout 15m
```

After Vault becomes ready, the `vault` phase stores AppRole credentials in a Secret and re-signs Athenz certificates with Vault PKI. You can also install the `oauth2` phase after `core` if needed. This setup uses the same development Vault as the existing Vault showcase.

## Phases and execution order

| `phase` | Corresponding Make target | Work completed by the phase |
| --- | --- | --- |
| `pki` | Certificate generation and the initial state after `clean-kubernetes-athenz` | Create CA, key, and certificate Secrets; derive public keys |
| `crypki` | `deploy-kubernetes-crypki-softhsm` / `use-kubernetes-crypki-softhsm` | Wait for the Crypki Deployment; re-sign certificates |
| `vault` | `deploy-kubernetes-vault` / `use-kubernetes-vault` | Prepare the Vault Deployment and AppRole; re-sign certificates |
| `core` | `deploy-kubernetes-athenz` | Prepare DB, ZMS, ZTS, CLI, and UI |
| `identityprovider` | `deploy-kubernetes-athenz-identityprovider` | Register Athenz resources and create the attestation Secret before installation |
| `workloads` | `deploy-kubernetes-athenz-workloads` | Register Athenz services, roles, and policies before installation |
| `oauth2` | `deploy-kubernetes-athenz-oauth2` | Register external Keycloak users before installation |
| `rustfs` | `deploy-kubernetes-rustfs` | Update CoreDNS and create a bucket |
| `syncer` | `deploy-kubernetes-athenz-zms-syncer` | Complete the initial sync Job |

`use-kubernetes-athenz-zms-syncer` corresponds to upgrading the `core` release with `zts.changeLogStore=s3`. The ZTS configuration in `use-kubernetes-crypki-softhsm` corresponds to `zts.certSigner=crypki`.

## Main values

```yaml
registries:
  internal: registry.example/athenz/
  external: registry.example/showcase/
  dockerio: mirror.example/dockerhub
  quayio: mirror.example/quay
athenzImageTag: v1.2.3
images:
  authorization-proxy: docker.io/tatyano/authorization-proxy:latest # arm64 example
rustfs:
  bucket: my-zms-domains
  accessKey: change-me
  secretKey: change-me
  patchCoreDNS: true
syncer:
  schedule: "*/5 * * * *"
  storageSize: 1Gi
  storageClassName: standard
keycloak:
  adminPassword: change-me
  dbPassword: change-me
vault:
  rootToken: change-me
```

`registries.internal` / `external` correspond to the Make variables `DOCKER_REGISTRY` / `DOCKER_REGISTRY_EXTERNAL`; `registries.dockerio` / `quayio` correspond to `DOCKERIO_REGISTRY` / `QUAYIO_REGISTRY`; and `athenzImageTag` corresponds to `ATHENZ_IMAGE_TAG`. Use `images.<basename>` to set a complete image reference for an individual image. You can also change `keycloak.image`, `keycloak.postgresImage`, `rustfs.bucketImage`, `pki.publicKeyImage`, and `hooks.apiImage`. Replace `keycloak.realmJSON` with `--set-file keycloak.realmJSON=path/to/realm.json`.

Set the Vault startup token with `vault.rootToken`. To change the Vault bootstrap or Envoy configuration, use `--set-file vault.bootstrapScript=...` and `--set-file vault.envoyConfig=...`.

To use an existing `rustfs-credentials` Secret, set `rustfs.createCredentialsSecret=false`.

Override fields in resources derived from Kustomize with `overrides.<phase>.<Kind>.<name>`. A list value replaces the entire list. For example:

```yaml
overrides:
  core:
    Deployment:
      athenz-ui:
        spec:
          replicas: 2
```

Use `overrides` to adjust individual settings in ConfigMaps or resource requests. To change a container image, use `images.<basename>` because an override would replace the entire container list.

To install into existing namespaces, set `namespaces.create=false` in every phase. To use existing Secrets, set `pki.existing=true` and prepare the Secrets and public keys named in `pki.yaml` beforehand. When using `crypki`, `showcase-pki` and `crypki-client` are also required.

## Uninstallation

Uninstall the releases in reverse order. The `showcase-rustfs` pre-delete hook removes the CoreDNS rule it added. Uninstalling `showcase-pki` last also deletes the `athenz` and `crypki` namespaces created by this chart.

```sh
helm uninstall showcase-syncer showcase-rustfs showcase-oauth2 showcase-workloads showcase-identityprovider showcase-core showcase-crypki showcase-vault -n default
helm uninstall showcase-pki -n default
```

Omit release names that do not exist. Uninstalling `showcase-vault` also deletes the Vault namespace. With `namespaces.create=false`, existing namespaces remain.

## CI tests

[test-kubernetes-helm.yaml](../../.github/workflows/test-kubernetes-helm.yaml) installs the `basic`, `crypki`, `syncer`, `userauth`, and `vault` scenarios separately on KinD and runs the existing Kubernetes functional tests. [test-kind.sh](scripts/test-kind.sh) contains the Helm commands that install and switch phases. Set `athenz_image_tag` in `workflow_dispatch` to skip the local Athenz build.

This chart's Secrets are stored in Kubernetes and in Helm release history. The default Keycloak password and RustFS credentials are the same test values as in the original showcase; change them through values on shared clusters. The `rustfs` CoreDNS change requires access to the ConfigMap and Deployment in `kube-system`. The `syncer` PVC requires a StorageClass that supports dynamic provisioning.

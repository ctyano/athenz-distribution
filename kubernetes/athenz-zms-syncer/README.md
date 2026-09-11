# Athenz ZMS Domain Syncer

This showcase deploys the OSS [ZMS AWS Domain Syncer](https://github.com/AthenZ/athenz/tree/master/syncers/zms_aws_domain_syncer) (`zms_aws_domain_syncer` / `CloudZmsSyncer`) as a Kubernetes `CronJob`.

## Architecture

```
athenz-zms-server  <--mTLS(read signed domains)--  athenz-zms-syncer (CronJob, one run per schedule tick)
                                                            |
                                                            v  (S3 PutObject)
                                                        rustfs (see ../rustfs)
                                                            ^
                                                            |  (S3 GetObject; ZTS never talks to ZMS)
athenz-zts-server (S3ChangeLogStoreFactory, opt-in)  -------
```

Each run reads the full domain list from ZMS over mTLS (using a dedicated `sys.auth.zms-syncer` service identity, registered by the `zms-cli` initContainer) and reconciles it into the [RustFS](../rustfs) bucket `zms-domains`.

## This is opt-in

Deploying this showcase (`make deploy-kubernetes-athenz-zms-syncer`) only starts the Syncer writing to RustFS — it does **not** change how ZTS reads domain data. ZTS keeps pulling directly from ZMS as usual until `make use-kubernetes-athenz-zms-syncer` is explicitly run, which switches `athenz-zts-server`'s `S3ChangeLogStoreFactory` on to read from RustFS instead.

## Usage

See [docs/SHOWCASES_KUBERNETES.md](../../docs/SHOWCASES_KUBERNETES.md) for the full setup flow. In short:

```sh
make deploy-kubernetes-rustfs
make deploy-kubernetes-athenz-zms-syncer test-kubernetes-athenz-zms-syncer
make use-kubernetes-athenz-zms-syncer
```

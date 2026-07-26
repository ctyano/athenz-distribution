# RustFS

This deploys [RustFS](https://rustfs.com/), an S3-compatible object storage server, as the backing store for the [ZMS Domain Syncer showcase](../athenz-zms-syncer).

A `Job` (`rustfs-create-bucket`) pre-creates the `zms-domains` bucket right after RustFS starts, using the [AWS CLI](https://github.com/aws/aws-cli) (`aws s3api create-bucket --endpoint-url ...`) — a generic S3 client also usable against RustFS's S3-compatible API. This is required because the ZMS Domain Syncer fails on startup if the target bucket does not already exist.

**Demo-only credentials**: `RUSTFS_ACCESS_KEY`/`RUSTFS_SECRET_KEY` default to `rustfsadmin`/`rustfsadmin` (RustFS's own built-in defaults) via a plain Kubernetes `Secret`. This is fine for a local/CI showcase but must never be used as-is outside of a throwaway demo cluster.

This component is independent of the rest of the `athenz-distribution` showcases — deploying it has no effect unless [`athenz-zms-syncer`](../athenz-zms-syncer) is also deployed and `use-kubernetes-athenz-zms-syncer` is explicitly run to switch ZTS over to reading from it.

## Virtual-hosted-style S3 addressing (`<bucket>.rustfs.athenz`)

The AWS SDK used by both the ZMS Domain Syncer and ZTS's `S3ChangeLogStore` defaults to virtual-hosted-style S3 addressing (`<bucket>.<endpoint-host>`) rather than path-style (`<endpoint-host>/<bucket>`), with no configuration switch to change that. Making this work against RustFS requires two things, both handled automatically by `make deploy-kubernetes-rustfs`:

1. **RustFS itself**: the StatefulSet sets `RUSTFS_SERVER_DOMAINS=rustfs.athenz:9000` — without it, RustFS rejects virtual-hosted-style requests with `501 Not Implemented`. This value must exactly match the `Host` header (including port) that clients send, which in turn is derived from the `aws_s3_endpoint`/`AWS_S3_ENDPOINT` configured on the Syncer/ZTS side (`http://rustfs.athenz:9000`).
2. **Cluster DNS**: there's no wildcard DNS for `*.rustfs.athenz`, so `setup-rustfs`/`deploy-rustfs` also patches the `kube-system/coredns` `ConfigMap` (`patch-coredns-rustfs` target) with a `rewrite` rule that redirects any `<bucket>.rustfs.athenz...` query to the real `rustfs.athenz` Service record. This is the **only component in this repository that modifies cluster-wide (`kube-system`) state** rather than staying within its own namespace — if you're running this against a shared/existing cluster rather than the disposable KinD cluster from `deploy-kubernetes-in-docker`, be aware this adds a rule to your cluster's CoreDNS configuration and restarts the `coredns` Deployment. `clean-rustfs` removes this rule again via `clean-patch-coredns-rustfs`.

See [docs/SHOWCASES_KUBERNETES.md](../../docs/SHOWCASES_KUBERNETES.md) for the full setup flow.

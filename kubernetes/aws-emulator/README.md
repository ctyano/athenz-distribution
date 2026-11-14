# AWS temporary credentials showcase

After the basic Athenz deployment, image loading, and `make deploy-kubernetes-athenz-identityprovider` have completed on KinD, run:

```sh
make deploy-kubernetes-aws-emulator test-kubernetes-aws-emulator
```

The Makefile creates IAM role `showcaserole` in the [AWS Emulator](https://github.com/aws/aws-emulator) account `000000000000`, associates Athenz domain `awsshowcase` with that account, and grants `athenz.aws-emulator-client` the `assume_aws_role` action. The client runs as a Deployment with a dedicated Kubernetes ServiceAccount. Its `sia-wait` and `sia-init` containers obtain a workload certificate through Copper Argos using `athenz.identityprovider` and a projected ServiceAccount token. The SIA sidecar refreshes that certificate and obtains AWS temporary credentials from ZTS; the workload does not mount an administrator certificate or private key.

The test explicitly requests an IMDSv2 token from SIA, retrieves the role credentials, and parses and prints `AccessKeyId`, `SecretAccessKey`, `SessionToken`, and `Expiration` with `jq`. These are credentials issued by this local emulator. AWS CLI independently obtains credentials through SIA's IMDSv2 endpoint and calls STS `GetCallerIdentity`; the test checks the account, role, and workload identity. A request for an unauthorized role must return HTTP 403.

The emulator runs in its own Deployment. Its generated TLS certificate covers loopback addresses, so an Envoy sidecar forwards the in-cluster HTTP endpoint `http://aws-emulator.athenz:9298` to `https://127.0.0.1:9297`, validating the generated certificate and its IP SAN. A file-source SIA sidecar serves the emulator's generated credentials through IMDSv2, which ZTS's instance-profile credential provider requires. Envoy exposes this endpoint on Service port 1339; its SIA certificate refresh is disabled, and the mounted ZTS identity is used only to initialize SIA. These HTTP Service ports are for this local showcase and should not be published outside the test cluster. The client SIA's IMDSv2 endpoint remains on Pod loopback.

ZTS uses the shared `zts.properties` region and invalid-credential cache settings. The only showcase-specific ZTS changes are the AWS enablement and endpoint environment variables set in the Makefile. No ZTS command override or emulator-specific JVM truststore import is needed. The shared ZTS entrypoint supports `ZTS_TRUSTSTORE_ALIAS`, `ZTS_SIGNER_TRUSTSTORE_ALIAS`, and `ZMS_CLIENT_TRUSTSTORE_ALIAS`, each defaulting to the existing `ssl_trust_store` alias.

The [emulator image](https://github.com/ctyano/docker-aws-emulator) and `ghcr.io/ctyano/k8s-athenz-sia:awsimds` image are pulled from GHCR and loaded into KinD. To test local images, build them with those tags and pass `AWS_EMULATOR_PULL=false` and/or `AWS_SIA_PULL=false` to the deploy target.

To remove the showcase Deployments and restore ZTS's default AWS settings:

```sh
make clean-kubernetes-aws-emulator
```

The Athenz service, role, policy, and domain registrations remain for subsequent runs.

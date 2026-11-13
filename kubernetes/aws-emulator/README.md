# AWS temporary credentials showcase

From a KinD cluster where `make deploy-kubernetes-athenz` and `make load-kubernetes-images` have completed, run:

```sh
make deploy-kubernetes-aws-emulator test-kubernetes-aws-emulator
```

The setup uses the [AWS Emulator](https://github.com/aws/aws-emulator), packaged by [docker-aws-emulator](https://github.com/ctyano/docker-aws-emulator), to create IAM role `showcaserole` in account `000000000000`. In Athenz, it creates domain `awsshowcase`, associates that account, and grants `user.athenz_admin` the `assume_aws_role` action for that role. The test calls ZTS's `GetAWSTemporaryCredentials`, verifies that the issued credentials work with the emulator's STS `GetCallerIdentity`, and checks that a role without an Athenz grant is denied.

The emulator runs in the ZTS Pod so the AWS SDK can use its loopback HTTPS endpoint. ZTS currently obtains AWS credentials only from EC2 instance metadata, so a [k8s-athenz-sia](https://github.com/ctyano/k8s-athenz-sia) sidecar serves the emulator's generated credentials through IMDSv2. A second SIA sidecar in the test Pod fetches the authorized role's credentials from ZTS through the same IMDSv2 protocol; AWS CLI then uses those credentials without receiving them from the test script. The emulator's generated CA certificate is imported into ZTS's JVM trust store before ZTS starts. The setup changes the Kubernetes Deployment and adds a Service, leaving the base ZTS manifest and configuration file untouched.

The Make target builds SIA from the sibling `../k8s-athenz-sia` checkout and loads it into KinD. Set `AWS_SIA_CONTEXT` to another checkout path if needed. The emulator image is pulled from GHCR. For a local image built from `../docker-aws-emulator`, tag it `ghcr.io/ctyano/docker-aws-emulator:latest` and set `AWS_EMULATOR_PULL=false` when running the Make target.

The distribution workflow applies `k8s-athenz-sia.patch` to a pinned public SIA revision before building. This keeps CI runnable while the SIA change remains on a local branch. Refresh the patch from the SIA changes or remove it after those changes are published upstream.

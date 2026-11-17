# AWS Emulator Client

This Deployment demonstrates retrieving AWS temporary credentials from ZTS through the SIA sidecar. Its Kubernetes manifests and Makefile are separate from the [AWS Emulator](../aws-emulator/README.md).

After deploying the emulator and enabling AWS support in ZTS, run from the repository root:

```sh
make deploy-kubernetes-aws-emulator-client test-kubernetes-aws-emulator-client
```

The client Makefile registers the `awsshowcase` Athenz domain, its `showcaserole` authorization policy, and workload identity `athenz.aws-emulator-client`. The Deployment uses a dedicated Kubernetes ServiceAccount and a projected token to obtain its workload certificate through Copper Argos. SIA then requests role credentials from ZTS and serves them to the AWS CLI container through IMDSv2.

The test checks the returned credentials, verifies that AWS CLI uses the `iam-role` source, calls `aws sts get-caller-identity`, and checks that an unauthorized role is denied.

To remove only the client Deployment and its generated ConfigMap:

```sh
make clean-kubernetes-aws-emulator-client
```

The Athenz registrations remain for subsequent runs. The repository root's `deploy-kubernetes-aws-emulator` and `clean-kubernetes-aws-emulator` targets manage both applications together for the showcase.

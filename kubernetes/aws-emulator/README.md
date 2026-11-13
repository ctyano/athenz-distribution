# AWS temporary credentials showcase

From a KinD cluster where `make deploy-kubernetes-athenz` and `make load-kubernetes-images` have completed, run:

```sh
make deploy-kubernetes-aws-emulator test-kubernetes-aws-emulator
```

The setup uses the [AWS Emulator](https://github.com/aws/aws-emulator) to create IAM role `showcaserole` in account `000000000000`. In Athenz, it creates domain `awsshowcase`, associates that account, and grants `user.athenz_admin` the `assume_aws_role` action for that role. The test calls ZTS's `GetAWSTemporaryCredentials`, verifies that the issued credentials work with the emulator's STS `GetCallerIdentity`, and checks that a role without an Athenz grant is denied.

The emulator runs in the ZTS Pod so the AWS SDK can use its loopback HTTPS endpoint. ZTS currently obtains AWS credentials only from EC2 instance metadata; `metadata.py` serves the emulator's generated credentials through that API. The emulator's generated CA certificate is imported into ZTS's JVM trust store before ZTS starts. The setup changes the Kubernetes Deployment and adds a ConfigMap and Service, leaving the base ZTS manifest and configuration file untouched.

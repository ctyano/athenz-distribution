# User Authentication Showcases for Kubernetes

[![](https://img.plantuml.biz/plantuml/svg/ZLJ1RXCn4BtxAqRBfHMAKAySgj8WeOfoGXKIeK9UUv8rTUojFIPDKFuTZxsRP0aIvB0PUTvxysPdl3UHPA2qjiBYae0y1BFg2BG9gCXu9mGPiWZDE-hGxU0X8inbVdW77rEBmI5XR8IGYdmuXOK6P8IK0v4VYZdD5spXDlZDc6rhV0GCzFdzNSahQyvoB0rp37H0SGsL3uHGrYSDpT5OLaYHkDel0Q1aq0UTW5OIQiZoAHZQWlBhtZjq52kQVvMXmhP_CjLHW5Vt_8e-14Htm04uht54pg9VKXVNbH5FK02B2dciOXoU9WTYoGxn8RqNq_y5znpDoc6OzS6_R0khH1FtjT_YHTRMQmUtDk5P0nKnIxNRDBNEutkuAsMIEVFrXyHk7MTvC3-7KU-cKby_VIuw6VKl8TqM0TrE5BGasPxknVlRPWB8HRBuzshXcnlnOrNTdc3tVtt9Ux4Nl7u1PhFhSLVXBJI-HzSCcMjUKZx45rGS7nFZNawpemvhfiAqNadR-KWWbS8OuQ8ZwYyRmSeCotOP9tkJHsejR0nrHHsA_9him8bvgoDTLWibn_Io4Yp09sPfLDvxuCKnpgmoupbbqYZm6dviM46aIUs0Kh_Pv7k2eqdb7GLleVVMgEr0pqGc3CGyiamzJ6eW5lSNwsryjbodkcD6lGx_QPHVJyKpTRWhp3t7zqygNbrnhP6nw8pMw1upC--1k46d-Hlu6m00)](https://editor.plantuml.com/uml/ZLJ1RXCn4BtxAqRBfHMAKAySgj8WeOfoGXKIeK9UUv8rTUojFIPDKFuTZxsRP0aIvB0PUTvxysPdl3UHPA2qjiBYae0y1BFg2BG9gCXu9mGPiWZDE-hGxU0X8inbVdW77rEBmI5XR8IGYdmuXOK6P8IK0v4VYZdD5spXDlZDc6rhV0GCzFdzNSahQyvoB0rp37H0SGsL3uHGrYSDpT5OLaYHkDel0Q1aq0UTW5OIQiZoAHZQWlBhtZjq52kQVvMXmhP_CjLHW5Vt_8e-14Htm04uht54pg9VKXVNbH5FK02B2dciOXoU9WTYoGxn8RqNq_y5znpDoc6OzS6_R0khH1FtjT_YHTRMQmUtDk5P0nKnIxNRDBNEutkuAsMIEVFrXyHk7MTvC3-7KU-cKby_VIuw6VKl8TqM0TrE5BGasPxknVlRPWB8HRBuzshXcnlnOrNTdc3tVtt9Ux4Nl7u1PhFhSLVXBJI-HzSCcMjUKZx45rGS7nFZNawpemvhfiAqNadR-KWWbS8OuQ8ZwYyRmSeCotOP9tkJHsejR0nrHHsA_9him8bvgoDTLWibn_Io4Yp09sPfLDvxuCKnpgmoupbbqYZm6dviM46aIUs0Kh_Pv7k2eqdb7GLleVVMgEr0pqGc3CGyiamzJ6eW5lSNwsryjbodkcD6lGx_QPHVJyKpTRWhp3t7zqygNbrnhP6nw8pMw1upC--1k46d-Hlu6m00)

## Prerequisite

- A running Kubernetes cluster
- kubectl

Other required dependencies will be automatically installed.

## Full setup on a KinD cluster ⎈

### Setup with minimal components

```
make load-docker-images load-kubernetes-images clean-kubernetes-athenz deploy-kubernetes-crypki-softhsm use-kubernetes-crypki-softhsm deploy-kubernetes-athenz deploy-kubernetes-athenz-oauth2
```

### Setup with full assets

```
make load-docker-images load-kubernetes-images clean-kubernetes-athenz deploy-kubernetes-crypki-softhsm use-kubernetes-crypki-softhsm deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads deploy-kubernetes-athenz-oauth2
```

## Full setup on a Kubernetes cluster ⎈

### Setup with minimal components

```
make clean-kubernetes-athenz deploy-kubernetes-crypki-softhsm use-kubernetes-crypki-softhsm deploy-kubernetes-athenz deploy-kubernetes-athenz-oauth2
```

### Setup with full assets

```
make clean-kubernetes-athenz deploy-kubernetes-crypki-softhsm use-kubernetes-crypki-softhsm deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads deploy-kubernetes-athenz-oauth2
```

## Each steps in Makefile

- `load-docker-images` pulls container images from remote registry.
- `load-kubernetes-images` loads container images to a newly created kind cluster.
- `clean-kubernetes-athenz` cleans up the keys and certs and all Kubernetes resources within `athenz` namespace.
- `deploy-kubernetes-crypki-softhsm` prepares the keys and the certs locally and deploys `crypki-softhsm` and then renews the certs issued with crypki-softhsm.
- `use-kubernetes-crypki-softhsm` prepares the keys and the certs issued with crypki and then overwrites the certs locally generated.
- `deploy-kubernetes-athenz` prepares the keys and the certs locally (if they do not exist) and deploys `athenz-db`, `athenz-zms-server`, `athenz-zts-server`, `athenz-cli`, and `athenz-ui`.
- `deploy-kubernetes-athenz-identityprovider` registers required information to athenz and deploys copper argos identity provider.
- `deploy-kubernetes-athenz-workloads` registers required information to athenz for each showcase and deploys miscellaneous workload applications for authentication/authorization showcases.
- `deploy-kubernetes-athenz-oauth2` deploys `dex` to authenticate user with oidc and deploys `certsigner-envoy` to check request against `crypki-softhsm` to sign user certificates.

## After completing the setup

### How to install CLI

You may retrieve Athenz-compatible user certificate with `athenz_user_cert` command line utility.

```
brew tap ctyano/athenz_user_cert https://github.com/ctyano/athenz_user_cert
```

```
brew install ctyano/athenz_user_cert/athenz_user_cert
```

### How to run CLI

To run `athenz_user_cert`, you must forward requests to `dex` and `certsigner-envoy`.

```
kubectl -n athenz port-forward deployment/oauth2-deployment 5556:5556
```

```
kubectl -n athenz port-forward deployment/oauth2-deployment 10000:10000
```


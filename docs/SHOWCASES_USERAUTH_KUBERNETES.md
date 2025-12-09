# User Authentication Showcases for Kubernetes

[![](https://img.plantuml.biz/plantuml/svg/ZLLDJnin4BtxLuos5r2rHLnxG1GgLQZqLA5AXQhosWDnSUp57uIaod_lZBqRTac_SjWuw_VUp3pFEASnoP3oqWgBjmcIXs3k5Wcq2QYIyKw8P995QDwb1ReDN4M4SqaFx-1ZxZ0uJ1WR8QHAFanXeG4P8TD2q4Cnf_c27Pm5lnftkxf-1WpqyykBig-isTjZQJZ7a1XrumvMFjn71dkPqmBwt5cZc8ak7UvoK4GGGbcVDJJFYHCknyJP_1G0IWQzYnFGoeGQA7mE9gr1-MNl7Qd6YkPFPQYmxkzDpJZ0gqksy4D0T3iSWFCQHsGR_MrQn6Lbn0aAuBf2lbKnNaut1sBP7TQxxQsOVrzppT7SEGnj7_pJUjyiVlXWDfAFcYeDZnWEYtWXZ48Qd_QvHfCLx0j17-d7G2Jip9lgPgbKLcEhFsSsuvuz5T7cwcMU6yFDStLHWcIpL_KBYSqojhMU8hMPIttzzBde4EfVGheh0hgRAMYPP3VjolTdpGn0GKZyUqtXnetuCQhk9jZjRuzmAxQ2cpz0sxOduwZ0MsXyZwwPR56lysjymjBtS0JMAsaNFgRXhEeqJ3dZJ4o9DCLZb3RtBq3Fab8fZ14E5YdrXrCECynViJl1DoVSA8mDME-QiS1cfZU0_YZ8vJAEB6MSx0srdRMmCbHrgRQ4MoOxS2BDTKpJL9XUkfq5-8svDOec7tXqZ3Dtn7Z8H1e5NiEF5Ik8F8iTKEgZ5TqKE2Qfl4l1M-WztKZhWKv49Wn4QYkYxhff89Ri3vRh-60vJiskd7Iv4FupKRQdufawt1RCtSVtzoeU7tEiaN6zC9e6_1kVGIV4AJhD_nA_0000)](https://editor.plantuml.com/uml/ZLLDJnin4BtxLuos5r2rHLnxG1GgLQZqLA5AXQhosWDnSUp57uIaod_lZBqRTac_SjWuw_VUp3pFEASnoP3oqWgBjmcIXs3k5Wcq2QYIyKw8P995QDwb1ReDN4M4SqaFx-1ZxZ0uJ1WR8QHAFanXeG4P8TD2q4Cnf_c27Pm5lnftkxf-1WpqyykBig-isTjZQJZ7a1XrumvMFjn71dkPqmBwt5cZc8ak7UvoK4GGGbcVDJJFYHCknyJP_1G0IWQzYnFGoeGQA7mE9gr1-MNl7Qd6YkPFPQYmxkzDpJZ0gqksy4D0T3iSWFCQHsGR_MrQn6Lbn0aAuBf2lbKnNaut1sBP7TQxxQsOVrzppT7SEGnj7_pJUjyiVlXWDfAFcYeDZnWEYtWXZ48Qd_QvHfCLx0j17-d7G2Jip9lgPgbKLcEhFsSsuvuz5T7cwcMU6yFDStLHWcIpL_KBYSqojhMU8hMPIttzzBde4EfVGheh0hgRAMYPP3VjolTdpGn0GKZyUqtXnetuCQhk9jZjRuzmAxQ2cpz0sxOduwZ0MsXyZwwPR56lysjymjBtS0JMAsaNFgRXhEeqJ3dZJ4o9DCLZb3RtBq3Fab8fZ14E5YdrXrCECynViJl1DoVSA8mDME-QiS1cfZU0_YZ8vJAEB6MSx0srdRMmCbHrgRQ4MoOxS2BDTKpJL9XUkfq5-8svDOec7tXqZ3Dtn7Z8H1e5NiEF5Ik8F8iTKEgZ5TqKE2Qfl4l1M-WztKZhWKv49Wn4QYkYxhff89Ri3vRh-60vJiskd7Iv4FupKRQdufawt1RCtSVtzoeU7tEiaN6zC9e6_1kVGIV4AJhD_nA_0000)

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


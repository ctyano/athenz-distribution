# Showcases for Kubernetes

[![](https://img.plantuml.biz/plantuml/svg/ZLPDRzGm4BtxLupIIpaifGSESAZwWOGgYbHH2eAoGexZDgQEdTgJRdVH_dV67yac_T2oXrt7Vk_D6tiysKEFt67NQARbDG9QSEgcHgYKamALDOoXGYsXEC9QcXLSUWaddBwiWKzTAPsHA7t161TetHZc2k0UEXem-XA1KtoN9Hmxk-XNopJU03BzvEmqhWkj61FQTXKKcsWqtNaC4dyPWE2k6eXEQewo0jBhdC8b2DkqraY3Fg739p64MxQtAeLni7CMylxef3G33i3OIlR8cRVNMFicCVm81N2L8FCa5eRZnKoCgtayBA_Pz7USJOp4KsB9tx7kv1Dx2J7hKYxTr5ZOySlJ6BfJJw8-abWrVaR7SPzFPpML-ldv8keGQgiGJeJmaT3NB8HRXQeo2bJbHA7YoCjnlNmuBYO02a8kVoSBlqoFx-rNvICileJ5ANQzvTnIgRREtgigvquF-V1-IAtjugNZ8uAXgxQSJTdJdSlfdcOid6ViF4UA3yzwN0ytnKblEoVe1YzCZX97sUMvChSvwCGVxx2sJgruw0h1vCCorUUcIgwEnfXWxc4PdGNkgWTzwUDVn1sFWDuJUsgNMW0b2xnjjH9HE5r03ZlVbDKIdpERI0cuiNUIf8usKlFSP6Xw57hDGaDoC3le6nIyXyAsqXIidvZHOgV2lBQ2wzfwyYY4z1vsQyJsLJ5ea7x0oGSfmhXWOIBmgHB30cyLfQDr8iRDGAApRe9oabTx2-ffieyZh45dDRIMqbbcDX6fQCV4QucYtiff0YUHwB8HRRXZcRbGMCDki_HtUXm3_mi-uFiQZNaZzN9CjRAGPMtjxQCa3d8p3MWX7QhhS6uIlBenogWRsggxZZGsj8mdPcwqWVeKtjuAlxyVZENoohbizklXzTitxo041Mug-BCWLeCwn8ZLl9MHKFq-Jwa7Gy57kdMBKEhz3QFNLs-KtiURykhhQh0S3on9aaoZ1BMQqCOKwOPfivSMwHtOT2QNVFAo5n8Ag-CzkAfLHPrbFZedDXWTh-ORmmwbgS9_Xty0)](https://editor.plantuml.com/uml/ZLPDRzGm4BtxLupIIpaifGSESAZwWOGgYbHH2eAoGexZDgQEdTgJRdVH_dV67yac_T2oXrt7Vk_D6tiysKEFt67NQARbDG9QSEgcHgYKamALDOoXGYsXEC9QcXLSUWaddBwiWKzTAPsHA7t161TetHZc2k0UEXem-XA1KtoN9Hmxk-XNopJU03BzvEmqhWkj61FQTXKKcsWqtNaC4dyPWE2k6eXEQewo0jBhdC8b2DkqraY3Fg739p64MxQtAeLni7CMylxef3G33i3OIlR8cRVNMFicCVm81N2L8FCa5eRZnKoCgtayBA_Pz7USJOp4KsB9tx7kv1Dx2J7hKYxTr5ZOySlJ6BfJJw8-abWrVaR7SPzFPpML-ldv8keGQgiGJeJmaT3NB8HRXQeo2bJbHA7YoCjnlNmuBYO02a8kVoSBlqoFx-rNvICileJ5ANQzvTnIgRREtgigvquF-V1-IAtjugNZ8uAXgxQSJTdJdSlfdcOid6ViF4UA3yzwN0ytnKblEoVe1YzCZX97sUMvChSvwCGVxx2sJgruw0h1vCCorUUcIgwEnfXWxc4PdGNkgWTzwUDVn1sFWDuJUsgNMW0b2xnjjH9HE5r03ZlVbDKIdpERI0cuiNUIf8usKlFSP6Xw57hDGaDoC3le6nIyXyAsqXIidvZHOgV2lBQ2wzfwyYY4z1vsQyJsLJ5ea7x0oGSfmhXWOIBmgHB30cyLfQDr8iRDGAApRe9oabTx2-ffieyZh45dDRIMqbbcDX6fQCV4QucYtiff0YUHwB8HRRXZcRbGMCDki_HtUXm3_mi-uFiQZNaZzN9CjRAGPMtjxQCa3d8p3MWX7QhhS6uIlBenogWRsggxZZGsj8mdPcwqWVeKtjuAlxyVZENoohbizklXzTitxo041Mug-BCWLeCwn8ZLl9MHKFq-Jwa7Gy57kdMBKEhz3QFNLs-KtiURykhhQh0S3on9aaoZ1BMQqCOKwOPfivSMwHtOT2QNVFAo5n8Ag-CzkAfLHPrbFZedDXWTh-ORmmwbgS9_Xty0)

## Prerequisite

- A running Kubernetes cluster
- kubectl

Other required dependencies will be automatically installed.

## Full setup on a KinD cluster ⎈

### Setup with minimal components

```
make load-docker-images load-kubernetes-images clean-kubernetes-athenz deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads
```

Running Athenz together with [crypki](https://github.com/theparanoids/crypki), every certificates will be signed by [softhsm](https://github.com/ctyano/crypki-softhsm).

### Setup with Crypki

```
make load-docker-images load-kubernetes-images clean-kubernetes-athenz deploy-kubernetes-crypki-softhsm use-kubernetes-crypki-softhsm deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads
```

## Full setup on a Kubernetes cluster ⎈

### Setup with minimal components

```
make clean-kubernetes-athenz deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads
```

Running Athenz together with [crypki](https://github.com/theparanoids/crypki), every certificates will be signed by [softhsm](https://github.com/ctyano/crypki-softhsm).

### Setup with Crypki

```
make clean-kubernetes-athenz deploy-kubernetes-crypki-softhsm use-kubernetes-crypki-softhsm deploy-kubernetes-athenz deploy-kubernetes-athenz-identityprovider deploy-kubernetes-athenz-workloads
```

## Each steps in Makefile

- `load-docker-images` pulls container images from remote registry.
- `load-kubernetes-images` loads container images to a newly created kind cluster.
- `clean-kubernetes-athenz` cleans up the keys and certs and all Kubernetes resources within `athenz` namespace.
- `deploy-kubernetes-crypki-softhsm` prepares the keys and the certs locally and deploys `crypki-softhsm` and then renews the certs issued with crypki-softhsm.
- `use-kubernetes-crypki-softhsm` prepares the keys and the certs issued with crypki and then overwrites the certs locally generated.
- `deploy-kubernetes-athenz` prepares the keys and the certs locally (if they do not exist) and deploys `athenz-db`, `athenz-zms-server`, `athenz-zts-server`, `athenz-cli`, and `athenz-ui`.
- `deploy-kubernetes-athenz-identityprovider` registers required informations to athenz and deploys copper argos identity provider.
- `deploy-kubernetes-athenz-workloads` registers required informations to athenz for the each showcase and deploys miscellaneous workload applications for authentication/authorization showcases.

## After completing the setup

You may access Athenz UI at http://localhost:3000 by forwarding requests.

```
kubectl -n athenz port-forward deployment/athenz-ui 3000:3000
```

## How to try them out

After deploying workload components, you can run some test to see how Athenz authorization processes work.

To try the authorization checks in various showcases:

```
make test-kubernetes-athenz-showcases
```

## How to try load testing

This showcase includes some senarios to benchmark the performance of Athenz authorization process.

To deploy applications to try load testing:

```
make deploy-kubernetes-athenz-loadtest
```

To execute load testing:

```
make test-kubernetes-athenz-loadtest
```

The loadtest results will be printed to html files in the current directory.


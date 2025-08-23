# List of Distributions

## Docker(OCI) Images

Primary Docker(OCI) image distributions:

  - [athenz-db](https://github.com/users/ctyano/packages/container/package/athenz-db)
    - This image provides MariaDB database to store data for ZMS and ZTS.
    - This image includes DDLs to reduce database setup efforts.
  - [athenz-zms-server](https://github.com/users/ctyano/packages/container/package/athenz-zms-server)
    - This image provides Athenz ZMS server component.
    - This image includes additional capabilities that read PEM certificates to convert into JKS/PKCS12 keystores to reduce deployer environment dependencies.
    - This image includes various solution templates for useful showcases.
  - [athenz-zts-server](https://github.com/users/ctyano/packages/container/package/athenz-zts-server)
    - This image includes additional capabilities that read pem certificates to convert into JKS/PKCS12 keystores to reduce deployer environment dependencies.
  - [athenz-cli](https://github.com/users/ctyano/packages/container/package/athenz-cli)
    - This image includes various CLIs for debugging/demonstrating perposes.
  - [athenz-ui](https://github.com/users/ctyano/packages/container/package/athenz-ui)
    - This image includes functional Athenz Web UI.
    - This image includes additional compatibility with OIDC auth proxy (e.g. [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/)).

External Docker(OCI) image distributions:

  - [athenz_user_cert](https://github.com/users/ctyano/packages/container/package/athenz_user_cert)
    - This image includes CLI to intract with [certsigner-envoy](https://github.com/users/ctyano/packages/container/package/certsigner-envoy) to retrieve certificate for Athenz user authentication.
  - [certsigner-envoy](https://github.com/users/ctyano/packages/container/package/certsigner-envoy)
    - This image includes Envoy proxy and the Wasm plugin to provide user authentication mechanism to control access to the CertSigner server as [crypki](https://github.com/theparanoids/crypki) or [cfssl](https://github.com/cfssl/cfssl).
    - This image is a wrapper of [envoyproxy](https://hub.docker.com/r/envoyproxy/envoy).
  - [crypki-softhsm](https://github.com/users/ctyano/packages/container/package/crypki-softhsm)
    - This image provides SoftHSM and [crypki](https://github.com/theparanoids/crypki) server.
    - This image includes Crypki that can dynamically configure the signing options.
  - [athenz-plugins](https://github.com/users/ctyano/packages/container/package/athenz-plugins)
    - This image includes various jar files that include plugins for Athenz ZMS and Athenz ZTS.
    - This image copies the jar files to specified locations when running as a container runtime.
  - [k8s-athenz-sia](https://github.com/users/ctyano/packages/container/package/k8s-athenz-sia)
    - This image is an enhanced version of [k8s-athenz-sia](https://github.com/AthenZ/k8s-athenz-sia).
    - This image provides additional capability to accept authorization check requests from the sidecar proxies like Envoy’s External Authorization filter.
  - [authorization-envoy](https://github.com/users/ctyano/packages/container/package/authorization-envoy)
    - This image includes Envoy proxy and the Wasm plugin to provide Athenz authentication and Athenz RBAC mechanism to control access to the upstream cluster.
    - This image is a wrapper of [envoyproxy](https://hub.docker.com/r/envoyproxy/envoy).

Third party Docker(OCI) images:

  - [open-policy-agent](https://hub.docker.com/r/openpolicyagent/opa)
  - [kube-mgmt](https://hub.docker.com/r/openpolicyagent/kube-mgmt)
  - [envoy](https://hub.docker.com/r/envoyproxy/envoy)
  - [ghostunnel](https://hub.docker.com/r/ghostunnel/ghostunnel)
  - [oauth2-proxy](https://quay.io/repository/oauth2-proxy/oauth2-proxy)
  - [dex](https://github.com/dexidp/dex/pkgs/container/dex)
  - [cfssl](https://hub.docker.com/r/cfssl/cfssl)

## Homebrew formulas

  - [athenz_user_cert](https://github.com/ctyano/athenz_user_cert)
    - This formula includes CLI to intract with [certsigner-envoy](https://github.com/users/ctyano/packages/container/package/certsigner-envoy) to retrieve certificate for Athenz user authentication.

## Linux packages (Under development)

Linux package distributions for several platforms:

https://github.com/ctyano/athenz-distribution/releases


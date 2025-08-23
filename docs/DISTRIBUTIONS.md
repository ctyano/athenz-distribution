# List of Distributions

## Docker(OCI) Images

Primary Docker(OCI) image distributions:

  - [athenz-db](https://github.com/users/ctyano/packages/container/package/athenz-db)  
    - This image provides a MariaDB database to store data for ZMS and ZTS.  
    - This image includes DDLs to reduce database setup efforts.  
  - [athenz-zms-server](https://github.com/users/ctyano/packages/container/package/athenz-zms-server)  
    - This image provides the [Athenz ZMS server component](https://athenz.github.io/athenz/system_view/#zms-authz-management-system).  
    - This image includes additional capabilities to read PEM certificates and convert them into JKS/PKCS12 keystores to reduce deployer environment dependencies.  
    - This image includes various solution templates for useful showcases.  
  - [athenz-zts-server](https://github.com/users/ctyano/packages/container/package/athenz-zts-server)  
    - This image provides the [Athenz ZTS server component](https://athenz.github.io/athenz/system_view/#zts-authz-token-system).  
    - This image includes additional capabilities to read PEM certificates and convert them into JKS/PKCS12 keystores to reduce deployer environment dependencies.  
  - [athenz-cli](https://github.com/users/ctyano/packages/container/package/athenz-cli)  
    - This image includes various CLIs for debugging/demonstration purposes.  
  - [athenz-ui](https://github.com/users/ctyano/packages/container/package/athenz-ui)  
    - This image includes a functional Athenz Web UI.  
    - This image includes additional compatibility with an OIDC auth proxy (e.g., [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/)).  

External Docker(OCI) image distributions:

  - [athenz_user_cert](https://github.com/users/ctyano/packages/container/package/athenz_user_cert)  
    - This image includes a CLI to interact with [certsigner-envoy](https://github.com/users/ctyano/packages/container/package/certsigner-envoy) to retrieve certificates for Athenz user authentication.  
  - [certsigner-envoy](https://github.com/users/ctyano/packages/container/package/certsigner-envoy)  
    - This image includes the Envoy proxy and a Wasm plugin to provide a user authentication mechanism to control access to the CertSigner server, such as [crypki](https://github.com/theparanoids/crypki) or [cfssl](https://github.com/cfssl/cfssl).  
    - This image is a wrapper of [envoyproxy](https://hub.docker.com/r/envoyproxy/envoy).  
  - [crypki-softhsm](https://github.com/users/ctyano/packages/container/package/crypki-softhsm)  
    - This image provides SoftHSM and the [crypki](https://github.com/theparanoids/crypki) server.  
    - This image includes Crypki that can dynamically configure signing options.  
  - [athenz-plugins](https://github.com/users/ctyano/packages/container/package/athenz-plugins)  
    - This image includes various JAR files containing plugins for Athenz ZMS and Athenz ZTS.  
    - This image copies the JAR files to specified locations when running in a container runtime.  
  - [k8s-athenz-sia](https://github.com/users/ctyano/packages/container/package/k8s-athenz-sia)  
    - This image is an enhanced version of [k8s-athenz-sia](https://github.com/AthenZ/k8s-athenz-sia).  
    - This image provides additional capability to accept authorization check requests from sidecar proxies like [Envoy's External Authorization filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter).  
  - [authorization-envoy](https://github.com/users/ctyano/packages/container/package/authorization-envoy)  
    - This image includes the Envoy proxy and a Wasm plugin to provide Athenz authentication and RBAC mechanisms to control access to the upstream cluster.  
    - This image is a wrapper of [envoyproxy](https://hub.docker.com/r/envoyproxy/envoy).  

Third-party Docker(OCI) images:

  - [open-policy-agent](https://hub.docker.com/r/openpolicyagent/opa)  
  - [kube-mgmt](https://hub.docker.com/r/openpolicyagent/kube-mgmt)  
  - [envoy](https://hub.docker.com/r/envoyproxy/envoy)  
  - [ghostunnel](https://hub.docker.com/r/ghostunnel/ghostunnel)  
  - [oauth2-proxy](https://quay.io/repository/oauth2-proxy/oauth2-proxy)  
  - [dex](https://github.com/dexidp/dex/pkgs/container/dex)  
  - [cfssl](https://hub.docker.com/r/cfssl/cfssl)  

## Homebrew formulas

  - [athenz_user_cert](https://github.com/ctyano/athenz_user_cert)  
    - This formula includes a CLI to interact with [certsigner-envoy](https://github.com/users/ctyano/packages/container/package/certsigner-envoy) to retrieve certificates for Athenz user authentication.  

## Linux packages (Under development)

Linux package distributions for several platforms:

https://github.com/ctyano/athenz-distribution/releases


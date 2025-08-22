# Envoy Ambassador Instruction for Kubernetes

## Deployment Instructions

### [athenz-identityprovider](../kubernetes/athenz-identityprovider)

Envoy configuration: [config.yaml](../kubernetes/athenz-identityprovider/kustomize/envoy/config.yaml)

### [athenz-authorizer](../kubernetes/athenz-authorizer)

Envoy configuration: [config.yaml](../kubernetes/athenz-authorizer/kustomize/envoy/config.yaml)

### [athenz-authzenvoy](../kubernetes/athenz-authzenvoy)

Envoy configuration: [config.yaml](../kubernetes/athenz-authzenvoy/kustomize/envoy/config.yaml)

### [athenz-authzwebhook](../kubernetes/athenz-authzwebhook)

Envoy configuration: [config.yaml](../kubernetes/athenz-authzwebhook/kustomize/envoy/config.yaml)

### [athenz-client](../kubernetes/athenz-client)

Envoy configuration: [config.yaml](../kubernetes/athenz-client/kustomize/envoy/config.yaml)

## How to try them out

Setup [Kubernetes Showcase](https://github.com/ctyano/athenz-distribution/blob/main/docs/SHOWCASES_KUBERNETES.md#full-setup-on-a-kubernetes-cluster-) as prerequisite.

### client2echoserver

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2echoserver.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|http + jwt/ztoken| C(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2echoserver | jq -r .request"
```

### client2extauthz

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2extauthz.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|https/tls + jwt/ztoken| C(ingress server proxy envoy\nwith extauthz filter\nwith authorization sidecar) -->|http + headers| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2extauthz | jq -r .request"
```

### client2extauthzmtls

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2extauthzmtls.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|https/mutual tls + jwt/ztoken| C(ingress server proxy envoy\nwith extauthz filter\nwith authorization sidecar) -->|http + headers| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2extauthzmtls | jq -r .request"
```

### client2authzproxy

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2authzproxy.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|https/tls + jwt/ztoken| C(authorization-proxy) -->|http + headers| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli — /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2authzproxy | jq -r .request"
```

### tokensidecar

[Load Test Result](https://ctyano.github.io/athenz-distribution/tokensidecar.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|http + headers| C(token sidecar)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r ."
```

### authorizationsidecar

[Load Test Result](https://ctyano.github.io/athenz-distribution/authorizationsidecar.html)

```mermaid
flowchart LR
A(curl) -->|https/tls + jwt/ztoken| B(ingress server proxy envoy) -->|http + headers| C(authorization sidecar)
```

with Role Token:

```
roletoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .roletoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Athenz-Role-Auth: $roletoken\" -H \"X-Athenz-Action: get\" -H \"X-Athenz-Resource: /server\" https://authorizer.athenz.svc.cluster.local/authorizationsidecar | jq -r ."
```

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" -H \"X-Athenz-Action: get\" -H \"X-Athenz-Resource: /server\" https://authorizer.athenz.svc.cluster.local/authorizationsidecar | jq -r ."
```

### authzproxy(authorization-proxy)

[Load Test Result](https://ctyano.github.io/athenz-distribution/authzproxy.html)

```mermaid
flowchart LR
A(curl) -->|https/tls + jwt/ztoken| B(authorization-proxy) -->|http + headers| C(echoserver)
```

with Role Token:

```
roletoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: authorization-proxy-clients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .roletoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Athenz-Role-Auth: $roletoken\" https://authzproxy.athenz.svc.cluster.local/echoserver | jq -r .request"
```

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: authorization-proxy-clients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" https://authzproxy.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### client2filterauthzmtls

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2filterauthzmtls.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|https/mutual tls| C(ingress server proxy envoy\nwith lua filter) -->|http + headers| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2filterauthzmtls | jq -r .request"
```

### client2filterauthzjwt

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2filterauthzjwt.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|https/tls + jwt| C(ingress server proxy envoy\nwith jwt filter) -->|http + headers| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2filterauthzjwt | jq -r .request"
```

### client2filterauthzmtlsjwt

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2filterauthzmtlsjwt.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|https/mutual tls + jwt| C(ingress server proxy envoy\nwith lua filter\nwith jwt filter) -->|http + headers| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2filterauthzmtlsjwt | jq -r .request"
```

### envoyjwtfilter(jwt filter/lua filter)

[Load Test Result](https://ctyano.github.io/athenz-distribution/envoyjwtfilter.html)

```mermaid
flowchart LR
A(curl) -->|https/tls + jwt| B(ingress server proxy envoy\nwith lua filter\nwith jwt filter) -->|http + headers| C(echoserver)
```

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" https://authzenvoy.athenz.svc.cluster.local/jwtauthn | jq -r .request"
```

### client2webhookauthzmtls

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2webhookauthzmtls.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|https/mutual tls| C(ingress server proxy envoy\nwith lua filter\nwith lua filter for zts authz webhook) -->|http + headers| D(echoserver)
C(ingress server proxy envoy\nwith lua filter\nwith lua filter for zts authz webhook) -->|https/mutual tls| D(zts)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2webhookauthzmtls | jq -r .request"
```

### client2webhookauthzjwt

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2webhookauthzjwt.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|https/tls + jwt| C(ingress server proxy envoy\nwith jwt filter\nwith lua filter for zts authz webhook) -->|http + headers| D(echoserver)
C(ingress server proxy envoy\nwith jwt filter\nwith lua filter for zts authz webhook) -->|https/mutual tls| D(zts)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2webhookauthzjwt | jq -r .request"
```

### client2webhookauthzmtlsjwt

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2webhookauthzmtlsjwt.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith extauthz filter\nwith token sidecar) -->|https/mutual tls + jwt| C(ingress server proxy envoy\nwith lua filter\nwith jwt filter\nwith lua filter for zts authz webhook) -->|http + headers| D(echoserver)
C(ingress server proxy envoy\nwith lua filter\nwith jwt filter\nwith lua filter for zts authz webhook) -->|https/mutual tls| D(zts)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2webhookauthzmtlsjwt | jq -r .request"
```

### envoywebhook(jwt filter/lua filter/lua filter for zts authz webhook)

[Load Test Result](https://ctyano.github.io/athenz-distribution/envoywebhook.html)

```mermaid
flowchart LR
A(curl) -->|https/tls + jwt| B(ingress server proxy envoy\nwith lua filter\nwith jwt filter\nwith lua filter for zts authz webhook) -->|http + headers| C(echoserver)
B(ingress server proxy envoy\nwith lua filter\nwith jwt filter\nwith lua filter for zts authz webhook) -->|https/mutual tls| D(zts)
```

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" https://authzwebhook.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### echoserver(client)

[Load Test Result](https://ctyano.github.io/athenz-distribution/echoserver.client.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|http + headers| C(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### echoserver(authorizer)

[Load Test Result](https://ctyano.github.io/athenz-distribution/echoserver.authorizer.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress server proxy envoy) -->|http + headers| C(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://authorizer.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### zms(authorization management service)

[Load Test Result](https://ctyano.github.io/athenz-distribution/zms.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|https/mutual tls| C(athenz zms server)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/zms/v1/domain/sys.auth/service | jq -r ."
```

### zts(authorization token service)

[Load Test Result](https://ctyano.github.io/athenz-distribution/zts.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|https/mutual tls| C(athenz zts server)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/zts/v1/domain/sys.auth/service | jq -r ."
```

### client(metrics)

prometheus metrics

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\n/stats/prometheus)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/stats/prometheus"
```

### server(metrics)

prometheus metrics

```mermaid
flowchart LR
A(curl) -->|https/tls| B(ingress server proxy envoy\n/stats/prometheus)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://authorizer.athenz.svc.cluster.local/stats/prometheus"
```


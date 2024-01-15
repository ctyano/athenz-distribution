# Envoy Ambassador Instruction for Kubernetes

## Deployment Instructions

### [athenz-identityprovider](../kubernetes/athenz-identityprovider)

Envoy configuration: [config.yaml](../kubernetes/athenz-identityprovider/kustomize/envoy/config.yaml)

### [athenz-authorizer](../kubernetes/athenz-authorizer)

Envoy configuration: [config.yaml](../kubernetes/athenz-authorizer/kustomize/envoy/config.yaml)

### [athenz-client](../kubernetes/athenz-client)

Envoy configuration: [config.yaml](../kubernetes/athenz-client/kustomize/envoy/config.yaml)

## How to try them out

### client2server

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2server.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/tls + jwt/ztoken| C(ingress server proxy envoy\nwith authorization sidecar) -->|http| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2server | jq -r .request"
```

### client2servermtls

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2servermtls.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/mutual tls + jwt/ztoken| C(ingress server proxy envoy\nwith authorization sidecar) -->|http| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2servermtls | jq -r .request"
```

### client2authzproxy

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2authzproxy.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/tls + jwt/ztoken| C(authorization-proxy) -->|http| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli — /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2authzproxy | jq -r .request"
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
A(curl) -->|https/tls + jwt/ztoken| B(ingress server proxy envoy) -->|http| C(authorization sidecar)
```

with Role Token:

```
roletoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .roletoken" | xargs echo -n)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Athenz-Role-Auth: $roletoken\" -H \"X-Athenz-Action: get\" -H \"X-Athenz-Resource: /server\" https://authorizer.athenz.svc.cluster.local/authorizationsidecar | jq -r .request"
```

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken" | xargs echo -n)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" -H \"X-Athenz-Action: get\" -H \"X-Athenz-Resource: /server\" https://authorizer.athenz.svc.cluster.local/authorizationsidecar | jq -r .request"
```

### authzproxy(authorization-proxy)

[Load Test Result](https://ctyano.github.io/athenz-distribution/authzproxy.html)

```mermaid
flowchart LR
A(curl) -->|https/tls + jwt/ztoken| B(authorization-proxy) -->|http| C(echoserver)
```

with Role Token:

```
roletoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: authorization-proxy-clients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .roletoken" | xargs echo -n)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Athenz-Role-Auth: $roletoken\" https://authzproxy.athenz.svc.cluster.local/echoserver | jq -r .request"
```

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: authorization-proxy-clients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken" | xargs echo -n)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" https://authzproxy.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### client2echoserverjwt

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2echoserverjwt.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/tls + jwt| C(ingress server proxy envoy\nwith jwt filter) -->|http| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2echoserverjwt | jq -r .request"
```

### client2echoservermtls

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2echoservermtls.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/mutual tls| C(ingress server proxy envoy\nwith lua filter) -->|http| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2echoservermtls | jq -r .request"
```

### client2echoserver

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2echoserver.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|http + jwt/ztoken| C(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2echoserver | jq -r .request"
```

### echoserver(client)

[Load Test Result](https://ctyano.github.io/athenz-distribution/echoserver.client.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|http| C(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### echoserver(authorizer)

[Load Test Result](https://ctyano.github.io/athenz-distribution/echoserver.authorizer.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress server proxy envoy) -->|http| C(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://authorizer.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### zms

[Load Test Result](https://ctyano.github.io/athenz-distribution/zms.html)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|https/mutual tls| C(athenz zms server)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/zms/v1/domain/sys.auth/service | jq -r ."
```

### zts

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
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/stats/prometheus"
```

### server(metrics)

prometheus metrics

```mermaid
flowchart LR
A(curl) -->|https/tls| B(ingress server proxy envoy\n/stats/prometheus)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://authorizer.athenz.svc.cluster.local/stats/prometheus"
```

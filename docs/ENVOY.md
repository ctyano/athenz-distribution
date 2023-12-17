# Envoy Ambassador Instruction for Kubernetes

## Deployment Instructions

### [athenz-identityprovider](../kubernetes/athenz-identityprovider)

Envoy configuration: [config.yaml](../kubernetes/athenz-identityprovider/kustomize/envoy/config.yaml)

### [athenz-authorizer](../kubernetes/athenz-authorizer)

Envoy configuration: [config.yaml](../kubernetes/athenz-authorizer/kustomize/envoy/config.yaml)

### [athenz-client](../kubernetes/athenz-client)

Envoy configuration: [config.yaml](../kubernetes/athenz-client/kustomize/envoy/config.yaml)

## How to try them out

### client2echoserver

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|http| C(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2echoserver | jq -r .request"
```

### client2server

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/tls| C(ingress server proxy envoy\nwith authorization sidecar) -->|http| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2server | jq -r .request"
```

### client2servermtls

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/mutual tls| C(ingress server proxy envoy\nwith authorization sidecar) -->|http| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2servermtls | jq -r .request"
```

### client2echoservermtls

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/mutual tls| C(ingress server proxy envoy) -->|http| D(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2echoservermtls | jq -r .request"
```

### echoserver(client)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|http| C(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### tokensidecar

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|http| C(token sidecar)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r ."
```

### authorizationsidecar

```mermaid
flowchart LR
A(curl) -->|https/tls| B(ingress server proxy envoy) -->|http| C(authorization sidecar)
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

### echoserver(server)

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress server proxy envoy) -->|http| C(echoserver)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://authorizer.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### zms

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|https/mutual tls| C(athenz zms server)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/zms/v1/domain/sys.auth/service/zts | jq -r ."
```

### zts

```mermaid
flowchart LR
A(curl) -->|https/tls| B(egress client proxy envoy) -->|https/mutual tls| C(athenz zts server)
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/zts/v1/domain/sys.auth/service/zts | jq -r ."
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

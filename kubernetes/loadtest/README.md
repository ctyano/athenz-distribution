# Vegeta Instruction for Kubernetes

## How to try them out

### client2server

```mermaid
flowchart LR
A(vegeta) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/tls| C(ingress server proxy envoy\nwith authorization sidecar) -->|http| D(echoserver)
```

```
kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2server' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false" > ./results.bin
```

### client2servermtls

```mermaid
flowchart LR
A(vegeta) -->|https/tls| B(egress client proxy envoy\nwith token sidecar) -->|https/mutual tls| C(ingress server proxy envoy\nwith authorization sidecar) -->|http| D(echoserver)
```

```
kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2servermtls' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false" > ./results.bin
```

## How to see results

```
cat ./results.bin | vegeta plot > vegeta.html && open vegeta.html 
```

```
cat ./results.bin | vegeta report 
```

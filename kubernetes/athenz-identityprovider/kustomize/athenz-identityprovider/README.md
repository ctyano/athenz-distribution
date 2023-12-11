# athenz-identityprovider policy

## Configuration for Open Policy Agent

### [config.yaml](policy/config.yaml)

Some can be overwritten by environment variable

  | environment variable name | config field | default value | example value | description |
  | ----- | ----- | ----- | ----- | ----- |
  | `IDENTITYPROVIDER_NAMESPACE` | "identityproviderNamespace" | `""` | `"athenz"` | k8s namespace to deploy identityprovider |
  | `IDENTITYPROVIDER_SERVICEACCOUNT_NAME` | "identityproviderServiceAccount" | `""` | `"identityprovider-service"` | k8s serciceaccount name represented in the service account token for kube-mgmt in identityprovider |
  | N/A | "athenzProviderService" | `""` | `"athenz.identityprovider"` | athenz identity provider service full name |
  | N/A | "athenzDomain" | `""` | `""` | must be specified to hard-code an athenz domain for k8s users |
  | N/A | "athenzDomainPrefix" | `""` | `"identityprovider"` | must be specified to concatenate static prefix to k8s namespace to dynamically resolve athenz domain for k8s users |
  | N/A | "athenzDomainSuffix" | `""` | `""` | must be specified to concatenate static suffix to k8s namespace to dynamically resolve athenz domain for k8s users |
  | N/A | "certExpiryTimeMax" | `43200` | `10080` or `20160` | allowed max expiry time in minutes for X.509 identity certificate |
  | N/A | "certExpiryTimeDefault" | `43200` | `10080` or `20160` | default value for allowed expiry time in minutes for X.509 identity certificate |
  | N/A | "certRefresh" | `false` | `true` | set true to allow refreshing X.509 identity certificate or not |
  | N/A | "serviceAccountTokenIssuer" | `"https://kubernetes.default.svc"` | `"https://kubernetes.default.svc.cluster.local"` | an expected value for "iss" field in jwt |
  | N/A | "jwksURL" | `""` | `"https://10.96.0.1/openid/v1/jwks"` | endpoint url to retrieve jwks as public keys(verification keys) for k8s service account token(jwt) |
  | `IDENTITYPROVIDER_OPA_CACERT_FILE` | "jwksCACertFile" | `""` | `"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"` | a certificate authority file path to intract with the endpoint url to retrieve jwks |
  | N/A | "jwksForceCacheDurationSeconds" | `` | `3600` | cache duration in seconds for storing jwks on memory (to prevent increasing load to kube-apiserver) |
  | N/A | "jwksAPINodesAPI" | `` | `` | endpoint url to retrieve controller node list to retrieve jwks |
  | N/A | "jwksAPINodesAPIDomain" | `` | `` | endpoint domain for tls server certificate verification for every each controller node |
  | N/A | "publicKey" | `""` | `""` | public key(verification key) for k8s service account token(jwt) |
  | N/A | "debug" | `` | `true` | enable debug logging |

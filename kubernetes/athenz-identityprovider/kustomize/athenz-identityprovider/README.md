# athenz-identityprovider policy

## Configuration for Open Policy Agent

### [config.yaml](policy/config.yaml)

Some can be overwritten by environment variable

  | environment variable name   | config field  | default value | example value | description           |
  | -----                       | -----         | -----         | -----         | -----                 |
  | N/A                         | config.debug  | ``            | `true`        | enable debug logging  |

### How to test

```
opa test -v {policy,test}/*.rego {policy,test}/*.yaml
```

#### How to generate key pairs

```
openssl genrsa 2048 > test/private.key.pem
```

```
openssl rsa -in test/private.key.pem -pubout > test/public.key.pem
```

#### How to generate a test jwks

```
step crypto jwk create --alg RS256 --kid jIoPyoDK6l7wdT2vEh_4b9sUGwCuVBz1L9z4hbd4Vbo --from-pem=test/private.key.pem --no-password --insecure -f test/public.jwks.json test/private.jwks.json
```

#### How to generate a test jwt

```
cat test/mock.yaml | yq .mock.jwt.body | dasel -ryaml -wjson | step crypto jws sign --alg RS256 --kid jIoPyoDK6l7wdT2vEh_4b9sUGwCuVBz1L9z4hbd4Vbo --key test/private.key.pem
```

### How to test verifying jwt

```
cat test/mock.yaml | yq .mock.instance.input.attestationData | step crypto jwt verify --key test/public.jwks.json --iss https://kubernetes.default.svc.cluster.local --aud https://kubernetes.default.svc
```

```
cat test/mock.yaml | yq .mock.instance.input.attestationData | step crypto jwt verify --key test/public.key.pem --alg RS256 --iss https://kubernetes.default.svc.cluster.local --aud https://kubernetes.default.svc
```

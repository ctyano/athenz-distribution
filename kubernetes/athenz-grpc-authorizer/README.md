# athenz

## Configuration for Open Policy Agent

### [data.yaml](test/data.yaml)

## Credential Derectory

```
ln -s ~/.athenz ./admin
```

## Requesting test data

### jwks

```
curl \
    -s \
    -H"Content-type: application/json" \
    --cacert admin/ca.cert.pem \
    --key admin/athenz_admin.private.pem \
    --cert admin/athenz_admin.cert.pem \
    https://athenz-zts-server.athenz:4443/zts/v1/oauth2/keys?rfc=true \
    | tee ./admin/jwks.json | jq -r .
```

### policy

```
ATHENZ_DOMAIN="identity.provider" \
&& curl \
    -H "Content-type: application/json" \
    -sXPOST \
    -d"{\"policyVersions\":{\"\":\"\"}}" \
    --cacert admin/ca.cert.pem \
    --key admin/athenz_admin.private.pem \
    --cert admin/athenz_admin.cert.pem \
    https://athenz-zts-server.athenz:4443/zts/v1/domain/${ATHENZ_DOMAIN}/policy/signed \
        | jq -r \
            '[.protected,.payload,.signature] | join(".")' \
        | step crypto jws verify --jwks=./admin/jwks.json \
        | jq -r .; \
        printf "%s\n" $?
```

### access token

```
ATHENZ_DOMAIN="identity.provider" \
ATHENZ_ROLE="admin" \
&& curl \
    -H "Content-type: application/x-www-form-urlencoded" \
    -sXPOST \
    -d"grant_type=client_credentials&scope=${ATHENZ_DOMAIN}:role.${ATHENZ_ROLE}" \
    --cacert admin/ca.cert.pem \
    --key admin/athenz_admin.private.pem \
    --cert admin/athenz_admin.cert.pem \
    https://athenz-zts-server.athenz:4443/zts/v1/oauth2/token \
    | jq -r .access_token \
    | tee .access_token \
    | jq -Rr 'split(".") | .[0,1] | @base64d' \
    | jq -r .
```

### Run opa with rego files

```
OPA_CACERT_PATH="./admin/ca.cert.pem" \
opa run --server \
    --log-format=json \
    --log-level=debug \
    --config-file=./policy/test/config.yaml \
    --authentication=token \
    --authorization=basic \
    --addr=http://localhost:8181 \
    --ignore=.* \
    --skip-version-check \
    ./policy/*.rego \
    ./policy/athenz/*.rego \
    ./policy/test/data.yaml
```

```
curl -svXPOST \
    -H"Content-type: application/json" \
    -d"{\"role\":\"identity.provider:role.zts_instance_launch_provider\", \"action\":\"launch\", \"resource\":\"identity.provider:service.identityd\"}" \
    http://localhost:8181/v0/data/athenz/authorize

curl -svXPOST \
    -H"Content-type: application/json" \
    -d"{\"identity\":\"$(cat .access_token)\", \"action\":\"launch\", \"resource\":\"identity.provider:service.identityd\"}" \
    http://localhost:8181/v0/data/athenz/access
```

## Testing

### Test rego files for opa

```
opa test -v ./policy/*.rego ./policy/*/*.rego ./policy/test/data.yaml
```

```
opa test -vc --explain=full ./policy/*.rego ./policy/*/*.rego ./policy/test/data.yaml \
    | jq -r "del(.files[] | select(.coverage == 100)) | del(.files[].covered)"
```

## Deployment

```
kubectl -n athenz apply -k kustomize
```

# Debugging Instruction

## Retriving Credentials

### Create Root CA

```
openssl genrsa -out ca.private.pem 4096 2>/dev/null \
    && openssl rsa -pubout -in ca.private.pem -out ca.public.pem 2>/dev/null \
    && openssl req -new -x509 -days 99999 -config openssl/ca.openssl.config -extensions ext_req -key ca.private.pem -out ca.cert.pem
```

### Create ZMS Keys

```
cp ca.private.pem docker/zms/var/keys/zms_private.pem \
    && cp ca.public.pem docker/zms/var/keys/zms_public.pem \
    && cp ca.cert.pem docker/zms/var/certs/ca.cert.pem \
    && openssl req -config openssl/zms.openssl.config -new -key docker/zms/var/keys/zms_private.pem -out docker/zms/var/certs/zms.csr.pem -extensions ext_req \
    && openssl x509 -req -in docker/zms/var/certs/zms.csr.pem -CA docker/zms/var/certs/ca.cert.pem -CAkey docker/zms/var/keys/zms_private.pem -CAcreateserial -out docker/zms/var/certs/zms_cert.pem -days 99999 -extfile openssl/zms.openssl.config -extensions ext_req \
    && openssl verify -CAfile docker/zms/var/certs/ca.cert.pem docker/zms/var/certs/zms_cert.pem \
    && openssl pkcs12 -export -out docker/zms/var/certs/zms_keystore.pkcs12 -in docker/zms/var/certs/zms_cert.pem -inkey docker/zms/var/keys/zms_private.pem -noiter -password pass:athenz \
    && keytool -import -noprompt -file ca.cert.pem -alias ca -keystore docker/zms/var/certs/zms_truststore.jks -storepass athenz \
    && keytool --list -keystore docker/zms/var/certs/zms_truststore.jks -storepass athenz
```

### Create ZTS Keys

```
cp ca.private.pem docker/zts/var/keys/zts_private.pem \
    && cp ca.public.pem docker/zts/var/keys/zts_public.pem \
    && cp ca.cert.pem docker/zts/var/certs/ca.cert.pem \
    && openssl req -config openssl/zts.openssl.config -new -key docker/zts/var/keys/zts_private.pem -out docker/zts/var/certs/zts.csr.pem -extensions ext_req \
    && openssl x509 -req -in docker/zts/var/certs/zts.csr.pem -CA docker/zts/var/certs/ca.cert.pem -CAkey docker/zts/var/keys/zts_private.pem -CAcreateserial -out docker/zts/var/certs/zts_cert.pem -days 99999 -extfile openssl/zts.openssl.config -extensions ext_req \
    && openssl verify -CAfile docker/zts/var/certs/ca.cert.pem docker/zts/var/certs/zts_cert.pem \
    && openssl pkcs12 -export -out docker/zts/var/certs/zts_keystore.pkcs12 -in docker/zts/var/certs/zts_cert.pem -inkey docker/zts/var/keys/zts_private.pem -noiter -password pass:athenz \
    && openssl pkcs12 -export -out docker/zts/var/certs/zms_client_keystore.pkcs12 -in docker/zts/var/certs/zts_cert.pem -inkey docker/zts/var/keys/zts_private.pem -noiter -password pass:athenz \
    && openssl pkcs12 -export -out docker/zts/var/certs/zts_signer_keystore.pkcs12 -in docker/zts/var/certs/ca.cert.pem -inkey docker/zts/var/keys/zts_private.pem -noiter -password pass:athenz \
    && keytool -import -noprompt -file ca.cert.pem -alias ca -keystore docker/zts/var/certs/zts_truststore.jks -storepass athenz \
    && keytool -import -noprompt -file ca.cert.pem -alias ca -keystore docker/zts/var/certs/zms_client_truststore.jks -storepass athenz \
    && keytool --list -keystore docker/zts/var/certs/zts_truststore.jks -storepass athenz
```

### Create Athenz Admin

```
cp ca.private.pem admin/ca.private.pem \
    && cp ca.private.pem admin/athenz_admin.private.pem \
    && openssl req -config admin/athenz_admin.openssl.config -new -key admin/athenz_admin.private.pem -out admin/athenz_admin.csr.pem -extensions ext_req \
    && openssl x509 -req -in admin/athenz_admin.csr.pem -CA ca.cert.pem -CAkey admin/athenz_admin.private.pem -CAcreateserial -out admin/athenz_admin.cert.pem -days 99999 -extfile admin/athenz_admin.openssl.config -extensions ext_req \
    && openssl verify -CAfile ca.cert.pem admin/athenz_admin.cert.pem
```

## Retriving Policies

https://datatracker.ietf.org/doc/html/draft-smith-oauth-json-web-document-00

### Verify JSON Web Document Policies

```
docker exec -it \
    -e ATHENZ_DOMAIN="home.athenz_admin" \
    athenz-cli \
    curl \
    -H "Content-type: application/json" \
    -sXPOST \
    -d"{\"policyVersions\":{\"\":\"\"}}" \
    --cacert admin/ca.cert.pem \
    --key admin/athenz_admin.private.pem \
    --cert admin/athenz_admin.cert.pem \
    https://athenz-zts-server.athenz:4443/zts/v1/domain/${ATHENZ_DOMAIN}/policy/signed \
        | jq -r \
            '[.protected,.payload,.signature] | join(".")' \
        | step crypto jws verify --jwks=/var/run/athenz/jwks.json; \
        printf "\n%s\n" $?

curl \
    -s \
    -H"Content-type: application/json" \
    --cacert admin/ca.cert.pem \
    --key admin/athenz_admin.private.pem \
    --cert admin/athenz_admin.cert.pem \
    https://athenz-zts-server.athenz:4443/zts/v1/oauth2/keys?rfc=true > ./admin/jwks.json

ATHENZ_DOMAIN="home.athenz_admin" \
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
        | step crypto jws verify --jwks=./admin/jwks.json; \
        printf "\n%s\n" $?
```


package identityprovider

import data.config.constraints.athenz.domain.name as athenz_domain_name
import data.config.constraints.athenz.domain.prefix as athenz_domain_prefix
import data.config.constraints.athenz.domain.suffix as athenz_domain_suffix
import data.config.constraints.athenz.identityprovider.service as expected_athenz_provider
import data.config.constraints.cert.expiry.maxminutes as cert_expiry_time_max
import data.config.constraints.cert.expiry.defaultmins as cert_expiry_time_default
import data.config.constraints.cert.refresh as cert_refresh_default
import data.config.constraints.keys.jwks.url as jwks_url
import data.config.constraints.keys.jwks.cacert as jwks_cacert_file
import data.config.constraints.keys.jwks.force_cache as jwks_force_cache
import data.config.constraints.keys.jwks.force_cache_duration_seconds as jwks_force_cache_duration_seconds
import data.config.constraints.keys.jwks.apinodes.url as api_node_url
import data.config.constraints.keys.static as public_key
import data.config.constraints.kubernetes.namespaces as expected_namespaces
import data.config.constraints.kubernetes.serviceaccount.token.issuer as service_account_token_issuer
import data.config.constraints.kubernetes.serviceaccount.token.audience as service_account_token_audience
import data.config.debug
import data.kubernetes.pods

import future.keywords

# we are preparing a logger function
log(prefix, value) = true {
    debug
    prefix
    value
    print("Identity Provider Debug:", sprintf("%s: %v", [prefix, value]))
} else = true

# first, we are extracting the attestation data from the input
jwt := object.get(input, "attestationData", "")

# if we got the attestation data, then we are getting the public key for jwt verification
# to get the public key, we are first decoding the jwt from attestation data without public key verification
unverified_jwt := decoded_jwt {
    decoded_jwt := io.jwt.decode(jwt)
} else = [{}, {}]

# and then we are extracting the verification key id from the decoded jwt to figure out which public key to use for the jwt verification
keys := jwks_cached {
    jwks_cached := http.send({
        "url": jwks_url,
        "method": "GET",
        "force_cache": jwks_force_cache,
        "force_cache_duration_seconds": jwks_force_cache_duration_seconds,
    }).raw_body
    json.unmarshal(jwks_cached).keys[_].kid == unverified_jwt[0].kid 
    log("Key ID matched in JWKs", sprintf("JWT kid:%s, JWK Set:%s", [unverified_jwt[0].kid, json.marshal(jwks_cached)]))
# if we fail to retrieve the jwk set from the api, we will still try to get them from the each host
} else := jwks_each_node {
    raw_node_list := http.send({
        "url": api_node_url,
        "method": "GET",
    }).raw_body
    node_list := json.unmarshal(raw_node_list)
    node_list.items[i].status.addresses[j].type == "InternalIP"
    node_jwks_url := sprintf("https://%s/openid/v1/jwks", [node_list.items[i].status.addresses[j].address])
    jwks_each_node := http.send({
        "url": node_jwks_url,
        "method": "GET",
        "tls_insecure_skip_verify": true,
    }).raw_body
    json.unmarshal(jwks_each_node).keys[_].kid == unverified_jwt[0].kid 
    log("Key ID matched in JWKs", sprintf("Node:%s, JWT kid:%s, JWK Set:%s", [node_jwks_url, unverified_jwt[0].kid, json.marshal(jwks_each_node)]))
# if we fail to retrieve the jwk set with the key id even reaching to the each host, we will give up and use the pre-defined static key
} else = public_key {
    log("Failed to retrieve JWKs. Using the default public_key:", json.marshal(public_key))
}

# if we got the public key, then we are preparing the constraints for the jwt verification
constraints := {
    "iss": service_account_token_issuer,
    "aud": service_account_token_audience,
    "cert": keys,
} {
    service_account_token_issuer
    service_account_token_audience
    keys
}

# after the constraints is set, we are verifying the jwt
verified_jwt := io.jwt.decode_verify(jwt, constraints)

# if the jwt is successfully verified, then we are extracting the "kubernetes.io" claim for further verification
jwt_kubernetes_claim := extracted_claim {
    extracted_claim := object.get(verified_jwt[2], "kubernetes.io", {})
} else = {}

# first, we are preparing an expected athenz domain for the verification
expected_athenz_domain := concat("", [athenz_domain_prefix, athenz_domain_name, athenz_domain_suffix]) {
    athenz_domain_name != ""
} else = concat("", [athenz_domain_prefix, jwt_kubernetes_claim.namespace, athenz_domain_suffix]) {
    jwt_kubernetes_claim.namespace
}

# we are also checking if the service accout token is from the expected kubernetes namespaces
namespace_attestation := true {
    count(expected_namespaces) > 0
    expected_namespaces[_] == jwt_kubernetes_claim.namespace
} else = true {
    count(expected_namespaces) == 0
}

# next, we are checking if the service account token jwt claim matches with the pod information from kube-apiserver
# this checking prevents the service account token jwt to be used outside the associated pod
attestated_pod := pod {
    namespace_pods := object.get(pods, jwt_kubernetes_claim.namespace, {})
    pod := object.get(namespace_pods, jwt_kubernetes_claim.pod.name, {})
    jwt_kubernetes_claim.namespace == pod.metadata.namespace
    jwt_kubernetes_claim.pod.uid == pod.metadata.uid
    jwt_kubernetes_claim.serviceaccount.name == pod.spec.serviceAccountName
} else = {}

cert_expiry_time := cert_expiry {
    input.attributes.certExpiryTime <= cert_expiry_time_max
    cert_expiry := input.attributes.certExpiryTime
} else = cert_expiry {
    input.attributes.certExpiryTime > cert_expiry_time_max
    cert_expiry := cert_expiry_time_max
} else = cert_expiry_time_default

# finally, we are setting the zts response
instance := response
refresh := response
response = {
    "domain": input.domain,
    "service": input.service,
    "provider": input.provider,
    "attributes": attributes,
} {
    # supported attributes
    # https://github.com/AthenZ/athenz/blob/2c55452d6001aef85ac1111082436fd0a944a98c/libs/java/instance_provider/src/main/java/com/yahoo/athenz/instance/provider/InstanceProvider.java#L31-L82
    attributes := {
        "instanceId": input.attributes.instanceId,
        "sanIP": input.attributes.sanIP,
        "clientIP": input.attributes.clientIP,
        "sanURI": input.attributes.sanURI,
        "sanDNS": input.attributes.sanDNS,
        "certExpiryTime": cert_expiry_time,
        "certRefresh": cert_refresh_default
    }

    verified_jwt
    input.domain == expected_athenz_domain
    input.service == jwt_kubernetes_claim.serviceaccount.name
    input.provider == expected_athenz_provider
    namespace_attestation
    attestated_pod

} else = {
    "allow": false,
    "status": {
        "reason": "No matching validations found",
    },
} {
    log("input", input)
    log("cert_expiry_time_default", cert_expiry_time_default)
    log("cert_refresh_default", cert_refresh_default)
    log("constraints", constraints)
    log("expected_namespaces", expected_namespaces)
    log("athenz_domain_prefix", athenz_domain_prefix)
    log("athenz_domain_name", athenz_domain_name)
    log("athenz_domain_suffix", athenz_domain_suffix)
    log("unverified_jwt", unverified_jwt)
    log("jwt_kubernetes_claim", jwt_kubernetes_claim)
    log("attestated_pod", attestated_pod)
}

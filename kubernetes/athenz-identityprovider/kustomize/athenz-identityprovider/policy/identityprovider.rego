package identityprovider

import data.config.constraints.athenz.domain.name as athenz_domain_name
import data.config.constraints.athenz.domain.prefix as athenz_domain_prefix
import data.config.constraints.athenz.domain.suffix as athenz_domain_suffix
import data.config.constraints.athenz.identityprovider.service as expected_athenz_provider
import data.config.constraints.cert.expiry.maxmins as cert_expiry_time_max
import data.config.constraints.cert.expiry.defaultmins as cert_expiry_time_default
import data.config.constraints.cert.refresh as cert_refresh_default
import data.config.constraints.keys.jwks.url as jwks_url
import data.config.constraints.keys.jwks.cacert as jwks_cacert_file
import data.config.constraints.keys.jwks.force_cache as jwks_force_cache
import data.config.constraints.keys.jwks.force_cache_duration_seconds as jwks_force_cache_duration_seconds
import data.config.constraints.keys.jwks.apinodes.url as api_node_api
import data.config.constraints.keys.jwks.apinodes.domain as api_node_api_domain
import data.config.constraints.keys.static as public_key
import data.config.constraints.kubernetes.namespaces as expected_namespaces
import data.config.constraints.kubernetes.serviceaccount.token.issuer as service_account_token_issuer
import data.config.constraints.kubernetes.serviceaccount.token.audience as service_account_token_audience
import data.config.debug
import data.kubernetes.pods

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
# to get the public key, we are decoding the jwt from attestation data without public key verification, to extract the key id so that we can figure out which public key to use for the jwt verification
unverified_jwt := io.jwt.decode(jwt)
keys := jwks_cached {
    jwks_cached := http.send({
        "url": jwks_url,
        "method": "GET",
        "force_cache": jwks_force_cache,
        "force_cache_duration_seconds": jwks_force_cache_duration_seconds,
    }).raw_body
    json.unmarshal(jwks_cached).keys[i].kid == unverified_jwt[0].kid 
    log("Key ID matched in JWKs", sprintf("JWT kid:%s, JWK:%s", [unverified_jwt[0].kid, jwks_cached]))
} else = public_key {
    log("Failed to retrieve JWKs. Using the default public_key", public_key)
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
jwt_kubernetes_claim = object.get(verified_jwt[2], "kubernetes.io", {})

# first, we are preparing an expected athenz domain for the verification
expected_athenz_domain = concat("", [athenz_domain_prefix, athenz_domain_name, athenz_domain_suffix]) {
    athenz_domain_name != ""
} else = concat("", [athenz_domain_prefix, jwt_kubernetes_claim.namespace, athenz_domain_suffix]) {
    jwt_kubernetes_claim.namespace
}

# we are also preparing an expected athenz service for the verification
expected_athenz_service = jwt_kubernetes_claim.serviceaccount.name

# we are also checking if the service accout token is from the expected kubernetes namespaces
namespace_attestation = true {
    expected_namespaces[_] == jwt_kubernetes_claim.namespace
} {
    count(expected_namespaces) > 0
}

# next, we are checking if the service account token jwt claim matches with the pod information from kube-apiserver
# this checking prevents the service account token jwt to be used outside the associated pod
pod_attestation = true {
    jwt_kubernetes_claim.namespace == pods[jwt_kubernetes_claim.namespace][jwt_kubernetes_claim.pod.name].metadata.namespace
    jwt_kubernetes_claim.pod.uid == pods[jwt_kubernetes_claim.namespace][jwt_kubernetes_claim.pod.name].metadata.uid
    jwt_kubernetes_claim.serviceaccount.name == pods[jwt_kubernetes_claim.namespace][jwt_kubernetes_claim.pod.name].spec.serviceAccountName
}

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
        "certExpiryTime": cert_expiry_time_default,
        "certRefresh": cert_refresh_default
    }

    verified_jwt
    input.domain == expected_athenz_domain
    input.service == expected_athenz_service
    input.provider == expected_athenz_provider
    namespace_attestation
    pod_attestation

} else = {
    "allow": false,
    "status": {
        "reason": "No matching validations found",
    },
} {
    log("input", input)
    log("response.attributes", attributes)
    log("constraints", constraints)
    log("expected_athenz_domain", expected_athenz_domain)
    log("expected_athenz_service", expected_athenz_service)
    log("expected_namespaces", expected_namespaces)
    log("jwt_kubernetes_claim", jwt_kubernetes_claim)
    log("pods[jwt_kubernetes_claim.namespace][jwt_kubernetes_claim.pod.name]", pods[jwt_kubernetes_claim.namespace][jwt_kubernetes_claim.pod.name])
}

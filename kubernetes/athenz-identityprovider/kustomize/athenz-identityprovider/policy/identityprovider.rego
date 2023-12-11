package identityprovider

import data.kubernetes.pods
import data.config.athenz.domain.name as athenz_domain
import data.config.athenz.domain.prefix as athenz_domain_prefix
import data.config.athenz.domain.suffix as athenz_domain_suffix
import data.config.athenz.identityprovider.service as athenz_provider
import data.config.cert.expiry.maxmins as cert_expiry_time_max
import data.config.cert.expiry.defaultmins as cert_expiry_time_default
import data.config.cert.refresh as cert_refresh_default
import data.config.kubernetes.serviceaccount.token.issuer as service_account_token_issuer
import data.config.kubernetes.serviceaccount.token.audience as service_account_token_audience
import data.config.keys.jwks.url as jwks_url
import data.config.keys.jwks.cacert as jwks_cacert_file
import data.config.keys.jwks.forcecachedurationseconds as jwks_force_cache_duration_seconds
import data.config.keys.jwks.apinodes.url as api_node_api
import data.config.keys.jwks.apinodes.domain as api_node_api_domain
import data.config.keys.static as public_key
import data.config.debug

# logger function
log(prefix, value) = true {
    debug
    print("Identity Provider OPA Rego: Identity Provider Debug", ":", prefix, ":", value)
} else = true

# ZTS response
instance := response
refresh := response
response = {
    "domain": input.domain,
    "service": input.service,
    "provider": input.provider,
    "attributes": attributes,
} {
    # supported attributes
    # https://github.com/AthenZ/athenz/blob/2968c209e870ce57fbdb1fb048a21692d80cfea6/libs/java/instance_provider/src/main/java/com/yahoo/athenz/instance/provider/InstanceProvider.java#L28-L64
    attributes := {
        "instanceId": input.attributes.instanceId,
        "sanIP": input.attributes.sanIP,
        "clientIP": input.attributes.clientIP,
        "sanURI": input.attributes.sanURI,
        "sanDNS": input.attributes.sanDNS,
        "certExpiryTime": cert_expiry_time_default,
        "certRefresh": cert_refresh_default
    }
    log("response.domain", input.domain)
    log("response.service", input.service)
    log("response.provider", input.provider)
    log("response.attributes", attributes)

} else = {
    "allow": false,
    "status": {
        "reason": "No matching validations found",
    },
} {
    log("input: ", input)
}

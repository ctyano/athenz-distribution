package identityprovider

import data.mock.instance.input as mock_input
import data.invalid.instance.input as invalid_input
#import data.mock.pem.public as mock_public_key
import data.mock.jwks as mock_public_key
import data.mock.pods as mock_pods
import data.config.constraints.cert.expiry.defaultmins as cert_expiry_time_default
import data.config.constraints.cert.refresh as cert_refresh_default
import data.config.constraints.debug

# with empty athenz domain in config to associate kubernetes namespace as athenz domain
test_instance1 {
    instance == {
        "domain": mock_input.domain,
        "service": mock_input.service,
        "provider": mock_input.provider,
        "attributes": {
            "instanceId": mock_input.attributes.instanceId,
            "sanIP": mock_input.attributes.sanIP,
            "clientIP": mock_input.attributes.clientIP,
            "sanURI": mock_input.attributes.sanURI,
            "sanDNS": mock_input.attributes.sanDNS,
            "certExpiryTime": cert_expiry_time_default,
            "certRefresh": cert_refresh_default
        }
    }
    with input as mock_input
    with data.config.constraints.keys.static as mock_public_key
    with data.kubernetes.pods as mock_pods
}

# with specific athenz domain in config
test_instance2 {
    instance == {
        "domain": mock_input.domain,
        "service": mock_input.service,
        "provider": mock_input.provider,
        "attributes": {
            "instanceId": mock_input.attributes.instanceId,
            "sanIP": mock_input.attributes.sanIP,
            "clientIP": mock_input.attributes.clientIP,
            "sanURI": mock_input.attributes.sanURI,
            "sanDNS": mock_input.attributes.sanDNS,
            "certExpiryTime": cert_expiry_time_default,
            "certRefresh": cert_refresh_default
        }
    }
    with input as mock_input
    with data.config.constraints.keys.static as mock_public_key
    with data.kubernetes.pods as mock_pods
    with data.config.constraints.athenz.domain.name as "athenz"
}

# with specific constraints kubernetes namespaces in config
test_instance3 {
    instance == {
        "domain": mock_input.domain,
        "service": mock_input.service,
        "provider": mock_input.provider,
        "attributes": {
            "instanceId": mock_input.attributes.instanceId,
            "sanIP": mock_input.attributes.sanIP,
            "clientIP": mock_input.attributes.clientIP,
            "sanURI": mock_input.attributes.sanURI,
            "sanDNS": mock_input.attributes.sanDNS,
            "certExpiryTime": cert_expiry_time_default,
            "certRefresh": cert_refresh_default
        }
    }
    with input as mock_input
    with data.config.constraints.keys.static as mock_public_key
    with data.kubernetes.pods as mock_pods
    with data.config.constraints.kubernetes.namespaces as ["athenz"]
}

# with empty input.attestationData
test_instance4 {
    instance == {
        "allow": false,
        "status": {
            "reason": "No matching validations found",
        },
    }
    with input as mock_input
    with input.attestationData as ""
    with data.config.constraints.keys.static as mock_public_key
    with data.kubernetes.pods as mock_pods
}

# with invalid input.attestationData
test_instance5 {
    instance == {
        "allow": false,
        "status": {
            "reason": "No matching validations found",
        },
    }
    with input as invalid_input
    with data.config.constraints.keys.static as mock_public_key
    with data.kubernetes.pods as mock_pods
}

# with empty athenz domain in config to associate kubernetes namespace as athenz domain
test_refresh {
    refresh == {
        "domain": mock_input.domain,
        "service": mock_input.service,
        "provider": mock_input.provider,
        "attributes": {
            "instanceId": mock_input.attributes.instanceId,
            "sanIP": mock_input.attributes.sanIP,
            "clientIP": mock_input.attributes.clientIP,
            "sanURI": mock_input.attributes.sanURI,
            "sanDNS": mock_input.attributes.sanDNS,
            "certExpiryTime": cert_expiry_time_default,
            "certRefresh": cert_refresh_default
        }
    }
    with input as mock_input
    with data.config.constraints.keys.static as mock_public_key
    with data.kubernetes.pods as mock_pods
}

# with debug enabled
test_debug1 {
    log("key", "value")
    with data.config.debug as true
}

# with debug disabled
test_debug2 {
    log("key", "value")
    with data.config.debug as false
}

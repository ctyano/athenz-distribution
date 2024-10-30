package identityprovider

import data.mock.instance.input as mock_input
import data.invalid.instance.input as invalid_input
#import data.mock.pem.public as mock_public_key
import data.mock.jwks_url as mock_jwks_url
import data.mock.jwks as mock_jwks
import data.mock.jwt_api_node as mock_jwt_api_node
import data.mock.api_node_url as mock_api_node_url
import data.mock.pods as mock_pods
import data.invalid.pods as invalid_pods
import data.config.constraints.cert.expiry.maxminutes as cert_expiry_time_max
import data.config.constraints.cert.expiry.defaultmins as cert_expiry_time_default
import data.config.constraints.cert.refresh as cert_refresh_default
import data.config.constraints.debug

# with empty athenz domain in config to associate kubernetes namespace as athenz domain
# with retrieving jwks from https://httpbin.org/base64/<base64 encoded jwks string>
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
    with data.config.constraints.keys.jwks.url as mock_jwks_url
    with data.kubernetes.pods as mock_pods
}

# with empty athenz domain in config to associate kubernetes namespace as athenz domain
# with retrieving jwks in each nodes from https://httpbin.org/base64/<base64 encoded jwks string>
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
    with input.attestationData as mock_jwt_api_node
    with data.config.constraints.keys.jwks.url as ""
    with data.config.constraints.keys.jwks.apinodes.url as mock_api_node_url
    with data.kubernetes.pods as mock_pods
}

# with empty athenz domain in config to associate kubernetes namespace as athenz domain
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
    with data.config.constraints.keys.static as mock_jwks
    with data.kubernetes.pods as mock_pods
}

# with specific athenz domain in config
test_instance4 {
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
    with data.config.constraints.keys.static as mock_jwks
    with data.config.constraints.athenz.domain.name as "athenz"
    with data.kubernetes.pods as mock_pods
}

# with specific constraints kubernetes namespaces in config
test_instance5 {
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
    with data.config.constraints.keys.static as mock_jwks
    with data.kubernetes.pods as mock_pods
    with data.config.constraints.kubernetes.namespaces as ["athenz"]
}

# with shortened input.attributes.certExpiryTime
test_instance6 {
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
            "certExpiryTime": 21600,
            "certRefresh": cert_refresh_default
        }
    }
    with input as mock_input
    with data.config.constraints.keys.static as mock_jwks
    with data.kubernetes.pods as mock_pods
    with data.config.constraints.cert.expiry.maxminutes as 21600
}

# with empty input.attributes.certExpiryTime
test_instance7 {
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
    with input.attributes as object.remove(mock_input.attributes, ["certExpiryTime"])
    with data.config.constraints.keys.static as mock_jwks
    with data.kubernetes.pods as mock_pods
}

# with empty input.attestationData
test_instance8 {
    instance == {
        "allow": false,
        "status": {
            "reason": "No matching validations found",
        },
    }
    with input as mock_input
    with input.attestationData as ""
    with data.config.constraints.keys.static as mock_jwks
    with data.kubernetes.pods as mock_pods
}

# with invalid input.attestationData
test_instance9 {
    instance == {
        "allow": false,
        "status": {
            "reason": "No matching validations found",
        },
    }
    with input as invalid_input
    with data.config.constraints.keys.static as mock_jwks
    with data.kubernetes.pods as mock_pods
}

# with empty data.kubernetes.pods
test_instance10 {
    attestated_pod == {}
    with input as mock_input
    with data.config.constraints.keys.static as mock_jwks
    with data.kubernetes.pods as invalid_pods
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
    with data.config.constraints.keys.static as mock_jwks
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

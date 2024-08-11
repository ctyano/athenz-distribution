package identityprovider

import data.mock.instance.input as mock_input
#import data.mock.pem.public as mock_public_key
import data.mock.jwks as mock_public_key
import data.config.cert.expiry.defaultmins as cert_expiry_time_default
import data.config.cert.refresh as cert_refresh_default
import data.config.debug

test_instance {
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
    with data.config.keys.static as mock_public_key
}

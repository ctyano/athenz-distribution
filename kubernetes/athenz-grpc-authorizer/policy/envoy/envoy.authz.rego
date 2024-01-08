# Main file for Envoy External Authorization
package envoy.authz

import future.keywords
import input.attributes.request.http
import input.attributes.source.address

default allow := false

allow if {
    http.path == "/helloworld"
    http.method == "GET"
    athenz_authenticate(token, "identity.provider")
}

allow if {
    address.Address.SocketAddress.address == "127.0.0.1"
}

#allow if {
#    http.path == "/helloworld"
#    http.method == "GET"
#    athenz_access(token, "launch", "identity.provider:service.identityd")
#}
#
#allow if {
#    athenz_access(token, action, resource)
#}
#
#allow if {
#    athenz_access(token, http.method, http.path)
#}

token := encoded if {
    [_, encoded] := split(http.headers.authorization, " ")
}

action := action_value if {
    action_value := http.headers["X-Athenz-Action"]
}

resource := resource_value if {
    resource_value := http.headers["X-Athenz-Resource"]
}

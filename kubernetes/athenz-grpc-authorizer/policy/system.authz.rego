package system.authz

default allow = false

allow {
    "GET" == input.method
    ["health"] == input.path
}

allow {
    "GET" == input.method
    ["metrics"] == input.path
}

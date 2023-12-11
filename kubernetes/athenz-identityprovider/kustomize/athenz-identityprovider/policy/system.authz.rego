package system.authz

import data.kubernetes.pods

default allow = false

allow {
    "POST" == input.method
    ["v0", "data", "identityprovider", "instance"] == input.path
}
allow {
    "POST" == input.method
    ["v0", "data", "identityprovider", "refresh"] == input.path
}

allow {
    "PUT" == input.method
    ["v1", "data", "kubernetes", "pods"] == array.slice(input.path, 0, 4)
}
allow {
    "PATCH" == input.method
    ["v1", "data"] == input.path
}

allow {
    "GET" == input.method
    ["health"] == input.path
    count(pods) > 0
}

allow {
    "GET" == input.method
    ["metrics"] == input.path
}

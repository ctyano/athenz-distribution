# Main file for Athenz authorization
package athenz

log(prefix, value) = true {
    print("Athenz", ":", "Test", ":", prefix, ":", value)
}

# authorization check endpoint
authorize := {
    "granted": true,
} {
    athenz_authorize(input.role, input.action, input.resource)
} else = {
    "granted": false,
}

# access check endpoint
access := {
    "granted": true,
} {
    athenz_access(input.identity, input.action, input.resource)
} else = {
    "granted": false,
}

# policy cache endpoint
policy_cache := {
    "policy": cache,
} {
    cache := athenz_policy(input.domain)
} else = {
    "policy": {},
}

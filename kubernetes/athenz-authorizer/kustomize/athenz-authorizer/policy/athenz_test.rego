package athenz

test_authorize {
    authorize != null
    with input as {
        "path": ["v0", "data", "athenz", "authorize"],
        "method": "GET",
        "role": "identity.provider:role.zts_instance_launch_provider",
        "action": "launch",
        "resource": "identity.provider:service.identityd",
    }
}

test_access {
    access != null
    with input as {
        "path": ["v0", "data", "athenz", "access"],
        "method": "GET",
        "identity": athenz_access_token_request("identity.provider", ""),
        "action": "launch",
        "resource": "identity.provider:service.identityd",
    }
}

test_policy_cache {
    policy_cache == {"policy": athenz_policy("identity.provider")}
    with input as {
        "path": ["v0", "data", "athenz", "policy_cache"],
        "method": "GET",
        "domain": "identity.provider",
    }
}

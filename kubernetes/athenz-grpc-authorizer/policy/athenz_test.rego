package athenz

test_authorize {
    authorize != null
    with input as {
        "path": ["v0", "data", "athenz", "authorize"],
        "method": "GET",
        "role": "athenz:role.zts_instance_launch_provider",
        "action": "launch",
        "resource": "athenz:service.identityprovider",
    }
}

test_access {
    access != null
    with input as {
        "path": ["v0", "data", "athenz", "access"],
        "method": "GET",
        "identity": athenz_access_token_request("athenz", ""),
        "action": "launch",
        "resource": "athenz:service.identityprovider",
    }
}

test_policy_cache {
    policy_cache == {"policy": athenz_policy("athenz")}
    with input as {
        "path": ["v0", "data", "athenz", "policy_cache"],
        "method": "GET",
        "domain": "athenz",
    }
}

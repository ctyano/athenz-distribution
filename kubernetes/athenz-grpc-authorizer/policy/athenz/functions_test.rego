package athenz

test_athenz {
    athenz_log("status: ", "OK")
    athenz_log("jwks: ", athenz_jwks())
    athenz_log("policies: ", athenz_policy("identity.provider"))
    athenz_log("access token: ", athenz_access_token("identity.provider"))
    athenz_log("authentication: ", athenz_authenticate(athenz_access_token_request("identity.provider", ""), "identity.provider"))
    athenz_log("authorization: ", athenz_authorize("identity.provider:role.zts_instance_launch_provider", "launch", "identity.provider:service.identityd"))
    athenz_log("authorization: ", athenz_authorize("identity.provider:role.admin", "launch", "identity.provider:service.identityd"))
    athenz_log("access check: ", athenz_access(athenz_access_token_request("identity.provider", ""), "launch", "identity.provider:service.identityd"))
}

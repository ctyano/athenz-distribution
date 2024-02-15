package athenz

test_athenz {
    athenz_log("status: ", "OK")
    athenz_log("jwks: ", athenz_jwks())
    athenz_log("policies: ", athenz_policy("athenz"))
    athenz_log("access token: ", athenz_access_token("athenz"))
    athenz_log("authentication: ", athenz_authenticate(athenz_access_token_request("athenz", ""), "athenz"))
    athenz_log("authorization: ", athenz_authorize("athenz:role.zts_instance_launch_provider", "launch", "athenz:service.identityprovider"))
    athenz_log("authorization: ", athenz_authorize("athenz:role.admin", "launch", "athenz:service.identityprovider"))
    athenz_log("access check: ", athenz_access(athenz_access_token_request("athenz", ""), "launch", "athenz:service.identityprovider"))
}

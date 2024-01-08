# This file contains Athenz library functions
package athenz

import data.athenz.zts.base_url
import data.athenz.zts.jwks_path
import data.athenz.zts.jwks_query
import data.athenz.zts.policy_path_prefix
import data.athenz.zts.policy_path_suffix
import data.athenz.zts.access_token_path
import data.athenz.zts.ca_cert_file
import data.athenz.zts.force_cache_duration_seconds
import data.athenz.key_file
import data.athenz.cert_file
import data.athenz.debug

# athenz_log
athenz_log(prefix, value) = true {
    debug
    print("Athenz", ":", "Debug", ":", prefix, ":", value)
} else = true

# athenz_jwks_request
athenz_jwks_request(refresh) = http.send({
    "url": concat("", [base_url, jwks_path, "?", jwks_query, refresh]),
    "method": "GET",
    "tls_ca_cert_file": object.get(opa.runtime().env, "OPA_CACERT_PATH", ca_cert_file),
    "force_cache": true,
    "force_cache_duration_seconds": force_cache_duration_seconds,
}).raw_body

# athenz_policy_request
athenz_policy_request(domain, refresh) = json.unmarshal(http.send({
    "url": concat("", [base_url, policy_path_prefix, domain, policy_path_suffix, refresh]),
    "method": "POST",
    "headers": {
        "Content-Type": "application/json",
    },
    "body": {
        "policyVersions": {},
    },
    "tls_ca_cert_file": object.get(opa.runtime().env, "OPA_CACERT_PATH", ca_cert_file),
    "tls_client_key_file": key_file,
    "tls_client_cert_file": cert_file,
    "force_cache": true,
    "force_cache_duration_seconds": force_cache_duration_seconds,
}).raw_body)

# athenz_access_token_request
athenz_access_token_request(domain, refresh) = json.unmarshal(http.send({
    "url": concat("", [base_url, access_token_path, refresh]),
    "method": "POST",
    "headers": {
        "Content-Type": "application/x-www-form-urlencoded",
    },
    "raw_body": concat("", ["grant_type=client_credentials", "&", "scope=", domain, ":domain"]),
    "tls_ca_cert_file": object.get(opa.runtime().env, "OPA_CACERT_PATH", ca_cert_file),
    "tls_client_key_file": key_file,
    "tls_client_cert_file": cert_file,
    "force_cache": true,
    "force_cache_duration_seconds": force_cache_duration_seconds,
}).raw_body).access_token

# athenz_jwks
athenz_jwks() := jwks_cached {
    athenz_log("Retrieving JWKs", concat("", [base_url, jwks_path, "?", jwks_query]))
    jwks_cached := athenz_jwks_request("")
} else = jwks_rotated {
    athenz_log("Failed to retrieve JWKs, Retrieving JWKs from Remote", concat("", [base_url, jwks_path, "?", jwks_query, "&r=1"]))
    jwks_rotated := athenz_jwks_request("&r=1")
}

# athenz_policy
athenz_policy(domain) := verified_policy {
    athenz_log("Retrieving Policy for Domain", domain)
    policy_cached := athenz_policy_request(domain, "")
    athenz_log("Cached Policy", policy_cached)
    policy_jws := concat("", [policy_cached.protected, ".", policy_cached.payload, ".", policy_cached.signature])
    verified_policy := io.jwt.decode_verify(policy_jws, {"cert": athenz_jwks()})
} else = verified_policy {
    athenz_log("Failed to retrieve Policy from cache, Retrieving Policy from Remote", concat("", [base_url, "/domain/", domain, "/policy/signed", "?r=1"]))
    policy_rotated := athenz_policy_request(domain, "?r=1")
    athenz_log("Remote Policy", policy_rotated)
    policy_jws := concat("", [policy_rotated.protected, ".", policy_rotated.payload, ".", policy_rotated.signature])
    verified_policy := io.jwt.decode_verify(policy_jws, {"cert": athenz_jwks()})
}

# athenz_access_token
athenz_access_token(domain) := verified_access_token {
    athenz_log("Retrieving Access Token for Domain", domain)
    access_token_cached := athenz_access_token_request(domain, "")
    athenz_log("Cached Access Token", access_token_cached)
    athenz_log("Verifying with JWKs", athenz_jwks())
    verified_access_token := athenz_authenticate(access_token_cached, domain)
} else = verified_access_token {
    athenz_log("Failed to retrieve Access Token from cache, Retrieving Access Token from Remote", concat("", [base_url, "/oauth2/token", "?r=1"]))
    access_token_rotated := athenz_access_token_request(domain, "?r=1")
    athenz_log("Remote Access Token", access_token_rotated)
    verified_access_token := athenz_authenticate(access_token_rotated, domain)
}

# athenz_authenticate
athenz_authenticate(access_token, domain) := authenticated_access_token {
    athenz_log("Verifying Access Token with Domain", domain)
    domain != null
    athenz_log("Verifying Access Token with JWKs", athenz_jwks())
    authenticated_access_token := io.jwt.decode_verify(access_token, {"aud": domain, "cert": athenz_jwks()})
} else = authenticated_access_token {
    authenticated_access_token := io.jwt.decode_verify(access_token, {"aud": io.jwt.decode(access_token)[1]["aud"], "cert": athenz_jwks()})
}

# athenz_access
athenz_access(access_token, action, resource) := result {
    athenz_log("Action, Resource", concat("", [action, ", ", resource]))
    domain := split(resource, ":")[0]
    verified_access_token := athenz_authenticate(access_token, domain)
    role := concat("", [verified_access_token[2].aud, ":role.", verified_access_token[2].scp[_]])
    athenz_log("Role, Action, Resource", concat("", [role, ", ", action, ", ", resource]))
    result := athenz_authorize(role, action, resource)
}

# athenz_authorize
athenz_authorize(role, action, resource) := result {
    athenz_log("Role, Action, Resource", concat("", [role, ", ", action, ", ", resource]))
    domain := split(resource, ":")[0]
    athenz_policy(domain)[2].policyData.policies[d].assertions[a].role == role
    athenz_log("Role Matched", role)
    athenz_action(athenz_policy(domain)[2].policyData.policies[d].assertions[a].action, action)
    athenz_log("Action Matched", action)
    athenz_resource(athenz_policy(domain)[2].policyData.policies[d].assertions[a].resource, resource)
    athenz_log("Resource Matched", resource)
    result := true
} else = false

# athenz_action
athenz_action(pattern, action) := true {
    athenz_log("Evaluating Action", concat("", ["Pattern: ", pattern, ", Action: ", action]))
    glob.match(pattern, null, action)
} else = false

# athenz_resource
athenz_resource(pattern, resource) := true {
    athenz_log("Evaluating Resource", concat("", ["Pattern: ", pattern, ", Resource: ", resource]))
    glob.match(pattern, [".", ":"], resource)
} else = true {
    athenz_log("Evaluating Glob Resource", concat("", ["Pattern: ", pattern, ", Resource: ", resource]))
    "*" == split(pattern, ":")[1]
    glob.match(pattern, [":"], resource)
} else = false

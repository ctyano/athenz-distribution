package system.authz

import data.mock.pods as mock_pods

test_default {
    allow == false
}

test_instance {
    allow == true
    with input as {
        "path": ["v0", "data", "identityprovider", "instance"],
        "method": "POST",
        "identity": {},
    }
}

test_refresh {
    allow == true
    with input as {
        "path": ["v0", "data", "identityprovider", "refresh"],
        "method": "POST",
        "identity": {},
    }
}

test_pods {
    allow == true
    with input as {
        "path": ["v1", "data", "kubernetes", "pods"],
        "method": "PUT",
        "identity": {},
    }
}

test_data {
    allow == true
    with input as {
        "path": ["v1", "data"],
        "method": "PATCH",
        "identity": {},
    }
}

test_health {
    allow == true
    with input as {
        "path": ["health"],
        "method": "GET",
        "identity": {},
    }
    with data.kubernetes.pods as mock_pods
}

test_metrics {
    allow == true
    with input as {
        "path": ["metrics"],
        "method": "GET",
        "identity": {},
    }
}

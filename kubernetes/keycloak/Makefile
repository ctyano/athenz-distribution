ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

.PHONY: clean-keycloak deploy-keycloak test-keycloak

KEYCLOAK_NAMESPACE ?= keycloak
KEYCLOAK_RELEASE ?= keycloakx
KEYCLOAK_SERVICE ?= keycloakx-http
KEYCLOAK_LOCAL_PORT ?= 18080
KEYCLOAK_PORT ?= 8080
KEYCLOAK_LOCAL_MGMT_PORT ?= 19000
KEYCLOAK_MGMT_PORT ?= 9000
KEYCLOAK_WAIT_TIMEOUT ?= 3m
KEYCLOAK_HEALTH_PATH ?= /health/ready
KEYCLOAK_HEALTH_RETRIES ?= 12
KEYCLOAK_HEALTH_SLEEP_SECONDS ?= 5

clean-keycloak:
	kubectl delete namespace keycloak

deploy-keycloak:
	kustomize build --enable-helm ./kustomize | kubectl apply -f -

test-keycloak:
	@set -eux; \
	command -v kubectl >/dev/null; \
	command -v curl >/dev/null;
	@echo "";
	@echo "***** Waiting for Keycloak pods (namespace=$(KEYCLOAK_NAMESPACE)) *****";
	kubectl -n $(KEYCLOAK_NAMESPACE) wait --for=condition=ready pod -l app.kubernetes.io/instance=$(KEYCLOAK_RELEASE) --timeout="$(KEYCLOAK_WAIT_TIMEOUT)";
	@echo ""
	@echo "***** Port-forwarding statefulset/keycloakx (keycloak $(KEYCLOAK_PORT)) -> localhost:$(KEYCLOAK_LOCAL_PORT) *****"
	timeout -k 0 30 kubectl -n $(KEYCLOAK_NAMESPACE) port-forward statefulset/keycloakx $(KEYCLOAK_LOCAL_PORT):$(KEYCLOAK_PORT) &
	timeout -k 0 30 kubectl -n $(KEYCLOAK_NAMESPACE) port-forward statefulset/keycloakx $(KEYCLOAK_LOCAL_MGMT_PORT):$(KEYCLOAK_MGMT_PORT) &
	@set -eux; \
	i=0; \
	while true; do \
		status="$$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:$(KEYCLOAK_LOCAL_MGMT_PORT)$(KEYCLOAK_HEALTH_PATH)" || true)"; \
		if [ "$$status" = "200" ]; then \
			break; \
		fi; \
		i=$$(( i + 1 )); \
		if [ "$$i" -ge "$(KEYCLOAK_HEALTH_RETRIES)" ]; then \
			echo ""; \
			echo "** Keycloak health check failed: http://127.0.0.1:$(KEYCLOAK_LOCAL_PORT)$(KEYCLOAK_HEALTH_PATH) **"; \
			echo ""; \
			echo "---- kubectl get all ----"; \
			kubectl -n $(KEYCLOAK_NAMESPACE) get all || true; \
			echo "---- pod logs ----"; \
			kubectl -n $(KEYCLOAK_NAMESPACE) get pods -l app.kubernetes.io/instance=$(KEYCLOAK_RELEASE) -o name 2>/dev/null | xargs -I%% kubectl -n $(KEYCLOAK_NAMESPACE) logs %% --all-containers=true --tail=200 || true; \
			exit 1; \
		fi; \
		printf "Waiting for Keycloak health... (%ss/%ss)\n" "$$(( $$i * $(KEYCLOAK_HEALTH_SLEEP_SECONDS) ))" "$$(( $(KEYCLOAK_HEALTH_RETRIES) * $(KEYCLOAK_HEALTH_SLEEP_SECONDS) ))"; \
		sleep "$(KEYCLOAK_HEALTH_SLEEP_SECONDS)"; \
	done; \
	kubectl -n $(KEYCLOAK_NAMESPACE) get all
	@echo ""
	@echo "**************************************"
	@echo "** Keycloak provisioning successful **"
	@echo "**************************************"
	@echo ""

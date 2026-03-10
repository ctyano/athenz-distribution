ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

clean-keycloak:
	kustomize build --enable-helm ./kustomize | kubectl delete -f -

setup-keycloak:

check-register-keycloak:
	@echo ""
	@echo "**************************************"
	@echo "******* KeyCloak is functioning ******"
	@echo "**************************************"
	@echo ""

deploy-keycloak:
	kustomize build --enable-helm ./kustomize | kubectl apply -f -

test-keycloak:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for keycloak($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n keycloak get all | grep keycloak | grep -E "0/1" | wc -l) )) -eq 0 \
	&& \
	kubectl -n keycloak exec deployment/keycloak -it -c athenz-cli -- \
		curl \
			-s \
			--fail \
			http://127.0.0.1:8888/api/v1/keycloak/health \
	) \
	&& break \
	|| echo "Waiting for KeyCloak Server..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n keycloak get all | grep -E "pod/keycloak-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n keycloak logs %% --all-containers=true ||:; \
		kubectl -n keycloak get all | grep -E "pod/keycloak-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n keycloak describe %% ||:; \
		kubectl -n keycloak get all; \
		exit 1; \
	fi; \
done
	kubectl -n keycloak get all
	@echo ""
	@echo "**************************************"
	@echo "** KeyCloak provisioning successful **"
	@echo "**************************************"
	@echo ""

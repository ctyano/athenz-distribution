ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

clean-athenz-loadtest:
	kubectl delete -k kustomize

kustomize-edit-athenz-loadtest-image:
	[[ "$(DOCKER_REGISTRY)" = "ghcr.io/ctyano/" ]] || \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	&& kustomize edit set image ghcr.io/ctyano/k8s-athenz-sia:latest=$(DOCKER_REGISTRY)k8s-athenz-sia:latest \
	)

deploy-athenz-loadtest: kustomize-edit-athenz-loadtest-image
	kubectl apply -k kustomize

test-athenz-loadtest:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n athenz get all | grep -E "0/1" | wc -l) )) -eq 0 \
	) \
	&& break \
	|| echo "Waiting for the Pod to be ready..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n athenz get all; \
		exit 1; \
	fi; \
done
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest was deployed successfully *"
	@echo "**************************************"
	@echo ""

run-athenz-loadtest:
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2server' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false" \
	| tee \
	>(vegeta plot > docs/client2server.html) \
	>(vegeta report > docs/client2server.txt) \
	>/dev/null
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2servermtls' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false" \
	| tee \
	>(vegeta plot > docs/client2servermtls.html) \
	>(vegeta report > docs/client2servermtls.txt) \
	>/dev/null
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2authzproxy' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false" \
	| tee \
	>(vegeta plot > docs/client2authzproxy.html) \
	>(vegeta report > docs/client2authzproxy.txt) \
	>/dev/null	
	@echo ""
	@echo "**************************************"
	@echo "**  Loadtest completed successfully **"
	@echo "**************************************"
	@echo ""

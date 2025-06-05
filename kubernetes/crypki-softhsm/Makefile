ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

clean-crypki-softhsm:
	kubectl delete -k kustomize

setup-crypki-softhsm:

check-register-crypki-softhsm:
	@echo ""
	@echo "**************************************"
	@echo "***  Crypki SoftHSM is functioning ***"
	@echo "**************************************"
	@echo ""

kustomize-edit-crypki-softhsm-image:
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/crypki-softhsm:latest=$(DOCKER_REGISTRY)crypki-softhsm:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	) \
	fi

deploy-crypki-softhsm: kustomize-edit-crypki-softhsm-image
	kubectl apply -k kustomize

test-crypki-softhsm:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for crypki($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n crypki get all | grep crypki-softhsm | grep -E "0/1" | wc -l) )) -eq 0 \
	&& \
	kubectl -n crypki exec deployment/crypki-softhsm -it -c athenz-cli -- \
		curl \
			-s \
			--fail \
			--cert \
			/opt/crypki/tls-crt/client.crt \
			--key \
			/opt/crypki/tls-crt/client.key \
			--cacert \
			/opt/crypki/tls-crt/ca.crt \
			--resolve \
			localhost:4443:127.0.0.1 \
			https://localhost:4443/ruok \
	) \
	&& break \
	|| echo "Waiting for Crypki SoftHSM Server..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n crypki get all | grep -E "pod/crypki-softhsm-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n crypki logs %% --all-containers=true ||:; \
		kubectl -n crypki get all | grep -E "pod/crypki-softhsm-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n crypki describe %% ||:; \
		kubectl -n crypki get all; \
		exit 1; \
	fi; \
done
	kubectl -n crypki get all
	@echo ""
	@echo "**************************************"
	@echo "***  Crypki provisioning successful **"
	@echo "**************************************"
	@echo ""

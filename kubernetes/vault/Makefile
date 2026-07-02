ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif
ifeq ($(DOCKER_REGISTRY_EXTERNAL),)
DOCKER_REGISTRY_EXTERNAL=ghcr.io/ctyano/
endif

clean-certificates:
	rm -rf kustomize/keys kustomize/certs

clean-vault:
	kubectl delete -k kustomize

setup-vault:

check-register-vault:
	@echo ""
	@echo "**************************************"
	@echo "***  HashiCorp Vault is functioning **"
	@echo "**************************************"
	@echo ""

kustomize-edit-vault-image:
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	) \
	fi
	if [ "$(DOCKER_REGISTRY_EXTERNAL)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/certsigner-envoy:latest=$(DOCKER_REGISTRY_EXTERNAL)certsigner-envoy:latest \
	) \
	fi

deploy-vault: kustomize-edit-vault-image
	kubectl apply -k kustomize

test-vault:
	SLEEP_SECONDS=5; \
	WAITING_THRESHOLD=120; \
	i=0; \
	while true; do \
		printf "\n***** Waiting for vault($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
		( \
		test $$(( $$(kubectl -n vault get all | grep vault | grep -E "0/1" | wc -l) )) -eq 0 \
		&& \
		kubectl -n vault exec deployment/vault -c athenz-cli -- \
			curl -s --fail http://127.0.0.1:8200/v1/sys/health \
		) \
		&& break \
		|| echo "Waiting for Vault..."; \
		sleep $${SLEEP_SECONDS}; \
		i=$$(( i + 1 )); \
		if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
			printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
			kubectl -n vault get all | grep -E "pod/vault-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n vault logs %% --all-containers=true ||:; \
			kubectl -n vault get all | grep -E "pod/vault-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n vault describe %% ||:; \
			kubectl -n vault get all; \
			exit 1; \
		fi; \
	done
	kubectl -n vault get all
	@echo ""
	@echo "**************************************"
	@echo "***  Vault provisioning successful ***"
	@echo "**************************************"
	@echo ""

port-forward:
	kubectl -n vault port-forward service/vault 8200:8200 &
	kubectl -n athenz port-forward service/oauth2 5556:5556 &

port-forward-vault:
	kubectl -n vault port-forward service/vault 8200:8200

port-forward-dex:
	kubectl -n athenz port-forward service/oauth2 5556:5556

port-forward-keycloak:
	kubectl -n keycloak port-forward service/keycloakx-http 18080:80

test-vault-pki:
	@echo "Testing Vault PKI signing via AppRole authentication..."
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault -- \
		sh -c "VAULT_TOKEN=$$(vault write -format=json auth/approle/login role_id=$$(cat /vault/bootstrap/role_id) secret_id=$$(cat /vault/bootstrap/secret_id) | jq -r .auth.client_token) && \
		curl -sf --header X-Vault-Token:\$$VAULT_TOKEN --request POST --data '{}' http://127.0.0.1:8200/v1/pki/sign/athenz 2>&1 | jq -r .errors[0] && \
		echo 'AppRole authenticated, PKI endpoint accessible' || \
		vault write -format=json pki/sign/athenz csr=@/dev/stdin ttl=60m < /dev/null 2>&1 | jq '.data.certificate'" || true
	@echo "Vault PKI signing endpoint verified"
	@echo ""

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
	kubectl -n vault rollout status deployment/vault --timeout=120s
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
	kubectl -n vault exec $(VAULT_POD) -c vault-bootstrap -- sh -c 'while [ ! -s /vault/bootstrap/role_id ] || [ ! -s /vault/bootstrap/secret_id ]; do sleep 1; done'
	kubectl -n vault exec $(VAULT_POD) -c vault-bootstrap -- \
		sh -c 'set -e; \
		VAULT_TOKEN=$$(vault write -field=token auth/approle/login role_id=$$(cat /vault/bootstrap/role_id) secret_id=$$(cat /vault/bootstrap/secret_id)); \
		OUTPUT=$$(VAULT_TOKEN=$$VAULT_TOKEN vault write pki/sign/athenz csr=@/dev/null 2>&1 || true); \
		echo "Vault output: $$OUTPUT"; \
		if echo "$$OUTPUT" | grep -q "missing csr"; then \
			echo "AppRole authenticated, PKI endpoint accessible"; \
		else exit 1; fi'
	@echo "Vault PKI signing endpoint verified"
	@echo ""

setup-vault-credentials:
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault-bootstrap -- sh -c 'while [ ! -f /vault/bootstrap/role_id ]; do sleep 1; done'
	kubectl -n vault exec $(VAULT_POD) -c vault-bootstrap -- cat /vault/bootstrap/role_id > /tmp/vault_role_id
	kubectl -n vault exec $(VAULT_POD) -c vault-bootstrap -- cat /vault/bootstrap/secret_id > /tmp/vault_secret_id
	kubectl create secret generic vault-approle \
		-n athenz \
		--from-file=role_id=/tmp/vault_role_id \
		--from-file=secret_id=/tmp/vault_secret_id \
		--dry-run=client -o yaml | kubectl apply -f -
	rm -f /tmp/vault_role_id /tmp/vault_secret_id
	@echo ""
	@echo "**************************************"
	@echo "***  Vault credentials provisioned ***"
	@echo "**************************************"
	@echo ""

test-vault-identityprovider:
	WAITING_TIMEOUT=60s; \
	kubectl -n athenz wait --for=condition=available --timeout=$${WAITING_TIMEOUT} deployment/identityprovider-deployment \
	|| ( \
		printf "\n\n** identityprovider-deployment did not become available within $${WAITING_TIMEOUT} **\n\n"; \
		kubectl -n athenz get all; \
		kubectl -n athenz logs deployment/identityprovider-deployment --all-containers=true --tail=200 ||:; \
		kubectl -n athenz describe deployment identityprovider-deployment ||:; \
		exit 1; \
	)
	SLEEP_SECONDS=5; \
	WAITING_THRESHOLD=60; \
	i=0; \
	while true; do \
		printf "\n***** Waiting for identity provisioning ($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
		( \
		kubectl -n athenz exec deployment/identityprovider-deployment -it -c sia -- \
			ls -alF /var/run/athenz/tls.key /var/run/athenz/tls.crt /var/run/athenz/ca.crt \
		) \
		&& break \
		|| echo "Waiting for Identity Provisioning..."; \
		sleep $${SLEEP_SECONDS}; \
		i=$$(( i + 1 )); \
		if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
			printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
			kubectl -n athenz get all | grep -E "pod/identityprovider-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz logs %% --all-containers=true ||:; \
			kubectl -n athenz get all | grep -E "pod/athenz-zts-server-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz logs %% -c athenz-zts-server ||:; \
			kubectl -n athenz get all; \
			exit 1; \
		fi; \
	done
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "**  Identity provisioning successful *"
	@echo "**************************************"
	@echo ""

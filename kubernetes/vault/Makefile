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
	kubectl -n vault exec $(VAULT_POD) -c vault -- \
		sh -c "VAULT_TOKEN=$$(vault write -field=token auth/approle/login role_id=$$(cat /vault/bootstrap/role_id) secret_id=$$(cat /vault/bootstrap/secret_id)) && \
		VAULT_TOKEN=$$VAULT_TOKEN vault write pki/sign/athenz csr=@/dev/null 2>&1 | grep -q 'missing csr' && \
		echo 'AppRole authenticated, PKI endpoint accessible'"
	@echo "Vault PKI signing endpoint verified"
	@echo ""

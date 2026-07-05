ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif
ifeq ($(DOCKER_REGISTRY_EXTERNAL),)
DOCKER_REGISTRY_EXTERNAL=ghcr.io/ctyano/
endif

clean-vault:
	kubectl delete -k kustomize

clean-certificates:
	rm -rf kustomize/keys kustomize/certs

wait-vault:
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault wait --for=condition=Ready pod/$(VAULT_POD) --timeout=120s
	kubectl -n vault exec $(VAULT_POD) -c vault -- sh -c 'while [ ! -s /vault/bootstrap/role_id ] || [ ! -s /vault/bootstrap/secret_id ]; do sleep 1; done'

generate-ca: wait-vault
	mkdir -p kustomize/keys kustomize/certs
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault -- \
		sh -c 'VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault read -field=certificate pki/cert/ca' \
		> kustomize/certs/ca.cert.pem
	cp kustomize/certs/ca.cert.pem kustomize/certs/selfsign.ca.cert.pem
	cat kustomize/certs/ca.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/ca.cert.pem

generate-zms: generate-ca
	mkdir -p kustomize/keys kustomize/certs
	openssl genrsa -out kustomize/keys/zms.private.pem 4096
	openssl rsa -pubout -in kustomize/keys/zms.private.pem -out kustomize/keys/zms.public.pem
	openssl req -config ../../openssl/zms.openssl.config -new -key kustomize/keys/zms.private.pem -out kustomize/certs/zms.csr.pem -extensions ext_req
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault -i -- \
		sh -c 'cat > /tmp/zms.csr.pem && VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault write -format=json pki/sign/athenz csr=@/tmp/zms.csr.pem ttl=43200m' < kustomize/certs/zms.csr.pem \
		| jq -r .data.certificate > kustomize/certs/zms.cert.pem
	cat kustomize/certs/zms.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/zms.cert.pem

generate-zts: generate-zms
	mkdir -p kustomize/keys kustomize/certs
	openssl genrsa -out kustomize/keys/zts.private.pem 4096
	openssl rsa -pubout -in kustomize/keys/zts.private.pem -out kustomize/keys/zts.public.pem
	openssl req -config ../../openssl/zts.openssl.config -new -key kustomize/keys/zts.private.pem -out kustomize/certs/zts.csr.pem -extensions ext_req
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault -i -- \
		sh -c 'cat > /tmp/zts.csr.pem && VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault write -format=json pki/sign/athenz csr=@/tmp/zts.csr.pem ttl=43200m' < kustomize/certs/zts.csr.pem \
		| jq -r .data.certificate > kustomize/certs/zts.cert.pem
	cat kustomize/certs/zts.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/zts.cert.pem

generate-admin: generate-ca
	mkdir -p kustomize/keys kustomize/certs
	openssl genrsa -out kustomize/keys/athenz_admin.private.pem 4096
	openssl rsa -pubout -in kustomize/keys/athenz_admin.private.pem -out kustomize/keys/athenz_admin.public.pem
	openssl req -config ../../openssl/athenz_admin.openssl.config -new -key kustomize/keys/athenz_admin.private.pem -out kustomize/certs/athenz_admin.csr.pem -extensions ext_req
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault -i -- \
		sh -c 'cat > /tmp/athenz_admin.csr.pem && VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault write -format=json pki/sign/athenz csr=@/tmp/athenz_admin.csr.pem ttl=43200m' < kustomize/certs/athenz_admin.csr.pem \
		| jq -r .data.certificate > kustomize/certs/athenz_admin.cert.pem
	cat kustomize/certs/athenz_admin.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/athenz_admin.cert.pem

generate-ui: generate-ca
	mkdir -p kustomize/keys kustomize/certs
	openssl genrsa -out kustomize/keys/ui.private.pem 4096
	openssl rsa -pubout -in kustomize/keys/ui.private.pem -out kustomize/keys/ui.public.pem
	openssl req -config ../../openssl/ui.openssl.config -new -key kustomize/keys/ui.private.pem -out kustomize/certs/ui.csr.pem -extensions ext_req
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault -i -- \
		sh -c 'cat > /tmp/ui.csr.pem && VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault write -format=json pki/sign/athenz csr=@/tmp/ui.csr.pem ttl=43200m' < kustomize/certs/ui.csr.pem \
		| jq -r .data.certificate > kustomize/certs/ui.cert.pem
	cat kustomize/certs/ui.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/ui.cert.pem

generate-identityprovider: generate-ca
	mkdir -p kustomize/keys kustomize/certs
	openssl genrsa -out kustomize/keys/identityprovider.private.pem 4096
	openssl rsa -pubout -in kustomize/keys/identityprovider.private.pem -out kustomize/keys/identityprovider.public.pem

generate-crypki: generate-ca
	mkdir -p kustomize/keys kustomize/certs
	openssl genrsa -out kustomize/keys/crypki.private.pem 4096
	openssl req -config ../../openssl/crypki.openssl.config -new -key kustomize/keys/crypki.private.pem -out kustomize/certs/crypki.csr.pem -extensions ext_req
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault -i -- \
		sh -c 'cat > /tmp/crypki.csr.pem && VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault write -format=json pki/sign/athenz csr=@/tmp/crypki.csr.pem ttl=43200m' < kustomize/certs/crypki.csr.pem \
		| jq -r .data.certificate > kustomize/certs/crypki.cert.pem
	cat kustomize/certs/crypki.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/crypki.cert.pem

generate-idp: generate-ca
	mkdir -p kustomize/keys kustomize/certs
	openssl genrsa -out kustomize/keys/idp.private.pem 4096
	openssl rsa -pubout -in kustomize/keys/idp.private.pem -out kustomize/keys/idp.public.pem
	openssl req -config ../../openssl/idp.openssl.config -new -key kustomize/keys/idp.private.pem -out kustomize/certs/idp.csr.pem -extensions ext_req
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault -i -- \
		sh -c 'cat > /tmp/idp.csr.pem && VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault write -format=json pki/sign/athenz csr=@/tmp/idp.csr.pem ttl=43200m' < kustomize/certs/idp.csr.pem \
		| jq -r .data.certificate > kustomize/certs/idp.cert.pem
	cat kustomize/certs/idp.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/idp.cert.pem

generate-certificates: generate-ca generate-zms generate-zts generate-admin generate-ui generate-identityprovider generate-crypki generate-idp

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
	kubectl -n vault wait --for=condition=Ready pod/$(VAULT_POD) --timeout=120s
	kubectl -n vault exec $(VAULT_POD) -c vault -- sh -c 'while [ ! -s /vault/bootstrap/role_id ] || [ ! -s /vault/bootstrap/secret_id ]; do sleep 1; done'
	kubectl -n vault exec $(VAULT_POD) -c vault -- \
		sh -c 'VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
		vault write -field=token auth/approle/login \
			role_id=$$(cat /vault/bootstrap/role_id) \
			secret_id=$$(cat /vault/bootstrap/secret_id) > /dev/null'
	kubectl -n vault exec $(VAULT_POD) -c vault -- \
		sh -c 'VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
		vault read -field=max_ttl pki/roles/athenz > /dev/null'
	@echo "Vault PKI signing endpoint verified"
	@echo ""

setup-vault-credentials:
	$(eval VAULT_POD := $(shell kubectl -n vault get pods -l app.kubernetes.io/instance=vault -o jsonpath='{.items[0].metadata.name}'))
	kubectl -n vault exec $(VAULT_POD) -c vault -- sh -c 'while [ ! -f /vault/bootstrap/role_id ]; do sleep 1; done'
	kubectl -n vault exec $(VAULT_POD) -c vault -- cat /vault/bootstrap/role_id > /tmp/vault_role_id
	kubectl -n vault exec $(VAULT_POD) -c vault -- cat /vault/bootstrap/secret_id > /tmp/vault_secret_id
	kubectl create namespace athenz ||:
	kubectl -n athenz create secret generic vault-approle \
		--from-file=role_id=/tmp/vault_role_id \
		--from-file=secret_id=/tmp/vault_secret_id \
		--dry-run=client -o yaml | kubectl apply -f -
	rm -f /tmp/vault_role_id /tmp/vault_secret_id
	@echo ""
	@echo "**************************************"
	@echo "***  Vault credentials provisioned ***"
	@echo "**************************************"
	@echo ""

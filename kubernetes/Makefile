SED_INPLACE = sed -i
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	SED_INPLACE = sed -i ''
endif

ifeq ($(DOCKERIO_REGISTRY),)
DOCKERIO_REGISTRY=docker.io
endif
ifeq ($(GHCR_REGISTRY),)
GHCR_REGISTRY=ghcr.io
endif
ifeq ($(QUAYIO_REGISTRY),)
QUAYIO_REGISTRY=quay.io
endif
ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=$(GHCR_REGISTRY)/ctyano/
endif
ifeq ($(DOCKER_REGISTRY_EXTERNAL),)
DOCKER_REGISTRY_EXTERNAL=$(GHCR_REGISTRY)/ctyano/
endif
export DOCKERIO_REGISTRY GHCR_REGISTRY QUAYIO_REGISTRY
export DOCKER_REGISTRY DOCKER_REGISTRY_EXTERNAL

install-kustomize:
	which kustomize \
|| (curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"| bash \
&& chmod a+x kustomize \
&& mv kustomize ~/.local/bin/)

clean-certificates:
	rm -rf athenz-cli/kustomize/{keys,certs}
	rm -rf athenz-zms-server/kustomize/{keys,certs}
	rm -rf athenz-zts-server/kustomize/{keys,certs}
	rm -rf athenz-ui/kustomize/{keys,certs}
	rm -rf athenz-identityprovider/kustomize/{keys,certs}
	rm -rf athenz-authorizer/kustomize/{keys,certs}
	rm -rf athenz-authzenvoy/kustomize/{keys,certs}
	rm -rf athenz-authzwebhook/kustomize/{keys,certs}
	rm -rf athenz-authzproxy/kustomize/{keys,certs}
	rm -rf athenz-client/kustomize/{keys,certs}
	rm -rf crypki-softhsm/kustomize/{keys,certs}
	rm -rf athenz-oauth2/kustomize/{keys,certs}
	rm -rf vault/kustomize/{keys,certs}

clean-namespace:
	kubectl delete namespace athenz ||:
	kubectl delete namespace crypki ||:
	kubectl delete namespace vault ||:

clean: clean-namespace clean-certificates
	@grep -q "athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.crypki.HttpCertSignerFactory" "athenz-zts-server/kustomize/conf/zts.properties" && \
		$(MAKE) clean-patch-athenz-zts-crypki ||:
	@grep -q "athenz.zts.cert_signer_factory_class=com.yahoo.athenz.common.server.cert.impl.vault.VaultCertSignerFactory" "athenz-zts-server/kustomize/conf/zts.properties" && \
		$(MAKE) clean-patch-athenz-zts-vault ||:

copy-crypki-certificates-to-kustomization:
	cp -r ../keys ../certs crypki-softhsm/kustomize/

copy-certificates-to-kustomization:
	grep -q "athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.crypki.HttpCertSignerFactory" "athenz-zts-server/kustomize/conf/zts.properties" && echo SKIPPED || \
	( \
	cp -r ../keys ../certs athenz-cli/kustomize/ && \
	cp -r ../keys ../certs athenz-zms-server/kustomize/ && \
	cp -r ../keys ../certs athenz-zts-server/kustomize/ && \
	cp -r ../keys ../certs athenz-ui/kustomize/ && \
	cp -r ../keys ../certs athenz-identityprovider/kustomize/ && \
	cp -r ../keys ../certs athenz-authorizer/kustomize/ && \
	cp -r ../keys ../certs athenz-authzenvoy/kustomize/ && \
	cp -r ../keys ../certs athenz-authzwebhook/kustomize/ && \
	cp -r ../keys ../certs athenz-authzproxy/kustomize/ && \
	cp -r ../keys ../certs athenz-client/kustomize/ && \
	cp -r ../keys ../certs crypki-softhsm/kustomize/ && \
	cp -r ../keys ../certs athenz-oauth2/kustomize/ && \
	echo "APPLIED copy-certificates-to-kustomization" \
	)

overwrite-certificates-with-vault:
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-cli/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-zms-server/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-zts-server/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-ui/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-identityprovider/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-oauth2/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-authorizer/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-authzenvoy/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-authzwebhook/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-authzproxy/kustomize/
	cp -r vault/kustomize/keys vault/kustomize/certs athenz-client/kustomize/

overwrite-certificates-with-crypki:
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-cli/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-zms-server/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-zts-server/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-ui/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-identityprovider/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-oauth2/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-authorizer/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-authzenvoy/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-authzwebhook/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-authzproxy/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-client/kustomize/

# Usage:
# make replace KEY=old_string VALUE=new_string FILE=path/to/file
replace-system-properties:
	@if [ -z "$(KEY)" ] || [ -z "$(VALUE)" ] || [ -z "$(FILE)" ]; then \
		echo "Error: KEY, VALUE, and FILE must be provided"; \
		exit 1; \
	fi; \
	if grep -q "$(KEY)" "$(FILE)"; then \
		echo "Replacing '$(KEY)' with '$(VALUE)' in $(FILE)"; \
		$(SED_INPLACE) 's|$(KEY)|$(VALUE)|g' "$(FILE)"; \
	else \
		echo "Key '$(KEY)' not found in $(FILE)"; \
	fi

clean-patch-athenz-zts-crypki:
	@$(MAKE) replace-system-properties \
		KEY="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.crypki.HttpCertSignerFactory" \
		VALUE="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.KeyStoreCertSignerFactory" \
		FILE="athenz-zts-server/kustomize/conf/zts.properties"

patch-athenz-zts-crypki:
	@$(MAKE) replace-system-properties \
		KEY="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.KeyStoreCertSignerFactory" \
		VALUE="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.crypki.HttpCertSignerFactory" \
		FILE="athenz-zts-server/kustomize/conf/zts.properties"

clean-patch-athenz-zts-vault:
	@$(MAKE) replace-system-properties \
		KEY="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.common.server.cert.impl.vault.VaultCertSignerFactory" \
		VALUE="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.KeyStoreCertSignerFactory" \
		FILE="athenz-zts-server/kustomize/conf/zts.properties"
	$(SED_INPLACE) '/^- patch-vault-approle.yaml/d' athenz-zts-server/kustomize/kustomization.yaml
	$(SED_INPLACE) '/^patchesStrategicMerge:/d' athenz-zts-server/kustomize/kustomization.yaml

patch-athenz-zts-vault:
	@$(MAKE) replace-system-properties \
		KEY="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.KeyStoreCertSignerFactory" \
		VALUE="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.common.server.cert.impl.vault.VaultCertSignerFactory" \
		FILE="athenz-zts-server/kustomize/conf/zts.properties"
	@if ! grep -q "patch-vault-approle.yaml" "athenz-zts-server/kustomize/kustomization.yaml"; then \
		printf '\npatchesStrategicMerge:\n- patch-vault-approle.yaml\n' >> athenz-zts-server/kustomize/kustomization.yaml; \
	fi

switch-athenz-zts-cert-signer: patch-athenz-zts-crypki
	@$(MAKE) -C crypki-softhsm generate-certificates
	@$(MAKE) overwrite-certificates-with-crypki

switch-athenz-zts-cert-signer-vault: patch-athenz-zts-vault setup-vault-credentials
	@$(MAKE) overwrite-certificates-with-vault
	kubectl apply -k athenz-zts-server/kustomize
	kubectl -n athenz rollout restart deployment/athenz-zts-server
	kubectl -n athenz rollout status deployment/athenz-zts-server --timeout=120s

kind-setup:
	#which kind && (kind delete cluster ||:; kind create cluster --config kind.yaml)
	which kind && (kind delete cluster ||:; kind create cluster)

kind-load-images:
	@# Check if Docker is using the problematic containerd-snapshotter
	@# https://docs.rancherdesktop.io/how-to-guides/migrating-images/
	@if [ "$$(docker info 2>/dev/null | grep -c 'containerd-snapshotter')" -eq 1 ]; then \
		if command -v rdctl >/dev/null; then \
			echo "Detected snapshotter driver. Switching to classic..."; \
			rdctl set --container-engine.moby-storage-driver classic; \
		else \
			echo "Warning: Detected problematic 'containerd-snapshotter' but 'rdctl' command not found. Manual intervention may be required."; \
		fi; \
	else \
		echo "Environment is correct. No driver change needed."; \
	fi
	kubectl config get-contexts kind-kind --no-headers=true | grep -E "^\* +kind-kind"
	kind load docker-image \
		$(DOCKERIO_REGISTRY)/hashicorp/vault:latest \
		$(DOCKERIO_REGISTRY)/ghostunnel/ghostunnel:latest \
		$(DOCKER_REGISTRY_EXTERNAL)crypki-softhsm:latest \
		$(DOCKER_REGISTRY_EXTERNAL)certsigner-envoy:latest \
		$(DOCKER_REGISTRY_EXTERNAL)athenz-user-cert:latest \
		$(DOCKER_REGISTRY_EXTERNAL)athenz-plugins:latest
	kind load docker-image \
		$(DOCKER_REGISTRY)athenz-db:latest \
		$(DOCKER_REGISTRY)athenz-zms-server:latest \
		$(DOCKER_REGISTRY)athenz-zts-server:latest \
		$(DOCKER_REGISTRY)athenz-cli:latest \
		$(DOCKER_REGISTRY)athenz-ui:latest
	kind load docker-image \
		$(DOCKERIO_REGISTRY)/ealen/echo-server:latest \
		$(DOCKERIO_REGISTRY)/dexidp/dex:latest \
		$(DOCKERIO_REGISTRY)/envoyproxy/envoy:v1.34-latest \
		$(DOCKERIO_REGISTRY)/cfssl/cfssl:latest \
		$(DOCKERIO_REGISTRY)/openpolicyagent/kube-mgmt:latest \
		$(DOCKERIO_REGISTRY)/openpolicyagent/opa:latest-envoy \
		$(DOCKERIO_REGISTRY)/openpolicyagent/opa:latest-static \
		$(DOCKERIO_REGISTRY)/openpolicyagent/opa:0.66.0-static \
		$(DOCKERIO_REGISTRY)/portainer/kubectl-shell:latest \
		$(QUAYIO_REGISTRY)/keycloak/keycloak:26.5.5 \
		$(DOCKERIO_REGISTRY)/library/postgres:alpine \
		$(DOCKER_REGISTRY_EXTERNAL)k8s-athenz-sia:latest \
		$(DOCKER_REGISTRY_EXTERNAL)docker-vegeta:latest
	if [ "$$(uname -m)" = "aarch64" -o "$$(uname -m)" = "arm64" ]; then \
		kind load docker-image $(DOCKERIO_REGISTRY)/tatyano/authorization-proxy:latest; \
	else \
		kind load docker-image $(DOCKERIO_REGISTRY)/athenz/authorization-proxy:latest; \
	fi

kind-shutdown:
	kind delete cluster

setup-crypki-softhsm:
	@$(MAKE) -C crypki-softhsm setup-crypki-softhsm

deploy-crypki-softhsm: copy-crypki-certificates-to-kustomization setup-crypki-softhsm
	@$(MAKE) -C crypki-softhsm deploy-crypki-softhsm

test-crypki-softhsm:
	@$(MAKE) -C crypki-softhsm test-crypki-softhsm

setup-vault:
	@$(MAKE) -C vault setup-vault

deploy-vault: setup-vault
	@$(MAKE) -C vault deploy-vault

clean-vault:
	@$(MAKE) -C vault clean-vault

test-vault:
	@$(MAKE) -C vault test-vault

check-vault:
	@$(MAKE) -C vault test-vault

test-vault-pki:
	@$(MAKE) -C vault test-vault-pki

generate-vault-certificates:
	@$(MAKE) -C vault generate-certificates

setup-vault-credentials:
	@$(MAKE) -C vault setup-vault-credentials

setup-athenz-oauth2:
	@$(MAKE) -C athenz-oauth2 setup-athenz-oauth2

deploy-athenz-oauth2: setup-athenz-oauth2
	@$(MAKE) -C athenz-oauth2 deploy-athenz-oauth2
	@$(MAKE) -C keycloak deploy-keycloak

test-athenz-oauth2:
	@$(MAKE) -C athenz-oauth2 register-athenz-oauth2 test-athenz-oauth2
	@$(MAKE) -C keycloak test-keycloak

athenz-user-cert:
	@$(MAKE) -C athenz-oauth2 athenz-user-cert

kustomize-edit-athenz-db-image: install-kustomize
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd athenz-db/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-db:latest=$(DOCKER_REGISTRY)athenz-db:latest \
	) \
	fi

setup-athenz-db: kustomize-edit-athenz-db-image
	kubectl apply -k athenz-db/kustomize

kustomize-edit-athenz-cli-image: install-kustomize
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd athenz-cli/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	) \
	fi

setup-athenz-cli: kustomize-edit-athenz-cli-image
	kubectl apply -k athenz-cli/kustomize

kustomize-edit-athenz-zms-server-image: install-kustomize
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd athenz-zms-server/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-zms-server:latest=$(DOCKER_REGISTRY)athenz-zms-server:latest \
	) \
	fi
	if [ "$(DOCKER_REGISTRY_EXTERNAL)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd athenz-zms-server/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-plugins:latest=$(DOCKER_REGISTRY_EXTERNAL)athenz-plugins:latest \
	) \
	fi

setup-athenz-zms-server: setup-athenz-db kustomize-edit-athenz-zms-server-image
	kubectl apply -k athenz-zms-server/kustomize

kustomize-edit-athenz-zts-server-image: install-kustomize
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd athenz-zts-server/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-zts-server:latest=$(DOCKER_REGISTRY)athenz-zts-server:latest \
	) \
	fi
	if [ "$(DOCKER_REGISTRY_EXTERNAL)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd athenz-zts-server/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-plugins:latest=$(DOCKER_REGISTRY_EXTERNAL)athenz-plugins:latest \
	) \
	fi

setup-athenz-zts-server: setup-athenz-db setup-athenz-zms-server kustomize-edit-athenz-zts-server-image
	kubectl apply -k athenz-zts-server/kustomize

kustomize-edit-athenz-ui-image: install-kustomize
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd athenz-ui/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-ui:latest=$(DOCKER_REGISTRY)athenz-ui:latest \
	) \
	fi
	if [ "$(DOCKERIO_REGISTRY)" != "docker.io" ]; then \
	( \
	cd athenz-ui/kustomize \
	&& kustomize edit set image docker.io/ghostunnel/ghostunnel:latest=$(DOCKERIO_REGISTRY)/ghostunnel/ghostunnel:latest \
	) \
	fi

setup-athenz-ui: setup-athenz-zms-server kustomize-edit-athenz-ui-image
	kubectl apply -k athenz-ui/kustomize

setup-athenz: setup-athenz-db setup-athenz-cli setup-athenz-zms-server setup-athenz-zts-server setup-athenz-ui

deploy-athenz: copy-certificates-to-kustomization setup-athenz

kustomize-edit-athenz-grpc-authorizer-image: install-kustomize
	if [ "$(DOCKERIO_REGISTRY)" != "docker.io" ]; then \
	( \
	cd athenz-grpc-authorizer \
	&& kustomize edit set image docker.io/openpolicyagent/opa:latest-envoy=$(DOCKERIO_REGISTRY)/openpolicyagent/opa:latest-envoy \
	&& kustomize edit set image docker.io/envoyproxy/envoy:v1.34-latest=$(DOCKERIO_REGISTRY)/envoyproxy/envoy:v1.34-latest \
	&& kustomize edit set image docker.io/ealen/echo-server:latest=$(DOCKERIO_REGISTRY)/ealen/echo-server:latest \
	) \
	fi

setup-athenz-grpc-authorizer: kustomize-edit-athenz-grpc-authorizer-image
	kubectl apply -k athenz-grpc-authorizer

check-athenz:
	WAITING_TIMEOUT=300s; \
	kubectl -n athenz rollout status statefulset/athenz-db --timeout=$${WAITING_TIMEOUT} \
	&& kubectl -n athenz rollout status deployment/athenz-cli --timeout=$${WAITING_TIMEOUT} \
	&& kubectl -n athenz rollout status deployment/athenz-zms-server --timeout=$${WAITING_TIMEOUT} \
	&& kubectl -n athenz rollout status deployment/athenz-zts-server --timeout=$${WAITING_TIMEOUT} \
	&& kubectl -n athenz rollout status deployment/athenz-ui --timeout=$${WAITING_TIMEOUT} \
	|| ( \
		printf "\n\n** Athenz deployment did not become ready within $${WAITING_TIMEOUT} **\n\n"; \
		kubectl -n athenz get all; \
		kubectl -n athenz logs -l app.kubernetes.io/name=athenz-ui --all-containers=true --tail=200 ||:; \
		kubectl -n athenz describe pod -l app.kubernetes.io/name=athenz-ui ||:; \
		exit 1; \
	)
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "****  Athenz Deployed Successfully ***"
	@echo "**************************************"
	@echo ""

test-athenz-zms-server:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
curl \
	-sf \
	-H"Content-type: application/json" \
	-H"X-Auth-Request-Preferred-Username: user.athenz_admin" \
	https://athenz-zms-server.athenz:4443/zms/v1/domain
	@echo

test-athenz-zts-server:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
curl \
	-sf \
	-H"Content-type: application/json" \
	-H"X-Auth-Request-Preferred-Username: user.athenz_admin" \
	https://athenz-zts-server.athenz:4443/zts/v1/domain/sys.auth/service
	@echo

test-zms-cli:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
zms-cli \
	-z https://athenz-zms-server.athenz:4443/zms/v1 \
	-key /var/run/athenz/athenz_admin.private.pem \
	-cert /var/run/athenz/athenz_admin.cert.pem \
	show-domain sys.auth

test-athenz-ui:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
curl \
	-sf \
	-H"X-Auth-Request-Preferred-Username: athenz_admin" \
	-H"X-Auth-Request-Email: athenz_admin@www.athenz.io" \
	https://athenz-ui.athenz:443/ \
| grep -Eiq '<title[^>]*>[^<]*Athenz[^<]*</title>' \
&& echo "Athenz UI sccessfully displayed"

test-zts-roletoken:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
zts-roletoken \
	-zts https://athenz-zts-server.athenz:4443/zts/v1 \
	-svc-key-file /var/run/athenz/athenz_admin.private.pem \
	-svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
	-domain sys.auth \
	-role admin \
| rev | cut -d';' -f2- | rev \
| tr ';' '\n'

test-zts-accesstoken:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
zts-accesstoken \
	-zts https://athenz-zts-server.athenz:4443/zts/v1 \
	-svc-key-file /var/run/athenz/athenz_admin.private.pem \
	-svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
	-domain sys.auth \
	-roles admin \
| jq -r .access_token \
| jq -Rr 'split(".") | .[0,1] | @base64d' \
| jq -r .

test-jwks:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
curl \
	-sf \
	-H"Content-type: application/json" \
	--key /var/run/athenz/athenz_admin.private.pem \
	--cert /var/run/athenz/athenz_admin.cert.pem \
	"https://athenz-zts-server.athenz:4443/zts/v1/oauth2/keys?rfc=true" \
| tee ./jwks.json \
| jq -r .

test-policies:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
curl \
	-sfXPOST \
	-H "Content-type: application/json" \
	-d"{\"policyVersions\":{\"\":\"\"}}" \
	--key /var/run/athenz/athenz_admin.private.pem \
	--cert /var/run/athenz/athenz_admin.cert.pem \
	"https://athenz-zts-server.athenz:4443/zts/v1/domain/sys.auth/policy/signed" \
| jq -r '[.protected,.payload,.signature] | join(".")' \
| jq -Rr 'split(".") | .[0,1] | @base64d' \
| jq -r .

test-verify: test-jwks
	kubectl -n athenz exec deployment/athenz-cli -it -- \
zts-accesstoken \
	-zts https://athenz-zts-server.athenz:4443/zts/v1 \
	-svc-key-file /var/run/athenz/athenz_admin.private.pem \
	-svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
	-domain sys.auth \
	-roles admin \
| jq -r .access_token \
| step crypto jws verify --jwks=jwks.json \
&& printf "\nValid Access Token\n" || printf "\nInvalid Access Token\n"
	@echo ""
	kubectl -n athenz exec deployment/athenz-cli -it -- \
curl \
	-sfXPOST \
	-H "Content-type: application/json" \
	-d"{\"policyVersions\":{\"\":\"\"}}" \
	--key /var/run/athenz/athenz_admin.private.pem \
	--cert /var/run/athenz/athenz_admin.cert.pem \
	"https://athenz-zts-server.athenz:4443/zts/v1/domain/sys.auth/policy/signed" \
| jq -r '[.protected,.payload,.signature] | join(".")' \
| step crypto jws verify --jwks=jwks.json \
&& printf "\nValid Policy\n" || printf "\nInvalid Policy\n"

setup-athenz-identityprovider: check-athenz test-athenz-servers
	@$(MAKE) -C athenz-identityprovider register-athenz-identityprovider check-register-athenz-identityprovider setup-athenz-identityprovider

deploy-athenz-identityprovider:
	@$(MAKE) -C athenz-identityprovider deploy-athenz-identityprovider

test-athenz-identityprovider:
	@$(MAKE) -C athenz-identityprovider test-athenz-identityprovider

test-athenz-identityprovider-openpolicyagent:
	@$(MAKE) -C athenz-identityprovider test-athenz-identityprovider-openpolicyagent

test-athenz-identityprovider-openpolicyagent-coverage:
	@$(MAKE) -C athenz-identityprovider test-athenz-identityprovider-openpolicyagent-coverage

setup-athenz-authorizer: test-athenz-servers test-athenz-identityprovider
	@$(MAKE) -C athenz-authorizer register-athenz-authorizer check-register-athenz-authorizer

deploy-athenz-authorizer: test-athenz-identityprovider
	@$(MAKE) -C athenz-authorizer deploy-athenz-authorizer

test-athenz-authorizer:
	@$(MAKE) -C athenz-authorizer test-athenz-authorizer

setup-athenz-authzenvoy: test-athenz-servers test-athenz-identityprovider
	@$(MAKE) -C athenz-authzenvoy register-athenz-authzenvoy check-register-athenz-authzenvoy

deploy-athenz-authzenvoy: test-athenz-identityprovider
	@$(MAKE) -C athenz-authzenvoy deploy-athenz-authzenvoy

test-athenz-authzenvoy:
	@$(MAKE) -C athenz-authzenvoy test-athenz-authzenvoy

setup-athenz-authzwebhook: test-athenz-servers test-athenz-identityprovider
	@$(MAKE) -C athenz-authzwebhook register-athenz-authzwebhook check-register-athenz-authzwebhook

deploy-athenz-authzwebhook: test-athenz-identityprovider
	@$(MAKE) -C athenz-authzwebhook deploy-athenz-authzwebhook

test-athenz-authzwebhook:
	@$(MAKE) -C athenz-authzwebhook test-athenz-authzwebhook

setup-athenz-authzproxy: test-athenz-servers test-athenz-identityprovider
	@$(MAKE) -C athenz-authzproxy register-athenz-authzproxy check-register-athenz-authzproxy

deploy-athenz-authzproxy: test-athenz-identityprovider
	@$(MAKE) -C athenz-authzproxy deploy-athenz-authzproxy

test-athenz-authzproxy:
	@$(MAKE) -C athenz-authzproxy test-athenz-authzproxy

setup-athenz-client: test-athenz-servers test-athenz-identityprovider
	@$(MAKE) -C athenz-client register-athenz-client check-register-athenz-client

deploy-athenz-client: test-athenz-identityprovider
	@$(MAKE) -C athenz-client deploy-athenz-client

test-athenz-client:
	@$(MAKE) -C athenz-client test-athenz-client

setup-athenz-workloads:
	@$(MAKE) -C athenz-authorizer register-athenz-authorizer
	@$(MAKE) -C athenz-authzenvoy register-athenz-authzenvoy
	@$(MAKE) -C athenz-authzwebhook register-athenz-authzwebhook
	@$(MAKE) -C athenz-authzproxy register-athenz-authzproxy
	@$(MAKE) -C athenz-client register-athenz-client
	@$(MAKE) -C athenz-authorizer check-register-athenz-authorizer
	@$(MAKE) -C athenz-authzenvoy check-register-athenz-authzenvoy
	@$(MAKE) -C athenz-authzwebhook check-register-athenz-authzwebhook
	@$(MAKE) -C athenz-authzproxy check-register-athenz-authzproxy
	@$(MAKE) -C athenz-client check-register-athenz-client

deploy-athenz-workloads: test-athenz-identityprovider
	@$(MAKE) -C athenz-authorizer deploy-athenz-authorizer
	@$(MAKE) -C athenz-authzenvoy deploy-athenz-authzenvoy
	@$(MAKE) -C athenz-authzwebhook deploy-athenz-authzwebhook
	@$(MAKE) -C athenz-authzproxy deploy-athenz-authzproxy
	@$(MAKE) -C athenz-client deploy-athenz-client

test-athenz-workloads:
	@$(MAKE) -C athenz-authorizer test-athenz-authorizer
	@$(MAKE) -C athenz-authzenvoy test-athenz-authzenvoy
	@$(MAKE) -C athenz-authzwebhook test-athenz-authzwebhook
	@$(MAKE) -C athenz-authzproxy test-athenz-authzproxy
	@$(MAKE) -C athenz-client test-athenz-client

test-athenz-servers: test-athenz-zms-server test-athenz-zts-server
	@echo ""
	@echo "**************************************"
	@echo "***** Athenz APIs are functioning ****"
	@echo "**************************************"
	@echo ""

test-athenz-envoy2echoserver:
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2echoserver" | jq -r .request || (kubectl -n athenz logs deployment/client-deployment --all-containers=true && false)
	@echo ""
	@echo "**************************************"
	@echo "**** Envoy Showcase is functioning ***"
	@echo "**************************************"
	@echo ""

test-athenz-envoy2envoyextauthz:
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2extauthz" | jq -r .request || (kubectl -n athenz logs deployment/authorizer-deployment --all-containers=true && false)
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2extauthzmtls" | jq -r .request || (kubectl -n athenz logs deployment/authorizer-deployment --all-containers=true && false)
	@echo ""
	@echo "**************************************"
	@echo "**** Envoy Showcase is functioning ***"
	@echo "**************************************"
	@echo ""

test-athenz-envoy2envoyfilter:
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2filterauthzmtls" | jq -r .request || (kubectl -n athenz logs deployment/authzenvoy-deployment --all-containers=true && false)
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2filterauthzjwt" | jq -r .request || (kubectl -n athenz logs deployment/authzenvoy-deployment --all-containers=true && false)
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2filterauthzmtlsjwt" | jq -r .request || (kubectl -n athenz logs deployment/authzenvoy-deployment --all-containers=true && false)

test-athenz-envoy2envoywebhook:
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2webhookauthzmtls" | jq -r .request || (kubectl -n athenz logs deployment/authzwebhook-deployment --all-containers=true && false)
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2webhookauthzjwt" | jq -r .request || (kubectl -n athenz logs deployment/authzwebhook-deployment --all-containers=true && false)
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2webhookauthzmtlsjwt" | jq -r .request || (kubectl -n athenz logs deployment/authzwebhook-deployment --all-containers=true && false)
	@echo ""
	@echo "**************************************"
	@echo "**** Envoy Showcase is functioning ***"
	@echo "**************************************"
	@echo ""

test-athenz-envoy2authzproxy:
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2authzproxy" | jq -r .request || (kubectl -n athenz logs deployment/authzproxy-deployment --all-containers=true && false)
	@echo ""
	@echo "**************************************"
	@echo "**** Envoy Showcase is functioning ***"
	@echo "**************************************"
	@echo ""

test-athenz-showcases: test-athenz-workloads test-athenz-envoy2echoserver test-athenz-envoy2echoserver test-athenz-envoy2envoyextauthz test-athenz-envoy2envoyfilter test-athenz-envoy2authzproxy

deploy-athenz-loadtest:
	@$(MAKE) -C loadtest deploy-athenz-loadtest test-athenz-loadtest

test-athenz-envoy-loadtest:
	@$(MAKE) -C loadtest run-athenz-envoy-loadtest

test-athenz-loadtest:
	@$(MAKE) -C loadtest test-athenz-loadtest
	@$(MAKE) -C loadtest run-athenz-envoy-loadtest run-athenz-sidecar-loadtest run-athenz-envoyfilter-loadtest run-athenz-envoywebhook-loadtest run-athenz-authzproxy-loadtest run-athenz-echoserver-loadtest run-athenz-loadtest

report-athenz-loadtest:
	@$(MAKE) -C loadtest report-athenz-envoy-loadtest report-athenz-sidecar-loadtest report-athenz-envoyfilter-loadtest report-athenz-envoywebhook-loadtest report-athenz-authzproxy-loadtest report-athenz-echoserver-loadtest report-athenz-loadtest

test-athenz: test-athenz-servers test-zms-cli test-athenz-ui test-zts-accesstoken test-policies test-verify

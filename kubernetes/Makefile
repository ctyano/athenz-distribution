SED_INPLACE = sed -i
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	SED_INPLACE = sed -i ''
endif

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

clean-namespace:
	kubectl delete namespace athenz ||:
	kubectl delete namespace crypki ||:

clean: clean-namespace clean-certificates
	@grep -q "athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.crypki.HttpCertSignerFactory" "athenz-zts-server/kustomize/conf/zts.properties" && \
		$(MAKE) clean-patch-athenz-zts ||:

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
	echo "APPLIED copy-certificates-to-kustomization" \
	)

overwrite-certificates-with-crypki:
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-cli/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-zms-server/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-zts-server/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-ui/kustomize/
	cp -r crypki-softhsm/kustomize/keys crypki-softhsm/kustomize/certs athenz-identityprovider/kustomize/
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

clean-patch-athenz-zts:
	@$(MAKE) replace-system-properties \
		KEY="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.crypki.HttpCertSignerFactory" \
		VALUE="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.KeyStoreCertSignerFactory" \
		FILE="athenz-zts-server/kustomize/conf/zts.properties"

patch-athenz-zts:
	@$(MAKE) replace-system-properties \
		KEY="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.KeyStoreCertSignerFactory" \
		VALUE="athenz.zts.cert_signer_factory_class=com.yahoo.athenz.zts.cert.impl.crypki.HttpCertSignerFactory" \
		FILE="athenz-zts-server/kustomize/conf/zts.properties"

switch-athenz-zts-cert-signer: patch-athenz-zts
	@$(MAKE) -C crypki-softhsm generate-certificates
	@$(MAKE) overwrite-certificates-with-crypki

kind-setup:
	kind create cluster

kind-load-images:
	kubectl config get-contexts kind-kind --no-headers=true | grep -E "^\* +kind-kind"
	kind load docker-image \
		docker.io/ghostunnel/ghostunnel:latest \
		$(DOCKER_REGISTRY)crypki-softhsm:latest \
		$(DOCKER_REGISTRY)certsigner-envoy:latest \
		$(DOCKER_REGISTRY)athenz_user_cert:latest \
		$(DOCKER_REGISTRY)athenz-plugins:latest
	kind load docker-image \
		$(DOCKER_REGISTRY)athenz-db:latest \
		$(DOCKER_REGISTRY)athenz-zms-server:latest \
		$(DOCKER_REGISTRY)athenz-zts-server:latest \
		$(DOCKER_REGISTRY)athenz-cli:latest \
		$(DOCKER_REGISTRY)athenz-ui:latest
	kind load docker-image \
		docker.io/ealen/echo-server:latest \
		docker.io/dexidp/dex:latest \
		docker.io/envoyproxy/envoy:v1.34-latest \
		docker.io/openpolicyagent/kube-mgmt:latest \
		docker.io/openpolicyagent/opa:latest-static \
		docker.io/portainer/kubectl-shell:latest \
		$(DOCKER_REGISTRY)k8s-athenz-sia:latest \
		$(DOCKER_REGISTRY)docker-vegeta:latest \
		docker.io/tatyano/authorization-proxy:latest

kind-shutdown:
	kind delete cluster

setup-crypki-softhsm:
	@$(MAKE) -C crypki-softhsm setup-crypki-softhsm

deploy-crypki-softhsm: copy-crypki-certificates-to-kustomization setup-crypki-softhsm
	@$(MAKE) -C crypki-softhsm deploy-crypki-softhsm

test-crypki-softhsm:
	@$(MAKE) -C crypki-softhsm test-crypki-softhsm

setup-athenz-oauth2:
	@$(MAKE) -C athenz-oauth2 setup-athenz-oauth2

deploy-athenz-oauth2: setup-athenz-oauth2
	@$(MAKE) -C athenz-oauth2 deploy-athenz-oauth2

test-athenz-oauth2:
	@$(MAKE) -C athenz-oauth2 test-athenz-oauth2

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
	&& kustomize edit set image ghcr.io/ctyano/athenz-plugins:latest=$(DOCKER_REGISTRY)athenz-plugins:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-zms-server:latest=$(DOCKER_REGISTRY)athenz-zms-server:latest \
	) \
	fi

setup-athenz-zms-server: setup-athenz-db kustomize-edit-athenz-zms-server-image
	kubectl apply -k athenz-zms-server/kustomize

kustomize-edit-athenz-zts-server-image: install-kustomize
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd athenz-zts-server/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-plugins:latest=$(DOCKER_REGISTRY)athenz-plugins:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-zts-server:latest=$(DOCKER_REGISTRY)athenz-zts-server:latest \
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

setup-athenz-ui: setup-athenz-zms-server kustomize-edit-athenz-ui-image
	kubectl apply -k athenz-ui/kustomize

setup-athenz: setup-athenz-db setup-athenz-cli setup-athenz-zms-server setup-athenz-zts-server setup-athenz-ui

deploy-athenz: copy-certificates-to-kustomization setup-athenz

check-athenz:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=300; \
i=0; \
while [ $$(( $$(kubectl -n athenz get all | grep -E "athenz-db-|athenz-zms-server-|athenz-zts-server-|athenz-ui-|athenz-cli-" | grep -E "0/1" | wc -l) )) -ne 0 ]; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n athenz get all | grep -E "pod/.*0/1" | sed -e 's/^\(pod\/[^ ]*\) *0\/1.*/\1/g' | xargs -I%% kubectl -n athenz logs %% --all-containers=true ||:; \
		kubectl -n athenz get all | grep -E "pod/.*0/1" | sed -e 's/^\(pod\/[^ ]*\) *0\/1.*/\1/g' | xargs -I%% kubectl -n athenz describe %% ||:; \
		kubectl -n athenz get all; \
		exit 1; \
	fi; \
done
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
| grep -E "<title>Athenz</title>" >/dev/null \
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
	@$(MAKE) -C loadtest run-athenz-envoy-loadtest run-athenz-sidecar-loadtest run-athenz-envoyfilter-loadtest run-athenz-envoywebhook-loadtest run-athenz-authzproxy-loadtest run-athenz-echoserver-loadtest run-athenz-loadtest

report-athenz-loadtest:
	@$(MAKE) -C loadtest report-athenz-envoy-loadtest report-athenz-sidecar-loadtest report-athenz-envoyfilter-loadtest report-athenz-envoywebhook-loadtest report-athenz-authzproxy-loadtest report-athenz-echoserver-loadtest report-athenz-loadtest

test-athenz: test-athenz-servers test-zms-cli test-athenz-ui test-zts-accesstoken test-policies test-verify

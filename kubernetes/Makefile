ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

clean-certificates:
	rm -rf athenz-cli/kustomize/{keys,certs}
	rm -rf athenz-zms-server/kustomize/{keys,certs}
	rm -rf athenz-zts-server/kustomize/{keys,certs}
	rm -rf athenz-ui/kustomize/{keys,certs}
	rm -rf athenz-identityprovider/kustomize/{keys,certs}
	rm -rf athenz-authorizer/kustomize/{keys,certs}
	rm -rf athenz-client/kustomize/{keys,certs}
	rm -rf athenz-authzproxy/kustomize/{keys,certs}

clean-namespace:
	kubectl delete namespace athenz ||:

clean-athenz: clean-namespace clean-certificates

copy-to-kustomization:
	cp -r ../keys ../certs athenz-cli/kustomize/
	cp -r ../keys ../certs athenz-zms-server/kustomize/
	cp -r ../keys ../certs athenz-zts-server/kustomize/
	cp -r ../keys ../certs athenz-ui/kustomize/
	cp ../athenz/servers/zms/schema/zms_server.sql athenz-db/kustomize/zms_server.sql
	cp ../athenz/servers/zts/schema/zts_server.sql athenz-db/kustomize/zts_server.sql
	cp -r ../keys ../certs athenz-identityprovider/kustomize/
	cp -r ../keys ../certs athenz-authorizer/kustomize/
	cp -r ../keys ../certs athenz-client/kustomize/
	cp -r ../keys ../certs athenz-authzproxy/kustomize/

kind-setup:
	kind create cluster

kind-load-images:
	kubectl config get-contexts kind-kind --no-headers=true | grep -E "^\* +kind-kind" || false
	docker pull docker.io/linuxserver/mariadb:latest
	docker pull docker.io/ghostunnel/ghostunnel:latest
	docker pull $(DOCKER_REGISTRY)athenz-auth-core:latest
	docker pull $(DOCKER_REGISTRY)athenz-zms-server:latest
	docker pull $(DOCKER_REGISTRY)athenz-zts-server:latest
	docker pull $(DOCKER_REGISTRY)athenz-cli:latest
	docker pull $(DOCKER_REGISTRY)athenz-ui:latest
	docker pull docker.io/openpolicyagent/kube-mgmt:latest
	docker pull docker.io/ealen/echo-server:latest
	docker pull docker.io/envoyproxy/envoy:v1.26-latest
	docker pull docker.io/portainer/kubectl-shell:latest
	docker pull docker.io/openpolicyagent/opa:latest-static
	docker pull $(DOCKER_REGISTRY)k8s-athenz-sia:latest
	kind load docker-image \
		docker.io/linuxserver/mariadb:latest \
		docker.io/ghostunnel/ghostunnel:latest \
		$(DOCKER_REGISTRY)athenz-auth-core:latest
	kind load docker-image \
		$(DOCKER_REGISTRY)athenz-cli:latest \
		$(DOCKER_REGISTRY)athenz-ui:latest \
		$(DOCKER_REGISTRY)athenz-zms-server:latest \
		$(DOCKER_REGISTRY)athenz-zts-server:latest
	kind load docker-image \
		docker.io/ealen/echo-server:latest \
		docker.io/envoyproxy/envoy:v1.26-latest \
		docker.io/openpolicyagent/kube-mgmt:latest \
		docker.io/openpolicyagent/opa:latest-static \
		docker.io/portainer/kubectl-shell:latest \
		$(DOCKER_REGISTRY)k8s-athenz-sia:latest

kind-shutdown:
	kind delete cluster

kustomize-edit-athenz-db-image:
	[[ "$(DOCKER_REGISTRY)" = "ghcr.io/ctyano/" ]] || \
	( \
	cd athenz-db/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-db:latest=$(DOCKER_REGISTRY)athenz-db:latest \
	)

setup-athenz-db: kustomize-edit-athenz-db-image
	kubectl apply -k athenz-db/kustomize

kustomize-edit-athenz-cli-image:
	[[ "$(DOCKER_REGISTRY)" = "ghcr.io/ctyano/" ]] || \
	( \
	cd athenz-cli/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	)

setup-athenz-cli: kustomize-edit-athenz-cli-image
	kubectl apply -k athenz-cli/kustomize

kustomize-edit-athenz-zms-server-image:
	[[ "$(DOCKER_REGISTRY)" = "ghcr.io/ctyano/" ]] || \
	( \
	cd athenz-zms-server/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-auth-core:latest=$(DOCKER_REGISTRY)athenz-auth-core:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-zms-server:latest=$(DOCKER_REGISTRY)athenz-zms-server:latest \
	)

setup-athenz-zms-server: setup-athenz-db kustomize-edit-athenz-zms-server-image
	kubectl apply -k athenz-zms-server/kustomize

kustomize-edit-athenz-zts-server-image:
	[[ "$(DOCKER_REGISTRY)" = "ghcr.io/ctyano/" ]] || \
	( \
	cd athenz-zts-server/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-auth-core:latest=$(DOCKER_REGISTRY)athenz-auth-core:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-zts-server:latest=$(DOCKER_REGISTRY)athenz-zts-server:latest \
	)

setup-athenz-zts-server: setup-athenz-db setup-athenz-zms-server kustomize-edit-athenz-zts-server-image
	kubectl apply -k athenz-zts-server/kustomize

kustomize-edit-athenz-ui-image:
	[[ "$(DOCKER_REGISTRY)" = "ghcr.io/ctyano/" ]] || \
	( \
	cd athenz-ui/kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-ui:latest=$(DOCKER_REGISTRY)athenz-ui:latest \
	)

setup-athenz-ui: setup-athenz-zms-server kustomize-edit-athenz-ui-image
	kubectl apply -k athenz-ui/kustomize

setup-athenz: setup-athenz-db setup-athenz-cli setup-athenz-zms-server setup-athenz-zts-server setup-athenz-ui

deploy-athenz: copy-to-kustomization setup-athenz

check-athenz:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=300; \
i=0; \
while [ $$(( $$(kubectl -n athenz get all | grep -E "0/1" | wc -l) )) -ne 0 ]; do \
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

test-athenz-servers: test-athenz-zms-server test-athenz-zts-server
	@echo ""
	@echo "**************************************"
	@echo "***** Athenz APIs are functioning ****"
	@echo "**************************************"
	@echo ""

test-athenz-envoy:
	kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s https://client.athenz.svc.cluster.local/client2servermtls | jq -r .request"
	@echo ""
	@echo "**************************************"
	@echo "**** Envoy Showcase is functioning ***"
	@echo "**************************************"
	@echo ""

setup-athenz-identityprovider: check-athenz test-athenz-servers
	@$(MAKE) -C athenz-identityprovider register-athenz-identityprovider check-register-athenz-identityprovider setup-athenz-identityprovider

deploy-athenz-identityprovider:
	@$(MAKE) -C athenz-identityprovider deploy-athenz-identityprovider

test-athenz-identityprovider:
	@$(MAKE) -C athenz-identityprovider test-athenz-identityprovider

setup-athenz-authorizer: test-athenz-servers test-athenz-identityprovider
	@$(MAKE) -C athenz-authorizer register-athenz-authorizer check-register-athenz-authorizer

deploy-athenz-authorizer: test-athenz-identityprovider
	@$(MAKE) -C athenz-authorizer deploy-athenz-authorizer

test-athenz-authorizer:
	@$(MAKE) -C athenz-authorizer test-athenz-authorizer

setup-athenz-client: test-athenz-servers test-athenz-identityprovider
	@$(MAKE) -C athenz-client register-athenz-client check-register-athenz-client

deploy-athenz-client: test-athenz-identityprovider
	@$(MAKE) -C athenz-client deploy-athenz-client

test-athenz-client:
	@$(MAKE) -C athenz-client test-athenz-client

test-athenz: test-athenz-servers test-zms-cli test-athenz-ui test-zts-accesstoken test-policies test-verify

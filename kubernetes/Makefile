clean-certificates:
	rm -rf athenz-cli/kustomize/{keys,certs}
	rm -rf athenz-zms-server/kustomize/{keys,certs}
	rm -rf athenz-zts-server/kustomize/{keys,certs}
	rm -rf athenz-ui/kustomize/{keys,certs}
	rm -rf athenz-identityprovider/kustomize/{keys,certs}

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

load-images:
	kubectl config get-contexts kind-kind --no-headers=true | grep -E "^\* +kind-kind" || false
	kind load docker-image ghcr.io/ctyano/athenz-zms-server:latest ghcr.io/ctyano/athenz-zts-server:latest ghcr.io/ctyano/athenz-cli:latest ghcr.io/ctyano/athenz-ui:latest

setup-athenz-db:
	kubectl apply -k athenz-db/kustomize

setup-athenz-cli:
	kubectl apply -k athenz-cli/kustomize

setup-athenz-zms-server: setup-athenz-db
	kubectl apply -k athenz-zms-server/kustomize

setup-athenz-zts-server: setup-athenz-db setup-athenz-zms-server
	kubectl apply -k athenz-zts-server/kustomize

setup-athenz-ui: setup-athenz-zms-server
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
	@echo "*************************************"
	@echo "***  Athenz Deployed Successfully ***"
	@echo "*************************************"
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
	@echo "*************************************"
	@echo "**** Athenz APIs are functioning ****"
	@echo "*************************************"
	@echo ""

setup-athenz-identityprovider: test-athenz-servers
	@$(MAKE) -C athenz-identityprovider register-athenz-identityprovider setup-athenz-identityprovider test-athenz-identityprovider

test-athenz: test-athenz-servers test-zms-cli test-athenz-ui test-zts-accesstoken test-policies test-verify

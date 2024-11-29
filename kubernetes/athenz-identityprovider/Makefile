ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

clean-athenz-identityprovider:
	kubectl delete -k kustomize

register-athenz-identityprovider:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		curl \
		-sv \
		-d"{\"name\":\"$$(cat kustomize/kustomization.yaml | yq .namespace)\",\"adminUsers\":[\"user.athenz_admin\"]}" \
		-H"Content-Type: application/json" \
		--key /var/run/athenz/athenz_admin.private.pem \
		--cert /var/run/athenz/athenz_admin.cert.pem \
		"https://athenz-zms-server.athenz:4443/zms/v1/domain"
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d \
			$$(cat kustomize/kustomization.yaml | yq .namespace) \
			add-service \
			$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g') \
			0 \
			$$(cat kustomize/keys/identityprovider.public.pem | base64 | tr -d '\r\n' | tr '\+\=\/' '\.\-\_') ||:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d \
			$$(cat kustomize/kustomization.yaml | yq .namespace) \
			set-service-endpoint \
			$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g') \
			https://$$(cat kustomize/athenz-identityprovider-policy/athenz-identityprovider.env | grep -E ^IDENTITYPROVIDER_ENDPOINT_HOST | sed -e 's/IDENTITYPROVIDER_ENDPOINT_HOST=\(.*\)/\1/g')/v0/data/identityprovider
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d \
			sys.auth \
			set-domain-template \
			instance_provider \
			provider="$$(cat kustomize/kustomization.yaml | yq .namespace).$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g')" \
			dnssuffix="$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^DNS_SUFFIX | sed -e 's/DNS_SUFFIX=\(.*\)/\1/g')"
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d \
			$$(cat kustomize/kustomization.yaml | yq .namespace) \
			set-domain-template \
			instance_registration \
			instanceregisterer="user.athenz_admin" \
			service="$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g')"
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d \
			$$(cat kustomize/kustomization.yaml | yq .namespace) \
			set-domain-template \
			identity_provisioning \
			instanceprovider="sys.auth.zts" \
			service="$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g')"
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d \
			$$(cat kustomize/kustomization.yaml | yq .namespace) \
			set-domain-template \
			identity_provisioning \
			instanceprovider="$$(cat kustomize/kustomization.yaml | yq .namespace).$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g')" \
			service="$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g')"
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			show-domain
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d $$(cat kustomize/kustomization.yaml | yq .namespace) \
			show-domain

check-register-athenz-identityprovider:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		curl \
			-sf \
			-H"Content-type: application/json" \
			-H"X-Auth-Request-Preferred-Username: user.athenz_admin" \
			"https://athenz-zts-server.athenz:4443/zts/v1/domain/$$(cat kustomize/kustomization.yaml | yq .namespace)/service/$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g')" \
		&& break \
		|| echo "Waiting for ZTS to sync with ZMS..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n athenz exec deployment/athenz-cli -it -- \
			zms-cli \
				-z https://athenz-zms-server.athenz:4443/zms/v1 \
				-key /var/run/athenz/athenz_admin.private.pem \
				-cert /var/run/athenz/athenz_admin.cert.pem \
				-d $$(cat kustomize/kustomization.yaml | yq .namespace) \
				show-domain \
		kubectl -n athenz exec deployment/athenz-cli -it -- \
			zms-cli \
				-z https://athenz-zms-server.athenz:4443/zms/v1 \
				-key /var/run/athenz/athenz_admin.private.pem \
				-cert /var/run/athenz/athenz_admin.cert.pem \
				-d $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
				show-domain \
		exit 1; \
	fi; \
done
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "**  Identity Provider is functioning *"
	@echo "**************************************"
	@echo ""

setup-athenz-identityprovider: check-register-athenz-identityprovider
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		sh \
		-c \
		" \
		chmod a+rw /tmp/.*.jwt; \
		zts-svccert \
			-get-instance-register-token \
			-zts $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^ENDPOINT | sed -e 's/ENDPOINT=\(.*\)/\1/g') \
			-domain $$(cat kustomize/kustomization.yaml | yq .namespace) \
			-service $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g') \
			-provider $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)/\1/g') \
			-instance $$(cat kustomize/kustomization.yaml | yq .namespace).$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g') \
			-svc-key-file /var/run/athenz/athenz_admin.private.pem \
			-svc-cert-file /var/run/athenz/athenz_admin.cert.pem \
			-attestation-data /tmp/.identitydocument.jwt \
		"
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		cat /tmp/.identitydocument.jwt \
	| tee identitydocument.jwt
	kubectl \
		-n \
		$$(cat kustomize/athenz-identityprovider-policy/athenz-identityprovider.env | grep -E ^IDENTITYPROVIDER_NAMESPACE | sed -e 's/IDENTITYPROVIDER_NAMESPACE=\(.*\)/\1/g') \
		create \
		secret \
		generic \
		identityprovider-jwt \
		--from-file=identitydocument.jwt \
		--dry-run=client \
		-o \
		yaml \
	| tee kustomize/secret.yaml

kustomize-edit-athenz-identityprovider-image:
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	&& kustomize edit set image ghcr.io/ctyano/k8s-athenz-sia:latest=$(DOCKER_REGISTRY)k8s-athenz-sia:latest \
	) \
	fi

deploy-athenz-identityprovider: kustomize-edit-athenz-identityprovider-image
	kubectl apply -k kustomize
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n athenz get all | grep -E "pod/identityprovider-sia" | grep -Ev "Running" | wc -l) )) -eq 0 \
	&& \
	kubectl -n athenz exec deployment/identityprovider-sia -it -c sia -- \
		ls \
		-alF \
		/var/run/athenz/tls.key \
		/var/run/athenz/tls.crt \
		/var/run/athenz/ca.crt \
	) \
	&& break \
	|| echo "Waiting for Identity Provisioning..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n athenz get all | grep -E "pod/identityprovider-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz logs %% --all-containers=true ||:; \
		kubectl -n athenz get all | grep -E "pod/identityprovider-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz describe %% ||:; \
		kubectl -n athenz get all; \
		exit 1; \
	fi; \
done
	kubectl -n athenz rollout restart deployment/identityprovider-deployment

test-athenz-identityprovider-openpolicyagent:
	opa test -v kustomize/athenz-identityprovider-policy/{policy,test}/*.rego kustomize/athenz-identityprovider-policy/{policy,test}/*.yaml

test-athenz-identityprovider-openpolicyagent-coverage:
	opa test -cv kustomize/athenz-identityprovider-policy/{policy,test}/*.rego kustomize/athenz-identityprovider-policy/{policy,test}/*.yaml

test-athenz-identityprovider:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n athenz get all | grep -E "pod/identityprovider-deployment" | grep -Ev "Running" | wc -l) )) -eq 0 \
	&& \
	kubectl -n athenz exec deployment/identityprovider-deployment -it -c sia -- \
		ls \
		-alF \
		/var/run/athenz/tls.key \
		/var/run/athenz/tls.crt \
		/var/run/athenz/ca.crt \
	&& \
	kubectl -n athenz exec deployment/identityprovider-sia -it -c sia -- \
		ls \
		-alF \
		/var/run/athenz/tls.key \
		/var/run/athenz/tls.crt \
		/var/run/athenz/ca.crt \
	) \
	&& break \
	|| echo "Waiting for Identity Provisioning..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n athenz get all | grep -E "pod/identityprovider-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz logs %% --all-containers=true ||:; \
		kubectl -n athenz get all | grep -E "pod/identityprovider-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz describe %% ||:; \
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

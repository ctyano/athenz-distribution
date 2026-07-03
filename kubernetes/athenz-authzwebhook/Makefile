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

clean-athenz-authzwebhook:
	kubectl delete -k kustomize

register-athenz-authzwebhook:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		curl \
		-sv \
		-d"{\"name\":\"$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g')\",\"adminUsers\":[\"user.athenz_admin\"]}" \
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
			sys.auth \
			set-domain-template \
			instance_provider \
			provider="$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)/\1/g')" \
			dnssuffix="$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^DNS_SUFFIX | sed -e 's/DNS_SUFFIX=\(.*\)/\1/g')"
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d \
			$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			add-service \
			$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g') \
			0 \
			$$(cat kustomize/keys/authzwebhook.public.pem | base64 | tr -d '\r\n' | tr '\+\=\/' '\.\-\_') ||:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d \
			$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
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
			$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			set-domain-template \
			identity_provisioning \
			instanceprovider="$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)/\1/g')" \
			service="$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g')"
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			add-group-role \
			envoywebhookclients ||:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			add-policy \
			envoywebhookclients \
			grant get to envoywebhookclients on /jwtauthn* ||:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			add-assertion \
			envoywebhookclients \
			grant get to envoywebhookclients on /mtlsauthn* ||:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			show-domain

check-register-athenz-authzwebhook:
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
			"https://athenz-zts-server.athenz:4443/zts/v1/domain/$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g')/service/$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g')" \
		&& break \
		|| echo "Waiting for ZTS to sync with ZMS..."; \
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
	@echo "**  Athenz Authzenvoy is functioning *"
	@echo "**************************************"
	@echo ""

kustomize-edit-athenz-authzwebhook-image:
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	) \
	fi
	if [ "$(DOCKER_REGISTRY_EXTERNAL)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/k8s-athenz-sia:latest=$(DOCKER_REGISTRY_EXTERNAL)k8s-athenz-sia:latest \
	) \
	fi
	if [ "$(DOCKERIO_REGISTRY)" != "docker.io" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image docker.io/envoyproxy/envoy:v1.34-latest=$(DOCKERIO_REGISTRY)/envoyproxy/envoy:v1.34-latest \
	&& kustomize edit set image docker.io/ealen/echo-server:latest=$(DOCKERIO_REGISTRY)/ealen/echo-server:latest \
	) \
	fi

deploy-athenz-authzwebhook: kustomize-edit-athenz-authzwebhook-image
	kubectl apply -k kustomize

test-athenz-authzwebhook:
	WAITING_TIMEOUT=60s; \
	kubectl -n athenz wait --for=condition=available --timeout=$${WAITING_TIMEOUT} deployment/authzwebhook-deployment \
	|| ( \
		printf "\n\n** authzwebhook-deployment did not become available within $${WAITING_TIMEOUT} **\n\n"; \
		kubectl -n athenz get all; \
		kubectl -n athenz logs deployment/authzwebhook-deployment --all-containers=true --tail=200 ||:; \
		kubectl -n athenz describe deployment authzwebhook-deployment ||:; \
		exit 1; \
	)
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	kubectl -n athenz exec deployment/authzwebhook-deployment -it -c sia -- \
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
		kubectl -n athenz get all | grep -E "pod/authzwebhook-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz logs %% --all-containers=true ||:; \
		kubectl -n athenz get all | grep -E "pod/authzwebhook-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz describe %% ||:; \
		kubectl -n athenz get all | grep -E "pod/identityprovider-deployment-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz logs %% -c opa | grep "Identity Provider OPA Rego" ||:; \
		kubectl -n athenz get all; \
		exit 1; \
	fi; \
done
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "* Authzenvoy provisioning successful *"
	@echo "**************************************"
	@echo ""

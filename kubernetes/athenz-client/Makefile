ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

clean-athenz-client:
	kubectl delete -k kustomize

register-athenz-client:
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
			$$(cat kustomize/keys/client.public.pem | base64 | tr -d '\r\n' | tr '\+\=\/' '\.\-\_') ||:
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
			add-member \
			envoyclients \
			$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g').$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g') ||:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			add-member \
			envoywebhookclients \
			$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g').$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g') ||:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			add-member \
			authorization-proxy-clients \
			$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g').$$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^SERVICEACCOUNT | sed -e 's/SERVICEACCOUNT=\(.*\)/\1/g') ||:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-d $$(cat kustomize/athenz-sia/athenz-sia.env | grep -E ^PROVIDER_SERVICE | sed -e 's/PROVIDER_SERVICE=\(.*\)\.\(.*\)/\1/g') \
			show-domain

check-register-athenz-client:
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
	@echo "****  Athenz Client is functioning ***"
	@echo "**************************************"
	@echo ""

kustomize-edit-athenz-client-image:
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	&& kustomize edit set image ghcr.io/ctyano/k8s-athenz-sia:latest=$(DOCKER_REGISTRY)k8s-athenz-sia:latest \
	) \
	fi

deploy-athenz-client: kustomize-edit-athenz-client-image
	kubectl apply -k kustomize

test-athenz-client:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n athenz get all | grep client | grep -E "0/1" | wc -l) )) -eq 0 \
	&& \
	kubectl -n athenz exec deployment/client-deployment -it -c sia -- \
		ls \
		-alF \
		/var/run/athenz/tls.key \
		/var/run/athenz/tls.crt \
		/var/run/athenz/ca.crt \
		/var/run/athenz/athenz:role.envoyclients.cert.pem \
		/var/run/athenz/athenz:role.envoyclients.roletoken \
		/var/run/athenz/athenz:role.envoyclients.accesstoken \
	) \
	&& break \
	|| echo "Waiting for Identity Provisioning..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n athenz get all | grep -E "pod/client-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz logs %% --all-containers=true ||:; \
		kubectl -n athenz get all | grep -E "pod/client-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz describe %% ||:; \
		kubectl -n athenz get all; \
		exit 1; \
	fi; \
done
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "***  Client provisioning successful **"
	@echo "**************************************"
	@echo ""

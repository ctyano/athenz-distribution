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

clean-certificates:
	rm -rf kustomize/keys kustomize/certs

generate-ca:
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n crypki exec deployment/crypki-softhsm -it -c athenz-cli -- \
		curl \
			--cert /opt/crypki/tls-crt/client.crt \
			--key /opt/crypki/tls-crt/client.key \
			--cacert /opt/crypki/tls-crt/ca.crt \
			-s \
			"https://crypki-softhsm.crypki/v3/sig/x509-cert/keys/x509-key" \
			| jq -r .cert \
			| tee kustomize/certs/ca.cert.pem
	cat kustomize/certs/ca.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/ca.cert.pem

generate-zms: generate-ca
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n crypki exec deployment/crypki-softhsm -it -c athenz-cli -- \
		curl \
			--cert /opt/crypki/tls-crt/client.crt \
			--key /opt/crypki/tls-crt/client.key \
			--cacert /opt/crypki/tls-crt/ca.crt \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"csr\": \"$$(echo $$(cat -e kustomize/certs/zms.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\", \
				\"key_meta\": { \
					\"identifier\": \"athenz\" \
				}, \
				\"validity\": $$(( 30 * 24 * 60 * 60 )) \
			}" \
			"https://crypki-softhsm.crypki/v3/sig/x509-cert/keys/x509-key" \
			| jq -r .cert \
			| tee kustomize/certs/zms.cert.pem
	cat kustomize/certs/zms.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/zms.cert.pem

generate-zts: generate-zms
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n crypki exec deployment/crypki-softhsm -it -c athenz-cli -- \
		curl \
			--cert /opt/crypki/tls-crt/client.crt \
			--key /opt/crypki/tls-crt/client.key \
			--cacert /opt/crypki/tls-crt/ca.crt \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"csr\": \"$$(echo $$(cat -e kustomize/certs/zts.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\", \
				\"key_meta\": { \
					\"identifier\": \"athenz\" \
				}, \
				\"validity\": $$(( 30 * 24 * 60 * 60 )) \
			}" \
			"https://crypki-softhsm.crypki/v3/sig/x509-cert/keys/x509-key" \
			| jq -r .cert \
			| tee kustomize/certs/zts.cert.pem
	cat kustomize/certs/zts.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/zts.cert.pem

generate-admin: generate-ca
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n crypki exec deployment/crypki-softhsm -it -c athenz-cli -- \
		curl \
			--cert /opt/crypki/tls-crt/client.crt \
			--key /opt/crypki/tls-crt/client.key \
			--cacert /opt/crypki/tls-crt/ca.crt \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"csr\": \"$$(echo $$(cat -e kustomize/certs/athenz_admin.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\", \
				\"key_meta\": { \
					\"identifier\": \"athenz\" \
				}, \
				\"validity\": $$(( 30 * 24 * 60 * 60 )) \
			}" \
			"https://crypki-softhsm.crypki/v3/sig/x509-cert/keys/x509-key" \
			| jq -r .cert \
			| tee kustomize/certs/athenz_admin.cert.pem
	cat kustomize/certs/athenz_admin.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/athenz_admin.cert.pem

generate-ui: generate-ca
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n crypki exec deployment/crypki-softhsm -it -c athenz-cli -- \
		curl \
			--cert /opt/crypki/tls-crt/client.crt \
			--key /opt/crypki/tls-crt/client.key \
			--cacert /opt/crypki/tls-crt/ca.crt \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"csr\": \"$$(echo $$(cat -e kustomize/certs/ui.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\", \
				\"key_meta\": { \
					\"identifier\": \"athenz\" \
				}, \
				\"validity\": $$(( 30 * 24 * 60 * 60 )) \
			}" \
			"https://crypki-softhsm.crypki/v3/sig/x509-cert/keys/x509-key" \
			| jq -r .cert \
			| tee kustomize/certs/ui.cert.pem
	cat kustomize/certs/ui.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/ui.cert.pem

generate-crypki: generate-ca
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n crypki exec deployment/crypki-softhsm -it -c athenz-cli -- \
		curl \
			--cert /opt/crypki/tls-crt/client.crt \
			--key /opt/crypki/tls-crt/client.key \
			--cacert /opt/crypki/tls-crt/ca.crt \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"csr\": \"$$(echo $$(cat -e kustomize/certs/crypki.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\", \
				\"key_meta\": { \
					\"identifier\": \"athenz\" \
				}, \
				\"validity\": $$(( 30 * 24 * 60 * 60 )) \
			}" \
			"https://crypki-softhsm.crypki/v3/sig/x509-cert/keys/x509-key" \
			| jq -r .cert \
			| tee kustomize/certs/crypki.cert.pem
	cat kustomize/certs/crypki.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/crypki.cert.pem

generate-idp: generate-ca
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n crypki exec deployment/crypki-softhsm -it -c athenz-cli -- \
		curl \
			--cert /opt/crypki/tls-crt/client.crt \
			--key /opt/crypki/tls-crt/client.key \
			--cacert /opt/crypki/tls-crt/ca.crt \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"csr\": \"$$(echo $$(cat -e kustomize/certs/idp.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\", \
				\"key_meta\": { \
					\"identifier\": \"athenz\" \
				}, \
				\"validity\": $$(( 30 * 24 * 60 * 60 )) \
			}" \
			"https://crypki-softhsm.crypki/v3/sig/x509-cert/keys/x509-key" \
			| jq -r .cert \
			| tee kustomize/certs/idp.cert.pem
	cat kustomize/certs/idp.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/idp.cert.pem

generate-certificates: generate-ca generate-zms generate-zts generate-admin generate-ui generate-idp #generate-crypki

clean-crypki-softhsm:
	kubectl delete -k kustomize

setup-crypki-softhsm:

check-register-crypki-softhsm:
	@echo ""
	@echo "**************************************"
	@echo "***  Crypki SoftHSM is functioning ***"
	@echo "**************************************"
	@echo ""

kustomize-edit-crypki-softhsm-image:
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	) \
	fi
	if [ "$(DOCKER_REGISTRY_EXTERNAL)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/crypki-softhsm:latest=$(DOCKER_REGISTRY_EXTERNAL)crypki-softhsm:latest \
	&& kustomize edit set image ghcr.io/ctyano/certsigner-envoy:latest=$(DOCKER_REGISTRY_EXTERNAL)certsigner-envoy:latest \
	) \
	fi
	if [ "$(DOCKERIO_REGISTRY)" != "docker.io" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image docker.io/ghostunnel/ghostunnel:latest=$(DOCKERIO_REGISTRY)/ghostunnel/ghostunnel:latest \
	) \
	fi

deploy-crypki-softhsm: kustomize-edit-crypki-softhsm-image
	kubectl apply -k kustomize

test-crypki-softhsm:
	WAITING_TIMEOUT=60s; \
	kubectl -n crypki wait --for=condition=available --timeout=$${WAITING_TIMEOUT} deployment/crypki-softhsm \
	|| ( \
		printf "\n\n** crypki-softhsm deployment did not become available within $${WAITING_TIMEOUT} **\n\n"; \
		kubectl -n crypki get all; \
		kubectl -n crypki logs deployment/crypki-softhsm --all-containers=true --tail=200 ||:; \
		kubectl -n crypki describe deployment crypki-softhsm ||:; \
		exit 1; \
	)
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for crypki($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	kubectl -n crypki exec deployment/crypki-softhsm -it -c athenz-cli -- \
		curl \
			-s \
			--fail \
			--cert \
			/opt/crypki/tls-crt/client.crt \
			--key \
			/opt/crypki/tls-crt/client.key \
			--cacert \
			/opt/crypki/tls-crt/ca.crt \
			--resolve \
			localhost:4443:127.0.0.1 \
			https://localhost:4443/ruok \
	) \
	&& break \
	|| echo "Waiting for Crypki SoftHSM Server..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n crypki get all | grep -E "pod/crypki-softhsm-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n crypki logs %% --all-containers=true ||:; \
		kubectl -n crypki get all | grep -E "pod/crypki-softhsm-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n crypki describe %% ||:; \
		kubectl -n crypki get all; \
		exit 1; \
	fi; \
done
	kubectl -n crypki get all
	@echo ""
	@echo "**************************************"
	@echo "***  Crypki provisioning successful **"
	@echo "**************************************"
	@echo ""

ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

clean-certificates:
	rm -rf kustomize/keys kustomize/certs

generate-ca:
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n cfssl exec deployment/cfssl -it -c athenz-cli -- \
		curl \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"hosts\": [ \
					\"cfssl.cfssl\", \
					\"localhost\" \
				], \
				\"names\": [ \
					{ \
						\"OU\": \"Athenz\" \
					} \
				], \
				\"CN\": \"CFSSL Root CA\", \
				\"key\": {\
					\"algo\": \"ecdsa\", \
					\"size\": 521 \
				}, \
				\"ca\": { \
					\"expiry\": \"720h\", \
					\"pathlen\": 1, \
					\"pathlenzero\": true, \
					\"backdate\": \"1m\" \
				} \
			}" \
			"http://127.0.0.1:8888/api/v1/cfssl/init_ca" \
		| jq -r .result \
		| tee /tmp/result.json
	cat /tmp/result.json | jq -r .certificate > kustomize/certs/ca.cert.pem
	cat /tmp/result.json | jq -r .private_key > kustomize/keys/ca.key.pem
	rm /tmp/result.json
	cat kustomize/certs/ca.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/ca.cert.pem

retrieve-ca:
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n cfssl exec deployment/cfssl -it -c athenz-cli -- \
		curl \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"label\": \"primary\" \
			}" \
			"http://127.0.0.1:8888/api/v1/cfssl/info" \
		| jq -r .result.certificate \
		> kustomize/certs/ca.cert.pem
	cat kustomize/certs/ca.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/ca.cert.pem

generate-zms: generate-ca
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n cfssl exec deployment/cfssl -it -c athenz-cli -- \
		curl \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"certificate_request\": \"$$(echo $$(cat -e kustomize/certs/zms.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\" \
			}" \
			"http://127.0.0.1:8888/api/v1/cfssl/sign" \
		| jq -r .result.certificate \
		| tee kustomize/certs/zms.cert.pem
	cat kustomize/certs/zms.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/zms.cert.pem

generate-zts: generate-zms
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n cfssl exec deployment/cfssl -it -c athenz-cli -- \
		curl \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"certificate_request\": \"$$(echo $$(cat -e kustomize/certs/zts.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\" \
			}" \
			"http://127.0.0.1:8888/api/v1/cfssl/sign" \
		| jq -r .result.certificate \
		| tee kustomize/certs/zts.cert.pem
	cat kustomize/certs/zts.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/zts.cert.pem

generate-admin: generate-ca
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n cfssl exec deployment/cfssl -it -c athenz-cli -- \
		curl \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"certificate_request\": \"$$(echo $$(cat -e kustomize/certs/athenz_admin.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\" \
			}" \
			"http://127.0.0.1:8888/api/v1/cfssl/sign" \
		| jq -r .result.certificate \
		| tee kustomize/certs/athenz_admin.cert.pem
	cat kustomize/certs/athenz_admin.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/athenz_admin.cert.pem

generate-ui: generate-ca
	mkdir kustomize/keys kustomize/certs ||:
	kubectl -n cfssl exec deployment/cfssl -it -c athenz-cli -- \
		curl \
			-sXPOST \
			-H'Content-Type:application/json' \
			-d "{ \
				\"certificate_request\": \"$$(echo $$(cat -e kustomize/certs/ui.csr.pem)| sed -e 's/\$$ /\\n/g' | sed 's/\$$$$//')\" \
			}" \
			"http://127.0.0.1:8888/api/v1/cfssl/sign" \
		| jq -r .result.certificate \
		| tee kustomize/certs/ui.cert.pem
	cat kustomize/certs/ui.cert.pem | openssl x509 -noout -text
	openssl verify -CAfile kustomize/certs/ca.cert.pem kustomize/certs/ui.cert.pem

generate-certificates: generate-ca generate-zms generate-zts generate-admin generate-ui

clean-cfssl:
	kubectl delete -k kustomize

setup-cfssl:

check-register-cfssl:
	@echo ""
	@echo "**************************************"
	@echo "*** Cloudflare CFSSL is functioning **"
	@echo "**************************************"
	@echo ""

kustomize-edit-cfssl-image:
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/cfssl:latest=$(DOCKER_REGISTRY)cfssl:latest \
	&& kustomize edit set image ghcr.io/ctyano/certsigner-envoy:latest=$(DOCKER_REGISTRY)certsigner-envoy:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	) \
	fi

deploy-cfssl: kustomize-edit-cfssl-image
	kubectl apply -k kustomize

test-cfssl:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for cfssl($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n cfssl get all | grep cfssl | grep -E "0/1" | wc -l) )) -eq 0 \
	&& \
	kubectl -n cfssl exec deployment/cfssl -it -c athenz-cli -- \
		curl \
			-s \
			--fail \
			http://127.0.0.1:8888/api/v1/cfssl/health \
	) \
	&& break \
	|| echo "Waiting for CFSSL Server..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n cfssl get all | grep -E "pod/cfssl-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n cfssl logs %% --all-containers=true ||:; \
		kubectl -n cfssl get all | grep -E "pod/cfssl-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n cfssl describe %% ||:; \
		kubectl -n cfssl get all; \
		exit 1; \
	fi; \
done
	kubectl -n cfssl get all
	@echo ""
	@echo "**************************************"
	@echo "***  CFSSL provisioning successful ***"
	@echo "**************************************"
	@echo ""

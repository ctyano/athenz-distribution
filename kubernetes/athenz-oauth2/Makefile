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

clean-athenz-oauth2:
	kubectl delete -k kustomize

setup-athenz-oauth2: install-athenz-user-cert

install-athenz-user-cert: install-brew
	if [ "$$(uname -s)" = "Darwin" ]; then \
		command -v athenzusercert >/dev/null \
		|| ( \
		brew tap ctyano/athenz-user-cert https://github.com/ctyano/athenz-user-cert \
		&& HOMEBREW_NO_AUTO_UPDATE=true brew install ctyano/athenz-user-cert/athenz-user-cert \
		) \
	fi

uninstall-athenz-user-cert:
	which athenzusercert \
	&& ( \
	brew uninstall athenz-user-cert \
	&& brew untap ctyano/athenz-user-cert \
	)

athenz-user-cert: install-athenz-user-cert
	kubectl -n athenz port-forward svc/oauth2 5556:5556 >/tmp/athenz-oauth2-idp-port-forward.log 2>&1 & \
	IDPPID=$$!; \
	kubectl -n athenz port-forward svc/oauth2 8080:8080 >/tmp/athenz-oauth2-cli-port-forward.log 2>&1 & \
	CLIPID=$$!; \
	trap 'kill -15 $$IDPPID $$CLIPID >/dev/null 2>&1 ||:' EXIT; \
	kubectl -n athenz exec deployment/oauth2-deployment -c athenz-user-cert -i -- \
		athenzusercert \
			-oidc-issuer https://oauth2.athenz/dex \
			-endpoint https://athenz-zts-server.athenz:4443/zts/v1/usercert \
			-signer-tls-ca /etc/ssl/certs/ca-certificates.crt \
		;

install-brew:
	if [ "$$(uname -s)" = "Darwin" ]; then \
		command -v brew >/dev/null \
			|| /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		eval "$$(/opt/homebrew/bin/brew shellenv)" ||:; \
	fi

check-setup-athenz-oauth2:
	if [ "$$(uname -s)" = "Darwin" ]; then \
		which athenzusercert; \
	fi
	@echo ""
	@echo "**************************************"
	@echo "** Oauth2 deployment is functioning **"
	@echo "**************************************"
	@echo ""

kustomize-edit-athenz-oauth2-image:
	if [ "$(DOCKER_REGISTRY_EXTERNAL)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-user-cert:latest=$(DOCKER_REGISTRY_EXTERNAL)athenz-user-cert:latest \
	&& kustomize edit set image ghcr.io/ctyano/certsigner-envoy:latest=$(DOCKER_REGISTRY_EXTERNAL)certsigner-envoy:latest \
	) \
	fi
	if [ "$(DOCKERIO_REGISTRY)" != "docker.io" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image docker.io/dexidp/dex:latest=$(DOCKERIO_REGISTRY)/dexidp/dex:latest \
	) \
	fi

deploy-athenz-oauth2: kustomize-edit-athenz-oauth2-image check-setup-athenz-oauth2
	kubectl apply -k kustomize

register-athenz-oauth2:
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-c /etc/ssl/certs/ca-certificates.crt \
			-d keycloak \
			set-external-member-validator \
			com.yahoo.athenz.auth.impl.EmailClaimExternalMemberValidator
	sleep 1
	kubectl -n athenz exec deployment/athenz-cli -it -- \
		zms-cli \
			-z https://athenz-zms-server.athenz:4443/zms/v1 \
			-key /var/run/athenz/athenz_admin.private.pem \
			-cert /var/run/athenz/athenz_admin.cert.pem \
			-c /etc/ssl/certs/ca-certificates.crt \
			-d keycloak \
			add-member \
			admin \
			"keycloak:ext.athenz_admin@athenz.io" "keycloak:ext.athenz_user@athenz.io"

test-athenz-oauth2:
	WAITING_TIMEOUT=60s; \
	kubectl -n athenz wait --for=condition=available --timeout=$${WAITING_TIMEOUT} deployment/oauth2-deployment \
	|| ( \
		printf "\n\n** oauth2-deployment did not become available within $${WAITING_TIMEOUT} **\n\n"; \
		kubectl -n athenz get all; \
		kubectl -n athenz logs deployment/oauth2-deployment --all-containers=true --tail=200 ||:; \
		kubectl -n athenz describe deployment oauth2-deployment ||:; \
		exit 1; \
	)
	timeout -k 0 30 kubectl -n athenz port-forward deployment/oauth2-deployment 5556:5556 &
	timeout -k 0 30 kubectl -n athenz port-forward deployment/oauth2-deployment 10000:10000 &
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=30; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	kubectl -n athenz exec deployment/oauth2-deployment -it -c dex -- \
	    nc -vz 127.0.0.1 5556 \
	&& \
	kubectl -n athenz exec deployment/oauth2-deployment -it -c dex -- \
	    nc -vz 127.0.0.1 10000 \
	&& \
	kubectl -n athenz exec deployment/oauth2-deployment -it -c athenz-user-cert -- \
		/bin/sh -c " \
			echo -n password | athenzusercert \
			-oidc-issuer https://oauth2.athenz/dex \
			-endpoint https://athenz-zts-server.athenz:4443/zts/v1/usercert \
			-signer-tls-ca /etc/ssl/certs/ca-certificates.crt \
			-oidc-user athenz_admin@athenz.io \
			-oidc-password-stdin; \
			openssl x509 -in ~/.athenz/user.cert.pem -noout -text \
		" \
	) \
	&& break \
	|| echo "Waiting for Dex Identity Provider and Envoy CertSigner Proxy..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n athenz get all | grep -E "pod/oauth2-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz logs %% --all-containers=true ||:; \
		kubectl -n athenz get all | grep -E "pod/oauth2-" | sed -e 's/^\(pod\/[^ ]*\) *[0-9]\/[0-9].*/\1/g' | xargs -I%% kubectl -n athenz describe %% ||:; \
		kubectl -n athenz get all; \
		exit 1; \
	fi; \
done
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "**** Oauth2 deployment successful ****"
	@echo "**************************************"
	@echo ""

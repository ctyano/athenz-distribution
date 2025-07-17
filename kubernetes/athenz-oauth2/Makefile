ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

clean-athenz-oauth2:
	kubectl delete -k kustomize

setup-athenz-oauth2: install-athenz_user_cert

install-athenz_user_cert: install-brew
	which athenz_user_cert \
	|| ( \
	brew tap ctyano/athenz_user_cert https://github.com/ctyano/athenz_user_cert \
	&& HOMEBREW_NO_AUTO_UPDATE=true brew install ctyano/athenz_user_cert/athenz_user_cert \
	)

uninstall-athenz_user_cert:
	which athenz_user_cert \
	&& ( \
	brew uninstall athenz_user_cert \
	&& brew untap ctyano/athenz_user_cert \
	)

install-brew:
	which brew \
|| /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

check-setup-athenz-oauth2:
	which athenz_user_cert
	@echo ""
	@echo "**************************************"
	@echo "** Oauth2 deployment is functioning **"
	@echo "**************************************"
	@echo ""

kustomize-edit-athenz-oauth2-image:

deploy-athenz-oauth2: kustomize-edit-athenz-oauth2-image check-setup-athenz-oauth2
	kubectl apply -k kustomize

test-athenz-oauth2:
	timeout -k 0 30 kubectl -n athenz port-forward deployment/oauth2-deployment 5556:5556 &
	timeout -k 0 30 kubectl -n athenz port-forward deployment/oauth2-deployment 10000:10000 &
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=30; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n athenz get all | grep oauth2 | grep -E "0/1" | wc -l) )) -eq 0 \
	&& \
	kubectl -n athenz exec deployment/oauth2-deployment -it -c dex -- \
	    nc -vz 127.0.0.1 5556 \
	&& \
	kubectl -n athenz exec deployment/oauth2-deployment -it -c dex -- \
	    nc -vz 127.0.0.1 10000 \
	&& \
	athenz_user_cert \
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

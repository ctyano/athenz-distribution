ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif

clean-athenz-loadtest:
	kubectl delete -k kustomize

kustomize-edit-athenz-loadtest-image:
	[[ "$(DOCKER_REGISTRY)" = "ghcr.io/ctyano/" ]] || \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	&& kustomize edit set image ghcr.io/ctyano/k8s-athenz-sia:latest=$(DOCKER_REGISTRY)k8s-athenz-sia:latest \
	)

deploy-athenz-loadtest: kustomize-edit-athenz-loadtest-image
	kubectl apply -k kustomize

test-athenz-loadtest:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n athenz get all | grep -E "0/1" | wc -l) )) -eq 0 \
	) \
	&& break \
	|| echo "Waiting for the Pod to be ready..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n athenz get all; \
		exit 1; \
	fi; \
done
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest was deployed successfully *"
	@echo "**************************************"
	@echo ""

run-athenz-loadtest:
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2echoserver' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../client2echoserver.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2echoserverjwt' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../client2echoserverjwt.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2echoservermtls' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../client2echoservermtls.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2server' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../client2server.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2servermtls' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../client2servermtls.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2authzproxy' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../client2authzproxy.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/tokensidecar' | vegeta attack -header \"X-Athenz-Domain: athenz\" -header \"X-Athenz-Role: envoyclients\" -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../tokensidecar.html
	accesstoken=$$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken" | xargs echo -n); \
kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://authorizer.athenz.svc.cluster.local/authorizationsidecar' | vegeta attack -header \"Authorization: Bearer $${accesstoken}\" -header \"X-Athenz-Action: get\" -header \"X-Athenz-Resource: /server\" -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../authorizationsidecar.html
	accesstoken=$$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: authorization-proxy-clients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken" | xargs echo -n); \
kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://authzproxy.athenz.svc.cluster.local/echoserver' | vegeta attack -header \"Authorization: Bearer $${accesstoken}\" -header \"X-Athenz-Action: get\" -header \"X-Athenz-Resource: /echoserver\" -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../authzproxy.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/echoserver' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../echoserver.client.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://authorizer.athenz.svc.cluster.local/echoserver' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../echoserver.authorizer.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/zms/v1/domain/sys.auth/service' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../zms.html
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/zts/v1/domain/sys.auth/service' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false | vegeta report -reporter=plot" \
> ../../zts.html
	@echo ""
	@echo "**************************************"
	@echo "**  Loadtest completed successfully **"
	@echo "**************************************"
	@echo ""

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
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2server' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false" \
	| tee \
	>(vegeta plot > docs/client2server.html) \
	>(vegeta report > docs/client2server.txt) \
	>/dev/null
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2servermtls' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false" \
	| tee \
	>(vegeta plot > docs/client2servermtls.html) \
	>(vegeta report > docs/client2servermtls.txt) \
	>/dev/null
	kubectl -n athenz exec pod/vegeta -- /bin/sh -c "echo 'GET https://client.athenz.svc.cluster.local/client2authzproxy' | vegeta attack -workers=100 -rate=100 -duration=30s -keepalive false" \
	| tee \
	>(vegeta plot > docs/client2authzproxy.html) \
	>(vegeta report > docs/client2authzproxy.txt) \
	>/dev/null

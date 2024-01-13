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

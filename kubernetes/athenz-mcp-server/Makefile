clean-athenz-mcp-server:
	kubectl delete -k kustomize

deploy-athenz-mcp-server:
	kubectl apply -k kustomize

test-athenz-mcp-server:
	WAITING_TIMEOUT=90s; \
	kubectl -n athenz wait --for=condition=available --timeout=$${WAITING_TIMEOUT} deployment/athenz-mcp-server \
	|| ( \
		printf "\n\n** athenz-mcp-server did not become available within $${WAITING_TIMEOUT} **\n\n"; \
		kubectl -n athenz get all; \
		kubectl -n athenz logs deployment/athenz-mcp-server --all-containers=true --tail=200 ||:; \
		kubectl -n athenz describe deployment athenz-mcp-server ||:; \
		exit 1; \
	)
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "**  Athenz MCP Server is functioning **"
	@echo "**************************************"
	@echo ""

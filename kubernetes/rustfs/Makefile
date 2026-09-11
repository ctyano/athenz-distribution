ifeq ($(DOCKERIO_REGISTRY),)
DOCKERIO_REGISTRY=docker.io
endif

RUSTFS_BUCKET=zms-domains
WAITING_TIMEOUT=90s
COREDNS_NAMESPACE=kube-system
COREDNS_CONFIGMAP=coredns
COREDNS_DEPLOYMENT=coredns

clean-rustfs: clean-patch-coredns-rustfs
	kubectl delete -k kustomize ||:

patch-coredns-rustfs:
	@CURRENT=$$(kubectl -n $(COREDNS_NAMESPACE) get configmap $(COREDNS_CONFIGMAP) -o jsonpath='{.data.Corefile}' 2>/dev/null); \
	if [ -z "$$CURRENT" ]; then \
		echo "WARNING: $(COREDNS_NAMESPACE)/$(COREDNS_CONFIGMAP) ConfigMap not found; skipping CoreDNS patch (this cluster may not use CoreDNS)."; \
		exit 0; \
	fi; \
	case "$$CURRENT" in \
		*"rustfs.athenz"*) echo "CoreDNS rewrite rule for rustfs.athenz is already present, skipping" ;; \
		*) NEW=$$(printf '%s\n' "$$CURRENT" | awk '{print} /^    ready$$/{print "    rewrite name regex ^[a-zA-Z0-9-]+\\.rustfs\\.athenz(\\.athenz\\.svc\\.cluster\\.local|\\.svc\\.cluster\\.local|\\.cluster\\.local)?\\.?$$ rustfs.athenz.svc.cluster.local. answer auto"}'); \
		   kubectl -n $(COREDNS_NAMESPACE) get configmap $(COREDNS_CONFIGMAP) -o json \
		     | jq --arg corefile "$$NEW" '.data.Corefile = $$corefile' \
		     | kubectl apply -f - \
		   && kubectl -n $(COREDNS_NAMESPACE) rollout restart deployment/$(COREDNS_DEPLOYMENT) \
		   && kubectl -n $(COREDNS_NAMESPACE) rollout status deployment/$(COREDNS_DEPLOYMENT) --timeout=$(WAITING_TIMEOUT) ;; \
	esac

clean-patch-coredns-rustfs:
	@CURRENT=$$(kubectl -n $(COREDNS_NAMESPACE) get configmap $(COREDNS_CONFIGMAP) -o jsonpath='{.data.Corefile}' 2>/dev/null); \
	if [ -z "$$CURRENT" ]; then exit 0; fi; \
	case "$$CURRENT" in \
		*"rustfs.athenz"*) \
			NEW=$$(printf '%s\n' "$$CURRENT" | grep -v "rustfs.athenz"); \
			kubectl -n $(COREDNS_NAMESPACE) get configmap $(COREDNS_CONFIGMAP) -o json \
			  | jq --arg corefile "$$NEW" '.data.Corefile = $$corefile' \
			  | kubectl apply -f - ||:; \
			kubectl -n $(COREDNS_NAMESPACE) rollout restart deployment/$(COREDNS_DEPLOYMENT) ||: ;; \
		*) : ;; \
	esac

kustomize-edit-rustfs-image:
	if [ "$(DOCKERIO_REGISTRY)" != "docker.io" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image docker.io/rustfs/rustfs:latest=$(DOCKERIO_REGISTRY)/rustfs/rustfs:latest \
	&& kustomize edit set image docker.io/amazon/aws-cli:latest=$(DOCKERIO_REGISTRY)/amazon/aws-cli:latest \
	) \
	fi

setup-rustfs: kustomize-edit-rustfs-image
	kubectl apply -k kustomize

deploy-rustfs: setup-rustfs patch-coredns-rustfs
	kubectl -n athenz rollout status statefulset/rustfs --timeout=$(WAITING_TIMEOUT) \
	|| ( \
		printf "\n\n** rustfs did not become ready within $(WAITING_TIMEOUT) **\n\n"; \
		kubectl -n athenz get all -l app.kubernetes.io/instance=rustfs; \
		kubectl -n athenz logs statefulset/rustfs --all-containers=true --tail=200 ||:; \
		exit 1; \
	)
	kubectl -n athenz run rustfs-create-bucket-$$(date +%s) --rm -i --restart=Never \
		--image=$(DOCKERIO_REGISTRY)/amazon/aws-cli:latest \
		--env="AWS_ACCESS_KEY_ID=$$(kubectl -n athenz get secret rustfs-credentials -o jsonpath='{.data.RUSTFS_ACCESS_KEY}' | base64 -d)" \
		--env="AWS_SECRET_ACCESS_KEY=$$(kubectl -n athenz get secret rustfs-credentials -o jsonpath='{.data.RUSTFS_SECRET_KEY}' | base64 -d)" \
		--env="AWS_DEFAULT_REGION=us-east-1" \
		--command \
		-- \
		/bin/sh -c ' \
			until aws --endpoint-url http://rustfs.athenz:9000 s3api list-buckets >/dev/null 2>&1; do \
				echo "Waiting for rustfs..."; \
				sleep 2; \
			done; \
			aws --endpoint-url http://rustfs.athenz:9000 s3api head-bucket --bucket $(RUSTFS_BUCKET) >/dev/null 2>&1 || \
				aws --endpoint-url http://rustfs.athenz:9000 s3api create-bucket --bucket $(RUSTFS_BUCKET) \
		' \
	|| ( \
		printf "\n\n** failed to create bucket $(RUSTFS_BUCKET) on rustfs **\n\n"; \
		exit 1; \
	)
	@echo ""
	@echo "**************************************"
	@echo "****   RustFS Deployed Successfully  *"
	@echo "**************************************"
	@echo ""

test-rustfs:
	kubectl -n athenz run rustfs-aws-cli-test-$$(date +%s) --rm -i --restart=Never \
		--image=$(DOCKERIO_REGISTRY)/amazon/aws-cli:latest \
		--env="AWS_ACCESS_KEY_ID=$$(kubectl -n athenz get secret rustfs-credentials -o jsonpath='{.data.RUSTFS_ACCESS_KEY}' | base64 -d)" \
		--env="AWS_SECRET_ACCESS_KEY=$$(kubectl -n athenz get secret rustfs-credentials -o jsonpath='{.data.RUSTFS_SECRET_KEY}' | base64 -d)" \
		--env="AWS_DEFAULT_REGION=us-east-1" \
		-- \
		--endpoint-url http://rustfs.athenz:9000 s3api head-bucket --bucket $(RUSTFS_BUCKET)
	@echo ""
	@echo "**************************************"
	@echo "*****   RustFS is functioning   ******"
	@echo "**************************************"
	@echo ""

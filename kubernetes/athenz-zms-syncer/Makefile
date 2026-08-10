ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif
ifeq ($(DOCKERIO_REGISTRY),)
DOCKERIO_REGISTRY=docker.io
endif

RUSTFS_BUCKET=zms-domains
JOB_NAME := athenz-zms-syncer-manual-$(shell date +%s)

clean-athenz-zms-syncer:
	kubectl delete -k kustomize ||:

kustomize-edit-athenz-zms-syncer-image:
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/athenz-zms-syncer:latest=$(DOCKER_REGISTRY)athenz-zms-syncer:latest \
	&& kustomize edit set image ghcr.io/ctyano/athenz-cli:latest=$(DOCKER_REGISTRY)athenz-cli:latest \
	) \
	fi

setup-athenz-zms-syncer: kustomize-edit-athenz-zms-syncer-image
	kubectl apply -k kustomize

# Triggers one immediate run of the CronJob's pod template, so the showcase
# doesn't have to wait for the schedule to fire.
deploy-athenz-zms-syncer: setup-athenz-zms-syncer
	kubectl -n athenz create job --from=cronjob/athenz-zms-syncer $(JOB_NAME)
	$(MAKE) wait-athenz-zms-syncer-job JOB_NAME=$(JOB_NAME)

wait-athenz-zms-syncer-job:
	WAITING_TIMEOUT=120s; \
	kubectl -n athenz wait --for=condition=complete --timeout=$${WAITING_TIMEOUT} job/$(JOB_NAME) \
	|| ( \
		printf "\n\n** job/$(JOB_NAME) did not complete within $${WAITING_TIMEOUT} **\n\n"; \
		kubectl -n athenz get all -l app.kubernetes.io/instance=athenz-zms-syncer; \
		kubectl -n athenz logs job/$(JOB_NAME) --all-containers=true --tail=200 ||:; \
		exit 1; \
	)
	@echo ""
	@echo "**************************************"
	@echo "**  ZMS Domain Syncer ran successfully *"
	@echo "**************************************"
	@echo ""

# kubectl run --rm -i's attach-then-stream-logs fallback is unreliable for
# containers that finish almost instantly (a known kubectl quirk), so this
# creates the pod, waits for it to finish, reads its logs, then deletes it --
# rather than relying on --rm -i to stream output live.
show-athenz-zms-syncer-status:
	@NAME=zms-syncer-status-$$(date +%s); \
	kubectl -n athenz run $$NAME --restart=Never \
		--image=$(DOCKER_REGISTRY)athenz-cli:latest \
		--overrides='{"apiVersion":"v1","spec":{"volumes":[{"name":"state","persistentVolumeClaim":{"claimName":"athenz-zms-syncer-state","readOnly":true}}],"containers":[{"name":"'"$$NAME"'","image":"$(DOCKER_REGISTRY)athenz-cli:latest","command":["cat","/state/run_state.json"],"volumeMounts":[{"name":"state","mountPath":"/state","readOnly":true}]}]}}' >/dev/null; \
	kubectl -n athenz wait --for=jsonpath='{.status.phase}'=Succeeded --timeout=30s pod/$$NAME >/dev/null; \
	kubectl -n athenz logs $$NAME | jq .; \
	kubectl -n athenz delete pod $$NAME --ignore-not-found >/dev/null

test-athenz-zms-syncer:
	kubectl -n athenz run zms-syncer-aws-cli-test-$$(date +%s) --rm -i --restart=Never \
		--image=$(DOCKERIO_REGISTRY)/amazon/aws-cli:latest \
		--env="AWS_ACCESS_KEY_ID=$$(kubectl -n athenz get secret rustfs-credentials -o jsonpath='{.data.RUSTFS_ACCESS_KEY}' | base64 -d)" \
		--env="AWS_SECRET_ACCESS_KEY=$$(kubectl -n athenz get secret rustfs-credentials -o jsonpath='{.data.RUSTFS_SECRET_KEY}' | base64 -d)" \
		--env="AWS_DEFAULT_REGION=us-east-1" \
		--command \
		-- \
		/bin/sh -c "aws --endpoint-url http://rustfs.athenz:9000 s3 ls s3://$(RUSTFS_BUCKET)/ | grep -q sys.auth"
	@echo ""
	@echo "**************************************"
	@echo "**** ZMS Domain Syncer is functioning ***"
	@echo "**************************************"
	@echo ""

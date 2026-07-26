ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/ctyano/
endif
ifeq ($(DOCKERIO_REGISTRY),)
DOCKERIO_REGISTRY=docker.io
endif

RUSTFS_BUCKET=zms-domains
MANUAL_JOB_NAME_FILE=.manual-job-name

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
	JOB_NAME=athenz-zms-syncer-manual-$$(date +%s); \
	kubectl -n athenz create job --from=cronjob/athenz-zms-syncer $${JOB_NAME}; \
	echo $${JOB_NAME} > $(MANUAL_JOB_NAME_FILE)
	@$(MAKE) wait-athenz-zms-syncer-job

wait-athenz-zms-syncer-job:
	WAITING_TIMEOUT=120s; \
	JOB_NAME=$$(cat $(MANUAL_JOB_NAME_FILE)); \
	kubectl -n athenz wait --for=condition=complete --timeout=$${WAITING_TIMEOUT} job/$${JOB_NAME} \
	|| ( \
		printf "\n\n** job/$${JOB_NAME} did not complete within $${WAITING_TIMEOUT} **\n\n"; \
		kubectl -n athenz get all -l app.kubernetes.io/instance=athenz-zms-syncer; \
		kubectl -n athenz logs job/$${JOB_NAME} --all-containers=true --tail=200 ||:; \
		exit 1; \
	)
	@echo ""
	@echo "**************************************"
	@echo "**  ZMS Domain Syncer ran successfully *"
	@echo "**************************************"
	@echo ""

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

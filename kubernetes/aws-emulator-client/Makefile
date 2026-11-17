DOCKERIO_REGISTRY ?= docker.io
GHCR_REGISTRY ?= ghcr.io

ACCOUNT = 000000000000
DOMAIN = awsshowcase
ROLE = showcaserole
ZMS = https://athenz-zms-server.athenz:4443/zms/v1
ZTS = https://athenz-zts-server.athenz:4443/zts/v1
ZMS_CLI = kubectl -n athenz exec deployment/athenz-cli -- zms-cli -z $(ZMS)
CLIENT = kubectl -n athenz exec deployment/aws-emulator-client -c aws-cli --

.PHONY: setup-aws-emulator-client register-aws-emulator-client deploy-aws-emulator-client test-aws-emulator-client clean-aws-emulator-client

setup-aws-emulator-client:
	cd kustomize && kustomize edit set image docker.io/amazon/aws-cli:latest=$(DOCKERIO_REGISTRY)/amazon/aws-cli:latest ghcr.io/ctyano/k8s-athenz-sia:awsimds=$(GHCR_REGISTRY)/ctyano/k8s-athenz-sia:awsimds
	kubectl apply -k kustomize

register-aws-emulator-client:
	@$(ZMS_CLI) -d $(DOMAIN) show-domain $(DOMAIN) >/dev/null 2>&1 || \
		kubectl -n athenz exec deployment/athenz-cli -- curl -fsS \
		--key /var/run/athenz/athenz_admin.private.pem --cert /var/run/athenz/athenz_admin.cert.pem \
		-H 'Content-Type: application/json' -d '{"name":"$(DOMAIN)","adminUsers":["user.athenz_admin"]}' $(ZMS)/domain
	$(ZMS_CLI) -d $(DOMAIN) set-aws-account $(ACCOUNT)
	$(ZMS_CLI) -d athenz set-domain-template identity_provisioning instanceprovider=athenz.identityprovider service=aws-emulator-client
	@$(ZMS_CLI) -d $(DOMAIN) show-role assumers >/dev/null 2>&1 || \
		$(ZMS_CLI) -d $(DOMAIN) add-regular-role assumers
	$(ZMS_CLI) -d $(DOMAIN) add-member assumers athenz.aws-emulator-client
	@$(ZMS_CLI) -d $(DOMAIN) show-policy allowassume >/dev/null 2>&1 || \
		$(ZMS_CLI) -d $(DOMAIN) add-policy allowassume grant assume_aws_role to assumers on $(ROLE)

deploy-aws-emulator-client:
	$(MAKE) register-aws-emulator-client
	$(MAKE) setup-aws-emulator-client
	kubectl -n athenz rollout status deployment/aws-emulator-client --timeout=180s

test-aws-emulator-client: SHELL := /bin/bash
test-aws-emulator-client:
	set -o pipefail; \
	SLEEP_SECONDS=5; \
	WAITING_THRESHOLD=120; \
	elapsed_seconds=0; \
	while true; do \
		printf '\n***** Waiting for AWS temporary credentials (%ss/%ss) *****\n' "$$elapsed_seconds" "$${WAITING_THRESHOLD}"; \
		$(CLIENT) sh -ec ' \
			token=$$(curl -fsS --max-time 5 -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 60" http://127.0.0.1:1338/latest/api/token); \
			curl -fsS --max-time 5 -H "X-aws-ec2-metadata-token: $$token" http://127.0.0.1:1338/latest/meta-data/iam/security-credentials/$(ROLE)' \
			| jq -e 'select(.Code == "Success" and ([.AccessKeyId, .SecretAccessKey, .Token, .Expiration] | all(type == "string" and length > 0))) | {AccessKeyId, SecretAccessKey, SessionToken: .Token, Expiration}' \
			&& break \
			|| echo 'Waiting for SIA to provide AWS temporary credentials...'; \
		sleep $${SLEEP_SECONDS}; \
		elapsed_seconds=$$((elapsed_seconds + SLEEP_SECONDS)); \
		if [ "$$elapsed_seconds" -ge "$${WAITING_THRESHOLD}" ]; then \
			printf '\n\n** Waiting (%ss) reached to threshold (%ss) **\n\n' "$$elapsed_seconds" "$${WAITING_THRESHOLD}"; \
			kubectl -n athenz logs deployment/aws-emulator-client --all-containers=true --tail=200 ||:; \
			kubectl -n athenz describe deployment aws-emulator-client ||:; \
			kubectl -n athenz get all; \
			exit 1; \
		fi; \
	done
	@printf '\n***** AWS CLI automatic credentials retrieval from SIA *****\n'
	set -o pipefail; \
	$(CLIENT) env | grep -E '^AWS_(EC2_METADATA_SERVICE_ENDPOINT|EC2_METADATA_V1_DISABLED|DEFAULT_REGION|ENDPOINT_URL)='
	set -o pipefail; \
	$(CLIENT) aws configure list \
		| awk '{ print } $$1 == "access_key" && /iam-role/ { imds_credentials_found=1 } END { exit !imds_credentials_found }'
	set -o pipefail; \
	$(CLIENT) aws sts get-caller-identity \
		| jq -e --arg account $(ACCOUNT) --arg role $(ROLE) \
		'select(.Account == $$account and .Arn == ("arn:aws:sts::" + $$account + ":assumed-role/" + $$role + "/athenz.aws-emulator-client"))'
	set -o pipefail; \
	$(CLIENT) curl -sS --key /var/run/athenz/tls.key --cert /var/run/athenz/tls.crt \
		--cacert /etc/ssl/certs/ca-certificates.crt -o /dev/null -w '%{http_code}\n' $(ZTS)/domain/$(DOMAIN)/role/unauthorized/creds \
		| jq -e 'select(. == 403)'
	kubectl -n athenz get all
	@echo ""
	@echo "****************************************"
	@echo "*** AWS Emulator Client is functioning ***"
	@echo "****************************************"
	@echo ""

clean-aws-emulator-client:
	kubectl delete -k kustomize --ignore-not-found

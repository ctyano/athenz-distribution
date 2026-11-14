DOCKERIO_REGISTRY ?= docker.io
GHCR_REGISTRY ?= ghcr.io

ACCOUNT = 000000000000
DOMAIN = awsshowcase
ROLE = showcaserole
ZMS = https://athenz-zms-server.athenz:4443/zms/v1
ZTS = https://athenz-zts-server.athenz:4443/zts/v1
EMULATOR = http://aws-emulator.athenz:9298
ZMS_CLI = kubectl -n athenz exec deployment/athenz-cli -- zms-cli -z $(ZMS)
AWS_CLI = kubectl -n athenz exec deployment/aws-emulator -c aws-cli -- aws
CLIENT = kubectl -n athenz exec deployment/aws-emulator-client -c aws-cli --

.PHONY: setup-aws-emulator deploy-aws-emulator register-aws-emulator test-aws-emulator clean-aws-emulator

setup-aws-emulator:
	kustomize edit set image docker.io/envoyproxy/envoy:v1.34-latest=$(DOCKERIO_REGISTRY)/envoyproxy/envoy:v1.34-latest docker.io/amazon/aws-cli:latest=$(DOCKERIO_REGISTRY)/amazon/aws-cli:latest ghcr.io/ctyano/docker-aws-emulator:latest=$(GHCR_REGISTRY)/ctyano/docker-aws-emulator:latest ghcr.io/ctyano/k8s-athenz-sia:awsimds=$(GHCR_REGISTRY)/ctyano/k8s-athenz-sia:awsimds
	cd client && kustomize edit set image docker.io/amazon/aws-cli:latest=$(DOCKERIO_REGISTRY)/amazon/aws-cli:latest ghcr.io/ctyano/k8s-athenz-sia:awsimds=$(GHCR_REGISTRY)/ctyano/k8s-athenz-sia:awsimds
	kubectl apply -k .
	kubectl -n athenz rollout status deployment/aws-emulator --timeout=180s

register-aws-emulator:
	@$(AWS_CLI) iam get-role --role-name $(ROLE) >/dev/null 2>&1 || \
		$(AWS_CLI) iam create-role --role-name $(ROLE) --assume-role-policy-document \
		'{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::$(ACCOUNT):root"},"Action":"sts:AssumeRole"}]}'
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

deploy-aws-emulator: setup-aws-emulator
	$(MAKE) register-aws-emulator
	kubectl apply -k ../athenz-zts-server/kustomize
	kubectl -n athenz set env deployment/athenz-zts-server --containers=athenz-zts-server \
		ATHENZ__ZTS__AWS_ENABLED=true AWS_ENDPOINT_URL_STS=$(EMULATOR) \
		AWS_EC2_METADATA_SERVICE_ENDPOINT=http://aws-emulator.athenz:1339
	kubectl -n athenz rollout status deployment/athenz-zts-server --timeout=180s
	kubectl apply -k client
	kubectl -n athenz rollout status deployment/aws-emulator-client --timeout=180s

test-aws-emulator:
	@set -eu; \
	for attempt in $$(seq 1 60); do \
		if credentials=$$($(CLIENT) sh -ec ' \
			token=$$(curl -fsS --max-time 5 -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 60" http://127.0.0.1:1338/latest/api/token); \
			curl -fsS --max-time 5 -H "X-aws-ec2-metadata-token: $$token" http://127.0.0.1:1338/latest/meta-data/iam/security-credentials/$(ROLE)' 2>/dev/null); then break; fi; \
		sleep 2; \
	done; \
	test -n "$$credentials" || { echo 'SIA did not return AWS temporary credentials' >&2; exit 1; }; \
	printf '%s\n' "$$credentials" | jq -e 'select(.Code == "Success" and ([.AccessKeyId, .SecretAccessKey, .Token, .Expiration] | all(type == "string" and length > 0))) | {AccessKeyId, SecretAccessKey, SessionToken: .Token, Expiration}'; \
	identity=$$($(CLIENT) aws sts get-caller-identity); \
	printf '%s\n' "$$identity" | jq -e --arg account $(ACCOUNT) --arg role $(ROLE) \
		'select(.Account == $$account and .Arn == ("arn:aws:sts::" + $$account + ":assumed-role/" + $$role + "/athenz.aws-emulator-client"))'; \
	status=$$($(CLIENT) curl -sS --key /var/run/athenz/tls.key --cert /var/run/athenz/tls.crt \
		--cacert /etc/ssl/certs/ca-certificates.crt -o /dev/null -w '%{http_code}' $(ZTS)/domain/$(DOMAIN)/role/unauthorized/creds); \
	test "$$status" = 403
	@echo 'SIA returned usable AWS temporary credentials and ZTS denied an unauthorized role.'

clean-aws-emulator:
	kubectl -n athenz set env deployment/athenz-zts-server --containers=athenz-zts-server \
		ATHENZ__ZTS__AWS_ENABLED- AWS_ENDPOINT_URL_STS- AWS_EC2_METADATA_SERVICE_ENDPOINT-
	kubectl -n athenz rollout status deployment/athenz-zts-server --timeout=180s
	kubectl delete -k client --ignore-not-found
	kubectl delete -k . --ignore-not-found

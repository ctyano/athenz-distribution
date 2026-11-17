DOCKERIO_REGISTRY ?= docker.io
GHCR_REGISTRY ?= ghcr.io

ACCOUNT = 000000000000
ROLE = showcaserole
EMULATOR = http://aws-emulator.athenz:9298
AWS_CLI = kubectl -n athenz exec deployment/aws-emulator -c aws-cli -- aws

.PHONY: setup-aws-emulator deploy-aws-emulator register-aws-emulator clean-aws-emulator

setup-aws-emulator:
	cd kustomize && kustomize edit set image docker.io/envoyproxy/envoy:v1.34-latest=$(DOCKERIO_REGISTRY)/envoyproxy/envoy:v1.34-latest docker.io/amazon/aws-cli:latest=$(DOCKERIO_REGISTRY)/amazon/aws-cli:latest ghcr.io/ctyano/docker-aws-emulator:latest=$(GHCR_REGISTRY)/ctyano/docker-aws-emulator:latest ghcr.io/ctyano/k8s-athenz-sia:awsimds=$(GHCR_REGISTRY)/ctyano/k8s-athenz-sia:awsimds
	kubectl apply -k kustomize
	kubectl -n athenz rollout status deployment/aws-emulator --timeout=180s

register-aws-emulator:
	@$(AWS_CLI) iam get-role --role-name $(ROLE) >/dev/null 2>&1 || \
		$(AWS_CLI) iam create-role --role-name $(ROLE) --assume-role-policy-document \
		'{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::$(ACCOUNT):root"},"Action":"sts:AssumeRole"}]}'

deploy-aws-emulator: setup-aws-emulator
	$(MAKE) register-aws-emulator
	kubectl apply -k ../athenz-zts-server/kustomize
	kubectl -n athenz set env deployment/athenz-zts-server --containers=athenz-zts-server \
		ATHENZ__ZTS__AWS_ENABLED=true AWS_ENDPOINT_URL_STS=$(EMULATOR) \
		AWS_EC2_METADATA_SERVICE_ENDPOINT=http://aws-emulator.athenz:1339
	kubectl -n athenz rollout status deployment/athenz-zts-server --timeout=180s

clean-aws-emulator:
	kubectl -n athenz set env deployment/athenz-zts-server --containers=athenz-zts-server \
		ATHENZ__ZTS__AWS_ENABLED- AWS_ENDPOINT_URL_STS- AWS_EC2_METADATA_SERVICE_ENDPOINT-
	kubectl -n athenz rollout status deployment/athenz-zts-server --timeout=180s
	kubectl delete -k kustomize --ignore-not-found

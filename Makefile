ifeq ($(wildcard athenz),)
SUBMODULE := $(shell git submodule add --force https://github.com/AthenZ/athenz.git athenz)
endif

ifeq ($(VERSION),)
VERSION := $(shell git submodule status | sed 's/^.* athenz (.*v\([0-9]*\.[0-9]*\.[0-9]*\).*)/\1/g')
endif

ifeq ($(PATCH),)
PATCH := true
endif

ifeq ($(PUSH),)
PUSH := true
endif
ifeq ($(PUSH),true)
PUSH_OPTION := --push
endif

# GID and UID of the default athenz:athenz user inside the container
GID=$(DOCKER_GID)
UID=$(DOCKER_UID)
GID_ARG := $(if $(GID),--build-arg GID=$(GID),--build-arg GID)
UID_ARG := $(if $(UID),--build-arg UID=$(UID),--build-arg UID)

BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(shell cd athenz && git rev-parse --short HEAD)
ifeq ($(XPLATFORMS),)
XPLATFORMS := linux/amd64,linux/arm64
endif
XPLATFORM_ARGS := --platform=$(XPLATFORMS)
BUILD_ARG := --build-arg 'BUILD_DATE=$(BUILD_DATE)' --build-arg 'VCS_REF=$(VCS_REF)' --build-arg 'VERSION=$(VERSION)' $(XPLATFORM_ARGS) $(PUSH_OPTION)

ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/$${USER}/
endif

ifeq ($(DOCKER_TAG),)
ifneq ($(VERSION),)
DOCKER_TAG=:v$(VERSION)
else
DOCKER_TAG=:latest
endif
endif

ifeq ($(GOPATH),)
GOPATH=$(shell go env GOPATH | sed -e "s/'//g")
export GOPATH
endif

ifeq ($(GOCACHE),)
GOCACHE=$(shell go env GOCACHE | sed -e "s/'//g")
export GOCACHE
endif

.PHONY: build

.SILENT: version

build: athenz-db athenz-zms-server athenz-zts-server athenz-cli athenz-ui

athenz-db:
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-db$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-db:latest; \
	DOCKERFILE_PATH=./docker/db/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

athenz-zms-server: build-java
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zms-server$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zms-server:latest; \
	DOCKERFILE_PATH=./docker/zms/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

athenz-zts-server: build-java
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zts-server$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zts-server:latest; \
	DOCKERFILE_PATH=./docker/zts/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

athenz-ui:
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-ui$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-ui:latest; \
	DOCKERFILE_PATH=./docker/ui/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

athenz-cli: build-go
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-cli$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-cli:latest; \
	DOCKERFILE_PATH=./docker/cli/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

install-rdl-tools:
	go install github.com/ardielle/ardielle-go/...@master && \
	go install github.com/ardielle/ardielle-tools/...@master && \
	export PATH=$$PATH:$$GOPATH
	mkdir -p athenz/clients/go/zms/bin && \
	cp $$GOPATH/bin/rdl* athenz/clients/go/zms/bin/ && \
	mkdir -p athenz/clients/go/zts/bin && \
	cp $$GOPATH/bin/rdl* athenz/clients/go/zts/bin/ && \
	mkdir -p athenz/clients/go/msd/bin && \
	cp $$GOPATH/bin/rdl* athenz/clients/go/msd/bin/ && \
	chmod a+x athenz/clients/go/*/bin/*

patch:
	$(PATCH) && rsync -av --exclude=".gitkeep" patchfiles/* athenz

build-java: checkout-version install-rdl-tools patch
	mvn -B clean install \
		-f athenz/pom.xml \
		-Dproject.basedir=athenz \
		-Dproject.build.directory=athenz \
		-Dmaven.test.skip=true \
		-Djacoco.skip=true \
		-Dcheckstyle.skip \
		-pl core/zms \
		-pl core/zts \
		-pl core/msd \
		-pl rdl/rdl-gen-athenz-java-model \
		-pl rdl/rdl-gen-athenz-java-client \
		-pl clients/java/zms \
		-pl clients/java/zts \
		-pl libs/java/auth_core \
		-pl libs/java/client_common \
		-pl libs/java/server_common \
		-pl libs/java/instance_provider \
		-pl libs/java/cert_refresher \
		-pl libs/java/dynamodb_client_factory \
		-pl rdl/rdl-gen-athenz-server \
		-pl servers/zms \
		-pl servers/zts \
		-pl containers/jetty \
		-pl assembly/zms \
		-pl assembly/zts

build-go: submodule-update install-rdl-tools
	go install github.com/ardielle/ardielle-go/...@master && \
	go install github.com/ardielle/ardielle-tools/...@master && \
	mkdir -p athenz/clients/go/zms/bin && \
	cp $$GOPATH/bin/rdl* athenz/clients/go/zms/bin/ && \
	mkdir -p athenz/clients/go/zts/bin && \
	cp $$GOPATH/bin/rdl* athenz/clients/go/zts/bin/ && \
	mkdir -p athenz/clients/go/msd/bin && \
	cp $$GOPATH/bin/rdl* athenz/clients/go/msd/bin/ && \
	mvn -B install \
		-f athenz/pom.xml \
		-Dproject.basedir=athenz \
		-Dproject.build.directory=athenz \
		-Dmaven.test.skip=true \
		-Djacoco.skip=true \
		-pl core/zms \
		-pl core/zts \
		-pl core/msd \
		-pl rdl/rdl-gen-athenz-go-model \
		-pl rdl/rdl-gen-athenz-go-client \
		-pl rdl/rdl-gen-athenz-java-model \
		-pl clients/go/zms \
		-pl clients/go/zts \
		-pl clients/go/msd \
		-pl libs/go/zmscli \
		-pl libs/go/athenzutils \
		-pl libs/go/athenzconf \
		-pl utils/zms-cli \
		-pl utils/athenz-conf \
		-pl utils/zts-accesstoken \
		-pl utils/zts-rolecert \
		-pl utils/zts-svccert \
		-pl assembly/utils

clean: checkout
	mvn -B clean \
		-f athenz/pom.xml \
		-Dproject.basedir=athenz \
		-Dproject.build.directory=athenz \
		-Dmaven.test.skip=true -Djacoco.skip=true \
		-Djacoco.skip=true

diff:
	@diff athenz patchfiles

checkout:
	@cd athenz/ && git checkout .

submodule-update: checkout
	@git submodule update --init

checkout-version: submodule-update
	@cd athenz/ && git fetch --refetch --tags origin && git checkout v$(VERSION)

version:
	@echo "Version: $(VERSION)"
	@echo "Tag Version: v$(VERSION)"

install-pathman:
	curl -s https://webi.sh/pathman | sh

install-jq: install-pathman
	curl -s https://webi.sh/jq | sh
	~/.local/bin/pathman add ~/.local/bin

install-yq: install-pathman
	curl -s https://webi.sh/yq | sh
	~/.local/bin/pathman add ~/.local/bin

install-parsers: install-jq install-yq

clean-certificates:
	rm -rf keys certs
	@$(MAKE) -f Makefile.kubernetes clean-certificates

generate-ca:
	mkdir keys certs ||:
	openssl genrsa -out keys/ca.private.pem 4096 \
	&& openssl rsa -pubout -in keys/ca.private.pem -out keys/ca.public.pem \
	&& openssl req -new -x509 -days 99999 -config openssl/ca.openssl.config -extensions ext_req -key keys/ca.private.pem -out certs/ca.cert.pem

generate-zms: generate-ca
	mkdir keys certs ||:
	openssl genrsa -out keys/zms.private.pem 4096 \
	&& openssl rsa -pubout -in keys/zms.private.pem -out keys/zms.public.pem \
	&& openssl req -config openssl/zms.openssl.config -new -key keys/zms.private.pem -out certs/zms.csr.pem -extensions ext_req \
	&& openssl x509 -req -in certs/zms.csr.pem -CA certs/ca.cert.pem -CAkey keys/ca.private.pem -CAcreateserial -out certs/zms.cert.pem -days 99999 -extfile openssl/zms.openssl.config -extensions ext_req \
	&& openssl verify -CAfile certs/ca.cert.pem certs/zms.cert.pem \
	&& openssl pkcs12 -export -out certs/zms_keystore.pkcs12 -in certs/zms.cert.pem -inkey keys/zms.private.pem -noiter -password pass:athenz \
	&& keytool -import -noprompt -file certs/ca.cert.pem -alias ca -keystore certs/zms_truststore.jks -storepass athenz \
	&& keytool --list -keystore certs/zms_truststore.jks -storepass athenz

generate-zts: generate-zms
	mkdir keys certs ||:
	openssl genrsa -out keys/zts.private.pem 4096 \
	&& openssl rsa -pubout -in keys/zts.private.pem -out keys/zts.public.pem \
	&& openssl req -config openssl/zts.openssl.config -new -key keys/zts.private.pem -out certs/zts.csr.pem -extensions ext_req \
	&& openssl x509 -req -in certs/zts.csr.pem -CA certs/ca.cert.pem -CAkey keys/ca.private.pem -CAcreateserial -out certs/zts.cert.pem -days 99999 -extfile openssl/zts.openssl.config -extensions ext_req \
	&& openssl verify -CAfile certs/ca.cert.pem certs/zts.cert.pem \
	&& openssl pkcs12 -export -out certs/zts_keystore.pkcs12 -in certs/zts.cert.pem -inkey keys/zts.private.pem -noiter -password pass:athenz \
	&& openssl pkcs12 -export -out certs/zms_client_keystore.pkcs12 -in certs/zts.cert.pem -inkey keys/zts.private.pem -noiter -password pass:athenz \
	&& openssl pkcs12 -export -out certs/zts_signer_keystore.pkcs12 -in certs/zts.cert.pem -inkey keys/zts.private.pem -noiter -password pass:athenz \
	&& keytool -import -noprompt -file certs/ca.cert.pem -alias ca -keystore certs/zts_truststore.jks -storepass athenz \
	&& keytool -import -noprompt -file certs/ca.cert.pem -alias ca -keystore certs/zms_client_truststore.jks -storepass athenz \
	&& keytool --list -keystore certs/zts_truststore.jks -storepass athenz

generate-admin: generate-ca
	mkdir keys certs ||:
	openssl genrsa -out keys/athenz_admin.private.pem 4096 \
	&& openssl rsa -pubout -in keys/athenz_admin.private.pem -out keys/athenz_admin.public.pem \
	&& openssl req -config openssl/athenz_admin.openssl.config -new -key keys/athenz_admin.private.pem -out certs/athenz_admin.csr.pem -extensions ext_req \
	&& openssl x509 -req -in certs/athenz_admin.csr.pem -CA certs/ca.cert.pem -CAkey keys/ca.private.pem -CAcreateserial -out certs/athenz_admin.cert.pem -days 99999 -extfile openssl/athenz_admin.openssl.config -extensions ext_req \
	&& openssl verify -CAfile certs/ca.cert.pem certs/athenz_admin.cert.pem

generate-certificates: generate-ca generate-zms generate-zts generate-admin

clean-k8s-athenz:
	@$(MAKE) -f Makefile.kubernetes clean-athenz

deploy-k8s-athenz: generate-certificates
	@$(MAKE) -f Makefile.kubernetes deploy-athenz

check-k8s-athenz: install-parsers
	@$(MAKE) -f Makefile.kubernetes check-athenz

test-k8s-athenz: install-parsers
	@$(MAKE) -f Makefile.kubernetes test-athenz

clean-docker-athenz: clean-certificates
	@$(MAKE) -f Makefile.docker clean-athenz

deploy-docker-athenz: build-java build-go generate-certificates
	@$(MAKE) -f Makefile.docker deploy-athenz

check-docker-athenz: install-parsers
	@$(MAKE) -f Makefile.docker check-athenz

test-docker-athenz: install-parsers
	@$(MAKE) -f Makefile.docker test-athenz

ifeq ($(wildcard athenz),)
SUBMODULE := $(shell git submodule add --force https://github.com/AthenZ/athenz.git athenz)
endif

ifeq ($(DOCKER_TAG),)
ifeq ($(VERSION),)
VERSION := $(shell git submodule status | sed 's/^.* athenz .*v\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/g')
ifeq ($(VERSION),)
VERSION := $(shell cat athenz/pom.xml | grep -E "<version>[0-9]+.[0-9]+.[0-9]+</version>" | head -n1 | sed -e 's/.*>\([0-9]*\.[0-9]*\.[0-9]*\)<.*/\1/g')
endif
DOCKER_TAG := :latest
else
DOCKER_TAG := :v$(VERSION)
endif
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
BUILD_ARG := --build-arg 'BUILD_DATE=$(BUILD_DATE)' --build-arg 'VCS_REF=$(VCS_REF)' --build-arg 'VERSION=$(VERSION)'

ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY=ghcr.io/$${USER}/
endif

ifeq ($(GOOS),)
GOOS=$(shell go env GOOS | sed -e "s/'//g")
export GOPATH
endif

ifeq ($(GOARCH),)
GOARCH=$(shell go env GOARCH | sed -e "s/'//g")
export GOPATH
endif

ifeq ($(GOPATH),)
GOPATH=$(shell go env GOPATH | sed -e "s/'//g")
export GOPATH
endif

ifeq ($(GOCACHE),)
GOCACHE=$(shell go env GOCACHE | sed -e "s/'//g")
export GOCACHE
endif

.PHONY: buildx

.SILENT: version

build: build-athenz-db build-athenz-zms-server build-athenz-zts-server build-athenz-cli build-athenz-ui

build-athenz-db:
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-db$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-db:latest; \
	DOCKERFILE_PATH=./docker/db/Dockerfile; \
	docker build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

build-athenz-zms-server: build-java
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zms-server$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zms-server:latest; \
	DOCKERFILE_PATH=./docker/zms/Dockerfile; \
	docker build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

build-athenz-zts-server: build-java
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zts-server$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zts-server:latest; \
	DOCKERFILE_PATH=./docker/zts/Dockerfile; \
	docker build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

build-athenz-ui:
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-ui$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-ui:latest; \
	DOCKERFILE_PATH=./docker/ui/Dockerfile; \
	docker build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

build-athenz-cli:
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-cli$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-cli:latest; \
	DOCKERFILE_PATH=./docker/cli/Dockerfile; \
	docker build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

buildx: buildx-athenz-db buildx-athenz-zms-server buildx-athenz-zts-server buildx-athenz-cli buildx-athenz-ui

buildx-athenz-db:
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-db$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-db:latest; \
	DOCKERFILE_PATH=./docker/db/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(XPLATFORM_ARGS) $(PUSH_OPTION) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

buildx-athenz-zms-server: build-java
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zms-server$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zms-server:latest; \
	DOCKERFILE_PATH=./docker/zms/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(XPLATFORM_ARGS) $(PUSH_OPTION) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

buildx-athenz-zts-server: build-java
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zts-server$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zts-server:latest; \
	DOCKERFILE_PATH=./docker/zts/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(XPLATFORM_ARGS) $(PUSH_OPTION) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

buildx-athenz-ui:
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-ui$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-ui:latest; \
	DOCKERFILE_PATH=./docker/ui/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(XPLATFORM_ARGS) $(PUSH_OPTION) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

buildx-athenz-cli:
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-cli$(DOCKER_TAG); \
	LATEST_IMAGE_NAME=$(DOCKER_REGISTRY)athenz-cli:latest; \
	DOCKERFILE_PATH=./docker/cli/Dockerfile; \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(XPLATFORM_ARGS) $(PUSH_OPTION) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -t $$LATEST_IMAGE_NAME -f $$DOCKERFILE_PATH .

install-rdl-tools:
	go install github.com/ardielle/ardielle-go/...@master && \
	go install github.com/ardielle/ardielle-tools/...@master && \
	export PATH=$$PATH:$$GOPATH/bin
	mkdir -p athenz/clients/go/zms/bin && \
	cp $$GOPATH/bin/rdl* athenz/clients/go/zms/bin/ && \
	mkdir -p athenz/clients/go/zts/bin && \
	cp $$GOPATH/bin/rdl* athenz/clients/go/zts/bin/ && \
	mkdir -p athenz/clients/go/msd/bin && \
	cp $$GOPATH/bin/rdl* athenz/clients/go/msd/bin/ && \
	chmod a+x athenz/clients/go/*/bin/*

patch:
	$(PATCH) && rsync -av --exclude=".gitkeep" patchfiles/* athenz

build-java: checkout-version patch install-rdl-tools
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

build-go: checkout-version install-rdl-tools
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
	@git submodule update --init --remote

checkout-version: submodule-update
	@cd athenz/ && git fetch --refetch --tags origin && git checkout v$(VERSION)

version:
	@echo "Version: $(VERSION)"
	@echo "Tag Version: v$(VERSION)"

install-pathman:
	test -e ~/.local/bin/pathman \
|| curl -sf https://webi.sh/pathman | sh

install-jq: install-pathman
	which jq \
|| (curl -sf https://webi.sh/jq | sh \
&& ~/.local/bin/pathman add ~/.local/bin)

install-yq: install-pathman
	which yq \
|| (curl -sf https://webi.sh/yq | sh \
&& ~/.local/bin/pathman add ~/.local/bin)

install-step: install-pathman
	which step \
|| (STEP_VERSION=$$(curl -sf https://api.github.com/repos/smallstep/cli/releases | jq -r .[].tag_name | grep -E '^v[0-9]*.[0-9]*.[0-9]*$$' | head -n1 | sed -e 's/.*v\([0-9]*.[0-9]*.[0-9]*\).*/\1/g') \
; curl -fL "https://github.com/smallstep/cli/releases/download/v$${STEP_VERSION}/step_$(GOOS)_$${STEP_VERSION}_$(GOARCH).tar.gz" | tar -xz -C ~/.local/bin/ \
&& ln -sf ~/.local/bin/step_$${STEP_VERSION}/bin/step ~/.local/bin/step \
&& ~/.local/bin/pathman add ~/.local/bin)

install-parsers: install-jq install-yq install-step

install-golang:
	which go \
|| (curl -sf https://webi.sh/golang | sh \
&& ~/.local/bin/pathman add ~/.local/bin)

clean-certificates:
	rm -rf keys certs

generate-ca:
	mkdir keys certs ||:
	openssl genrsa -out keys/ca.private.pem 4096
	openssl rsa -pubout -in keys/ca.private.pem -out keys/ca.public.pem
	openssl req -new -x509 -days 99999 -config openssl/ca.openssl.config -extensions ext_req -key keys/ca.private.pem -out certs/ca.cert.pem

generate-zms: generate-ca
	mkdir keys certs ||:
	openssl genrsa -out keys/zms.private.pem 4096
	openssl rsa -pubout -in keys/zms.private.pem -out keys/zms.public.pem
	openssl req -config openssl/zms.openssl.config -new -key keys/zms.private.pem -out certs/zms.csr.pem -extensions ext_req
	openssl x509 -req -in certs/zms.csr.pem -CA certs/ca.cert.pem -CAkey keys/ca.private.pem -CAcreateserial -out certs/zms.cert.pem -days 99999 -extfile openssl/zms.openssl.config -extensions ext_req
	openssl verify -CAfile certs/ca.cert.pem certs/zms.cert.pem
	openssl pkcs12 -export -noiter -out certs/zms_keystore.pkcs12 -in certs/zms.cert.pem -inkey keys/zms.private.pem -password pass:athenz
	#keytool -import -noprompt -file certs/ca.cert.pem -alias ca -keystore certs/zms_truststore.jks -storepass athenz
	#keytool --list -keystore certs/zms_truststore.jks -storepass athenz
	#openssl pkcs12 -export -noiter -out certs/zms_truststore.pkcs12 -in certs/ca.cert.pem -nokeys -caname ca -passout pass:athenz
	#openssl pkcs12 -in certs/zms_truststore.pkcs12 -cacerts -nokeys -out - -password pass:athenz | head -n3

generate-zts: generate-zms
	mkdir keys certs ||:
	openssl genrsa -out keys/zts.private.pem 4096
	openssl rsa -pubout -in keys/zts.private.pem -out keys/zts.public.pem
	openssl req -config openssl/zts.openssl.config -new -key keys/zts.private.pem -out certs/zts.csr.pem -extensions ext_req
	openssl x509 -req -in certs/zts.csr.pem -CA certs/ca.cert.pem -CAkey keys/ca.private.pem -CAcreateserial -out certs/zts.cert.pem -days 99999 -extfile openssl/zts.openssl.config -extensions ext_req
	openssl verify -CAfile certs/ca.cert.pem certs/zts.cert.pem
	openssl pkcs12 -export -noiter -out certs/zts_keystore.pkcs12 -in certs/zts.cert.pem -inkey keys/zts.private.pem -password pass:athenz
	openssl pkcs12 -export -noiter -out certs/zms_client_keystore.pkcs12 -in certs/zts.cert.pem -inkey keys/zts.private.pem -password pass:athenz
	openssl pkcs12 -export -noiter -out certs/zts_signer_keystore.pkcs12 -in certs/ca.cert.pem -inkey keys/ca.private.pem -password pass:athenz
	#keytool -import -noprompt -file certs/ca.cert.pem -alias ca -keystore certs/zts_truststore.jks -storepass athenz
	#keytool -import -noprompt -file certs/ca.cert.pem -alias ca -keystore certs/zms_client_truststore.jks -storepass athenz
	#keytool --list -keystore certs/zts_truststore.jks -storepass athenz
	#openssl pkcs12 -export -noiter -out certs/zts_truststore.pkcs12 -in certs/ca.cert.pem -nokeys -caname ca -passout pass:athenz
	#openssl pkcs12 -export -noiter -out certs/zms_client_truststore.pkcs12 -in certs/ca.cert.pem -nokeys -caname ca -passout pass:athenz
	#openssl pkcs12 -in certs/zts_truststore.pkcs12 -cacerts -nokeys -out - -password pass:athenz | head -n3
	#openssl pkcs12 -in certs/zms_client_truststore.pkcs12 -cacerts -nokeys -out - -password pass:athenz | head -n3

generate-admin: generate-ca
	mkdir keys certs ||:
	openssl genrsa -out keys/athenz_admin.private.pem 4096
	openssl rsa -pubout -in keys/athenz_admin.private.pem -out keys/athenz_admin.public.pem
	openssl req -config openssl/athenz_admin.openssl.config -new -key keys/athenz_admin.private.pem -out certs/athenz_admin.csr.pem -extensions ext_req
	openssl x509 -req -in certs/athenz_admin.csr.pem -CA certs/ca.cert.pem -CAkey keys/ca.private.pem -CAcreateserial -out certs/athenz_admin.cert.pem -days 99999 -extfile openssl/athenz_admin.openssl.config -extensions ext_req
	openssl verify -CAfile certs/ca.cert.pem certs/athenz_admin.cert.pem

generate-ui: generate-ca
	mkdir keys certs ||:
	openssl genrsa -out keys/ui.private.pem 4096
	openssl rsa -pubout -in keys/ui.private.pem -out keys/ui.public.pem
	openssl req -config openssl/ui.openssl.config -new -key keys/ui.private.pem -out certs/ui.csr.pem -extensions ext_req
	openssl x509 -req -in certs/ui.csr.pem -CA certs/ca.cert.pem -CAkey keys/ca.private.pem -CAcreateserial -out certs/ui.cert.pem -days 99999 -extfile openssl/ui.openssl.config -extensions ext_req
	openssl verify -CAfile certs/ca.cert.pem certs/ui.cert.pem

generate-certificates: generate-ca generate-zms generate-zts generate-admin generate-ui

clean-kubernetes-athenz: clean-certificates
	@$(MAKE) -C kubernetes clean-athenz

load-kubernetes-images: version
	@$(MAKE) -C kubernetes load-images

deploy-kubernetes-athenz: generate-certificates
	@$(MAKE) -C kubernetes deploy-athenz

check-kubernetes-athenz: install-parsers
	@$(MAKE) -C kubernetes check-athenz

test-kubernetes-athenz: install-parsers
	@$(MAKE) -C kubernetes test-athenz

clean-docker-athenz: clean-certificates
	@VERSION=$(VERSION) $(MAKE) -C docker clean-athenz

deploy-docker-athenz: build-java generate-certificates
	@VERSION=$(VERSION) $(MAKE) -C docker deploy-athenz

check-docker-athenz: install-parsers
	@$(MAKE) -C docker check-athenz

test-docker-athenz: install-parsers
	@$(MAKE) -C docker test-athenz

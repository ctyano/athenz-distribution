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
XPLATFORM_ARGS := --platform=linux/amd64,linux/arm64
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
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -f ./docker/db/Dockerfile .

athenz-zms-server: build-java
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zms-server$(DOCKER_TAG); \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -f ./docker/zms/Dockerfile .

athenz-zts-server: build-java
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-zts-server$(DOCKER_TAG); \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -f ./docker/zts/Dockerfile .

athenz-ui:
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-ui$(DOCKER_TAG); \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -f ./docker/ui/Dockerfile .

athenz-cli: build-go
	IMAGE_NAME=$(DOCKER_REGISTRY)athenz-cli$(DOCKER_TAG); \
	DOCKER_BUILDKIT=1 docker buildx build $(BUILD_ARG) $(GID_ARG) $(UID_ARG) --cache-from $$IMAGE_NAME -t $$IMAGE_NAME -f ./docker/cli/Dockerfile .

checkout:
	cd athenz/ && git checkout .

submodule-update: checkout
	git submodule update --init

checkout-version: submodule-update
	cd athenz/ && git fetch --refetch --tags origin && git checkout v$(VERSION)

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

version:
	echo "Version: $(VERSION)"
	echo "Tag Version: v$(VERSION)"

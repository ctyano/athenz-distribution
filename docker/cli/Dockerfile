FROM docker.io/library/golang:1-alpine AS builder

ARG VERSION=

RUN set -eux \
    && apk --no-cache add --virtual build-dependencies cmake g++ make unzip curl git

WORKDIR ${GOPATH}/src/github.com/AthenZ/athenz

ARG VERSION
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TRACKING_GIT_URL=https://github.com/AthenZ/athenz.git
ARG TRACKING_GIT_REF=

RUN set -eux; \
    case "${TARGETPLATFORM:-}" in \
        "linux/amd64") export GOARCH=amd64 ;; \
        "linux/arm64" | "linux/arm64/v8") export GOARCH=arm64 ;; \
        "linux/arm/v7") export GOARCH=arm GOARM=7 ;; \
        "") ;; \
    esac; \
    packages=" \
        utils/athenz-conf \
        utils/zms-cli \
        utils/zms-authhistory \
        utils/zms-domainattrs \
        utils/zts-idtoken \
        utils/zms-svctoken \
        utils/zpe-updater/cmd/tools \
        utils/zts-accesstoken \
        utils/zts-rolecert \
        utils/zts-roletoken \
        utils/zts-usercert \
        utils/zts-svccert \
    "; \
    if [ -n "${TRACKING_GIT_REF}" ]; then \
        git clone "${TRACKING_GIT_URL}" .; \
        ref="${TRACKING_GIT_REF}"; \
        if git fetch --force --tags origin "${ref}"; then \
            git checkout FETCH_HEAD; \
        else \
            git fetch --force --tags origin '+refs/heads/*:refs/remotes/origin/*'; \
            branch_ref="${ref#refs/heads/}"; \
            checkout_ref="${ref#refs/tags/}"; \
            if git rev-parse --verify --quiet "origin/${branch_ref}^{commit}" >/dev/null; then \
                git checkout -B "${branch_ref}" "origin/${branch_ref}"; \
            else \
                git checkout "${checkout_ref}"; \
            fi; \
        fi; \
        for package in ${packages}; do go install "./${package}"; done; \
    else \
        for package in ${packages}; do go install "github.com/AthenZ/athenz/${package}@v${VERSION}"; done; \
    fi

RUN go install github.com/smallstep/cli/cmd/step@latest

RUN apk del build-dependencies

RUN set -eux && apk update && apk add --no-cache --update tini

FROM ghcr.io/athenz-community/athenz-user-cert:latest AS athenz-user-cert
FROM docker.io/library/alpine:3

ARG VERSION
# date -u +'%Y-%m-%dT%H:%M:%SZ'
ARG BUILD_DATE
# git rev-parse --short HEAD
ARG VCS_REF

ENV VERSION=$VERSION
ENV BUILD_DATE=$BUILD_DATE
ENV VCS_REF=$VCS_REF

LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$VCS_REF
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.title="Athenz CLI"
LABEL org.opencontainers.image.authors="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.vendor="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.licenses="GPL-3.0 license"
LABEL org.opencontainers.image.url="ghcr.io/ctyano/athenz-cli"
LABEL org.opencontainers.image.documentation="https://www.athenz.io/"
LABEL org.opencontainers.image.source="https://github.com/ctyano/athenz-distribution"

ENV APP_NAME='athenz'

COPY --from=builder /sbin/tini /sbin/tini

COPY --from=builder /go/bin/athenz-conf /usr/bin/athenz-conf
COPY --from=builder /go/bin/zms-cli /usr/bin/zms-cli
COPY --from=builder /go/bin/zms-authhistory /usr/bin/zms-authhistory
COPY --from=builder /go/bin/zms-domainattrs /usr/bin/zms-domainattrs
COPY --from=builder /go/bin/zts-idtoken /usr/bin/zts-idtoken
COPY --from=builder /go/bin/zms-svctoken /usr/bin/zms-svctoken
COPY --from=builder /go/bin/tools /usr/bin/zpu
COPY --from=builder /go/bin/zts-accesstoken /usr/bin/zts-accesstoken
COPY --from=builder /go/bin/zts-rolecert /usr/bin/zts-rolecert
COPY --from=builder /go/bin/zts-roletoken /usr/bin/zts-roletoken
COPY --from=builder /go/bin/zts-usercert /usr/bin/zts-usercert
COPY --from=builder /go/bin/zts-svccert /usr/bin/zts-svccert
COPY --from=athenz-user-cert /usr/bin/athenzusercert /usr/bin/athenzusercert

COPY --from=builder /go/bin/step /usr/bin/step

RUN set -eux \
    && apk --no-cache add curl openssl tzdata tree netcat-openbsd jq yq dasel

RUN cp /usr/share/zoneinfo/Japan /etc/localtime

ARG GID=1001
ARG UID=10001

RUN addgroup -g ${GID} ${APP_NAME} && \
  adduser -S -D -H -s /sbin/nologin -u ${UID} -G ${APP_NAME} ${APP_NAME}
USER ${APP_NAME}:${APP_NAME}
WORKDIR /home/athenz

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/bin/tail", "-f", "/dev/null"]

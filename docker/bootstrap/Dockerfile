ARG VERSION

FROM ghcr.io/ctyano/athenz-cli:v${VERSION}

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
LABEL org.opencontainers.image.title="Athenz Bootstrap"
LABEL org.opencontainers.image.authors="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.vendor="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.licenses="GPL-3.0 license"
LABEL org.opencontainers.image.url="ghcr.io/ctyano/athenz-bootstrap"
LABEL org.opencontainers.image.documentation="https://www.athenz.io/"
LABEL org.opencontainers.image.source="https://github.com/ctyano/athenz-distribution"

ENV APP_NAME='athenz'

USER root:root
RUN set -eux \
    && apk --no-cache add curl openssl tzdata tree netcat-openbsd jq yq dasel make go git bash kubectl kustomize
USER ${APP_NAME}:${APP_NAME}

ARG HOMEDIR=/home/athenz
WORKDIR ${HOMEDIR}

COPY --chown=${APP_NAME}:${APP_NAME} ./athenz/.git/ ${HOMEDIR}/athenz/.git/
COPY --chown=${APP_NAME}:${APP_NAME} ./athenz/pom.xml ${HOMEDIR}/athenz/pom.xml
COPY --chown=${APP_NAME}:${APP_NAME} ./Makefile ${HOMEDIR}/Makefile
COPY --chown=${APP_NAME}:${APP_NAME} ./openssl/ ${HOMEDIR}/openssl/
COPY --chown=${APP_NAME}:${APP_NAME} ./kubernetes/ ${HOMEDIR}/kubernetes/

ENTRYPOINT ["/sbin/tini", "--"]
#CMD ["/usr/bin/make", "deploy-kubernetes-athenz"]
CMD ["/usr/bin/tail", "-f", "/dev/null"]

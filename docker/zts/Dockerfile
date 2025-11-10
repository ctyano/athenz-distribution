ARG VERSION=
# date -u +'%Y-%m-%dT%H:%M:%SZ'
ARG BUILD_DATE
# git rev-parse --short HEAD
ARG VCS_REF

ARG GID=1001
ARG UID=10001

FROM docker.io/library/openjdk:22-rc-slim-bookworm AS builder

ARG VERSION=
# date -u +'%Y-%m-%dT%H:%M:%SZ'
ARG BUILD_DATE
# git rev-parse --short HEAD
ARG VCS_REF

ARG GID=1001
ARG UID=10001

# add athenz user
RUN groupadd -g ${GID} athenz && \
  useradd -M -r -s /sbin/nologin -u ${UID} -g athenz athenz
USER athenz
WORKDIR /opt/athenz/zts
COPY athenz/assembly/zts/target/athenz-zts-${VERSION}-bin.tar.gz .
RUN tar xvzf ./athenz-zts-${VERSION}-bin.tar.gz -C /tmp \
    && mv /tmp/athenz-zts-${VERSION}*/* /opt/athenz/zts/ \
    && rm -f ./athenz-zts-${VERSION}-bin.tar.gz

FROM docker.io/library/openjdk:22-rc-slim-bookworm

ARG VERSION=
# date -u +'%Y-%m-%dT%H:%M:%SZ'
ARG BUILD_DATE
# git rev-parse --short HEAD
ARG VCS_REF

ENV VERSION=$VERSION
ENV BUILD_DATE=$BUILD_DATE
ENV VCS_REF=$VCS_REF

ARG GID=1001
ARG UID=10001

LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$VCS_REF
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.title="Athenz ZTS Server"
LABEL org.opencontainers.image.authors="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.vendor="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.licenses="GPL-3.0 license"
LABEL org.opencontainers.image.url="ghcr.io/ctyano/athenz-cli"
LABEL org.opencontainers.image.documentation="https://www.athenz.io/"
LABEL org.opencontainers.image.source="https://github.com/ctyano/athenz-distribution"

#RUN apk add --no-cache bash
RUN apt-get update
RUN apt-get -y install bash curl net-tools netcat-openbsd openssl tree git jq tzdata wget ca-certificates-java
RUN apt-get clean
RUN apt-get autoremove

RUN update-ca-certificates -v

# add athenz user
RUN groupadd -g ${GID} athenz && \
  useradd -M -r -s /sbin/nologin -u ${UID} -g athenz athenz
USER athenz

WORKDIR /opt/athenz/zts

COPY --from=builder /opt/athenz/zts /opt/athenz/zts

ENV ROOT=''
ENV JAVA_OPTS=''
ENV CLASSPATH='/opt/athenz/zts/lib/jars/*'
ENV USER_CLASSPATH='/usr/lib/jars/*'
ENV CONF_PATH='/opt/athenz/zts/conf/zts_server'

# ENV for passwords
ENV ZTS_DB_ADMIN_PASS=''
ENV ZTS_KEYSTORE_PASS=''
ENV ZTS_TRUSTSTORE_PASS=''
ENV ZTS_SIGNER_KEYSTORE_PASS=''
ENV ZTS_SIGNER_TRUSTSTORE_PASS=''
ENV ZMS_CLIENT_KEYSTORE_PASS=''
ENV ZMS_CLIENT_TRUSTSTORE_PASS=''

COPY ./docker/zts/docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# ENV for healthcheck
ENV ZTS_HOST=athenz-zts-server
ENV ZTS_PORT='8443'
ENV DEBUG=''

#HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 \
#  CMD wget -O - --quiet --tries=1 --no-check-certificate \
#  "https://127.0.0.1:${ZTS_PORT}/zts/v1/status" \
#  || exit 1

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -skf \
  --resolve ${ZTS_HOST}:${ZTS_PORT}:127.0.0.1 \
  "https://${ZTS_HOST}:${ZTS_PORT}/zts/v1/status" \
  || exit 1

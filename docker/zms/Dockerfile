ARG VERSION=
# date -u +'%Y-%m-%dT%H:%M:%SZ'
ARG BUILD_DATE
# git rev-parse --short HEAD
ARG VCS_REF

ARG GID=1001
ARG UID=10001

FROM docker.io/library/openjdk:25-rc-slim-bookworm AS builder

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
WORKDIR /opt/athenz/zms
COPY athenz/assembly/zms/target/athenz-zms-${VERSION}-bin.tar.gz .
RUN tar xvzf ./athenz-zms-${VERSION}-bin.tar.gz -C /tmp \
    && mv /tmp/athenz-zms-${VERSION}*/* /opt/athenz/zms/ \
    && rm -f ./athenz-zms-${VERSION}-bin.tar.gz

FROM docker.io/library/openjdk:25-rc-slim-bookworm

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
LABEL org.opencontainers.image.title="Athenz ZMS Server"
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

WORKDIR /opt/athenz/zms

COPY --from=builder /opt/athenz/zms /opt/athenz/zms

ENV ROOT=''
ENV JAVA_OPTS=''
ENV CLASSPATH='/opt/athenz/zms/lib/jars/*'
ENV USER_CLASSPATH='/usr/lib/jars/*'
ENV CONF_PATH='/opt/athenz/zms/conf/zms_server'

# ENV for passwords
ENV ZMS_DB_ADMIN_PASS=''
ENV ZMS_RODB_ADMIN_PASS=''
ENV ZMS_KEYSTORE_PASS=''
ENV ZMS_TRUSTSTORE_PASS=''

COPY ./docker/zms/docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# ENV for healthcheck
ENV ZMS_HOST=athenz-zms-server
ENV ZMS_PORT='4443'
ENV DEBUG ''

#HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 \
#  CMD wget -O - --quiet --tries=1 --no-check-certificate \
#  "https://127.0.0.1:${ZMS_PORT}/zms/v1/status" \
#  || exit 1

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -skf \
  --resolve ${ZMS_HOST}:${ZMS_PORT}:127.0.0.1 \
  "https://${ZMS_HOST}:${ZMS_PORT}/zms/v1/status" \
  || exit 1

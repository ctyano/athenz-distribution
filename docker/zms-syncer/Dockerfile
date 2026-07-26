ARG VERSION=
# date -u +'%Y-%m-%dT%H:%M:%SZ'
ARG BUILD_DATE
# git rev-parse --short HEAD
ARG VCS_REF

ARG GID=1001
ARG UID=10001

ARG BUILDER_IMAGE=default-jdk-base
ARG RUNTIME_IMAGE=default-jdk-base

FROM docker.io/library/openjdk:26-rc-slim-bookworm AS default-jdk-base

FROM ${BUILDER_IMAGE} AS builder

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
WORKDIR /opt/athenz/zms-syncer

# The zms_aws_domain_syncer Maven module has no assembly/shade plugin: it
# only produces a thin jar plus its runtime dependencies copied to
# target/dependency/ (maven-dependency-plugin:copy-dependencies). There is
# no -bin.tar.gz to extract like the zms/zts server images, so the jar and
# its dependencies are copied directly into a classpath directory.
COPY athenz/syncers/zms_aws_domain_syncer/target/*.jar lib/
COPY athenz/syncers/zms_aws_domain_syncer/target/dependency/ lib/

FROM ${RUNTIME_IMAGE}

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
LABEL org.opencontainers.image.title="Athenz ZMS AWS Domain Syncer"
LABEL org.opencontainers.image.authors="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.vendor="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.licenses="GPL-3.0 license"
LABEL org.opencontainers.image.url="ghcr.io/ctyano/athenz-zms-syncer"
LABEL org.opencontainers.image.documentation="https://www.athenz.io/"
LABEL org.opencontainers.image.source="https://github.com/ctyano/athenz-distribution"

RUN apt-get update
RUN apt-get -y install bash curl net-tools netcat-openbsd openssl tree git jq tzdata wget ca-certificates-java gettext-base
RUN apt-get clean
RUN apt-get autoremove

RUN update-ca-certificates -v

# add athenz user
RUN groupadd -g ${GID} athenz && \
  useradd -M -r -s /sbin/nologin -u ${UID} -g athenz athenz
USER athenz

WORKDIR /opt/athenz/zms-syncer

COPY --from=builder /opt/athenz/zms-syncer /opt/athenz/zms-syncer
COPY ./docker/zms-syncer/conf/zms_syncer.conf.template /opt/athenz/zms-syncer/conf-template/zms_syncer.conf.template

# The syncer's Config class hardcodes its config file paths relative to a
# "root_path" (the ROOT env var, default /opt) as:
#   ${root_path}/zms_syncer/conf/zms_syncer.conf
#   ${root_path}/zms_syncer/conf/athenz.conf
# ROOT is kept under this image's own (athenz-owned) working directory,
# rather than the upstream default /opt, so the syncer (running as the
# non-root athenz user) can create the config/state directories itself
# without needing root to pre-create /opt/zms_syncer.
ENV ROOT='/opt/athenz/zms-syncer'
ENV JAVA_OPTS=''

# ZMS AWS Domain Syncer configuration (see conf/zms_syncer.conf.template)
ENV AWS_BUCKET=''
ENV AWS_S3_ENDPOINT=''
ENV AWS_S3_REGION='us-east-1'
ENV AWS_CRED_KEYID=''
ENV AWS_CRED_ACCESS_KEY=''
ENV STATE_PATH='/opt/athenz/zms-syncer/var/state'
ENV KEY_FILE='/opt/athenz/zms-syncer/var/keys/zms-syncer.private.pem'
ENV CERT_FILE='/opt/athenz/zms-syncer/var/certs/zms-syncer.cert.pem'
ENV TRUSTSTORE_PATH='/opt/athenz/zms-syncer/var/truststore.jks'
ENV TRUSTSTORE_PASSWORD='athenz'
# Optional: PEM CA certificate to import into TRUSTSTORE_PATH before startup
# (needed for mTLS to a ZMS whose server certificate is signed by a private
# CA, e.g. this repository's self-signed showcase CA).
ENV CA_CERT_PEM_PATH=''
ENV DOMAIN_UPDATE_FETCH_THREADS='1'
ENV DOMAIN_REFRESH_FETCH_THREADS='1'

COPY ./docker/zms-syncer/docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

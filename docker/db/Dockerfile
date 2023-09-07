FROM docker.io/linuxserver/mariadb:latest AS builder

ARG VERSION
# date -u +'%Y-%m-%dT%H:%M:%SZ'
ARG BUILD_DATE
# git rev-parse --short HEAD
ARG VCS_REF

LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$VCS_REF
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.title="Athenz DB"
LABEL org.opencontainers.image.authors="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.vendor="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.licenses="Private"
LABEL org.opencontainers.image.url="ghcr.io/ctyano/athenz-db"
LABEL org.opencontainers.image.documentation="https://www.athenz.io/"
LABEL org.opencontainers.image.source="https://github.com/AthenZ/athenz"

COPY ./docker/db/schema/zms_user.sql /config/initdb.d
COPY ./docker/db/schema/zts_user.sql /config/initdb.d
COPY ./docker/db/schema/zms_server.sql /config/initdb.d
COPY ./docker/db/schema/zts_server.sql /config/initdb.d

ENV TZ Asia/Tokyo
ENV PUID 1000
ENV PGID 1000
ENV MYSQL_ROOT_PASSWORD ""

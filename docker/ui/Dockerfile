ARG BUILDER_IMAGE=docker.io/library/node:hydrogen-alpine
ARG RUNTIME_IMAGE=docker.io/library/node:hydrogen-alpine

FROM ${BUILDER_IMAGE} AS builder

#RUN apk add --no-cache ca-certificates net-tools wget unzip curl openssl git jq tzdata tree netcat-openbsd bash make nodejs-current npm
RUN set -eux && apk update && apk add --no-cache --update ca-certificates libstdc++ libgcc tini make git bash

WORKDIR /tmp/work

# dependency cache layer
COPY athenz/ui /tmp/work
COPY docker/ui/src/config/extended-config.js /tmp/work/src/config
COPY docker/ui/src/server/clients.js /tmp/work/src/server
COPY docker/ui/src/server/handlers/AuthStrategy.js /tmp/work/src/server/handlers
COPY docker/ui/src/pages/index.js /tmp/work/src/pages
COPY docker/ui/src/__tests__/server/handlers/AuthStrategy.test.js /tmp/work/src/__tests__/server/handlers

RUN npm install -g npm
RUN npm install --omit=dev

RUN rm -rf scripts \
    && rm -rf __mocks__ \
    && rm -rf .editorconfig \
    && rm -rf .env \
    && rm -rf .istanbul.yml \
    && rm -rf .npmrc \
    && rm -rf .prettierrc \
    && rm -rf jest.config.js \
    && rm -rf pm2.config.js \
    && rm -rf athenz-ui.spec \
    && rm -rf Makefile \
    && rm -rf pom.xml \
    && rm -rf README.md

FROM ${RUNTIME_IMAGE}

ARG VERSION=
# date -u +'%Y-%m-%dT%H:%M:%SZ'
ARG BUILD_DATE
# git rev-parse --short HEAD
ARG VCS_REF

LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$VCS_REF
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.title="Athenz UI Server"
LABEL org.opencontainers.image.authors="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.vendor="ctyano <ctyano@duck.com>"
LABEL org.opencontainers.image.licenses="GPL-3.0 license"
LABEL org.opencontainers.image.url="ghcr.io/ctyano/athenz-cli"
LABEL org.opencontainers.image.documentation="https://www.athenz.io/"
LABEL org.opencontainers.image.source="https://github.com/ctyano/athenz-distribution"

ARG APP_NAME=athenz
ARG GID=1001
ARG UID=10001

RUN set -eux \
    && apk --no-cache add ca-certificates unzip curl openssl git jq tzdata tree netcat-openbsd bash nodejs-current npm

RUN cp /usr/share/zoneinfo/Japan /etc/localtime

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /sbin/tini /sbin/tini
COPY --from=builder --chown=${UID}:${GID} /tmp/work /home/athenz

RUN mkdir -p /var/lib/sia/tokens/msd-api-access && \
  touch /var/lib/sia/tokens/msd-api-access/msd-api-access-token

# requires root permission
#RUN npm install -g npm

RUN addgroup -g ${GID} ${APP_NAME} && \
  adduser -S -D -H -s /sbin/nologin -u ${UID} -G ${APP_NAME} ${APP_NAME}
USER ${APP_NAME}:${APP_NAME}
WORKDIR /home/athenz

ENV NODE_ENV production 

RUN npm run build

RUN mkdir -p /home/athenz/keys
RUN cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 > /home/athenz/keys/cookie-session

ENV ZMS_SERVER_URL https://athenz-zms-server.athenz:4443/zms/v1/
ENV ZMS_LOGIN_URL https://athenz-zms-server.athenz:4443/zms/v1/
ENV ZMS_CONNECT_SRC_URL https://athenz-zms-server.athenz:4443
ENV ZTS_LOGIN_URL https://athenz-zts-server.athenz:4443/zts/v1/
ENV MSD_LOGIN_URL https://localhost:4443/msd/v1/
ENV UMS_LOGIN_URL https://localhost:4443/ums/v1/

ENV UI_DOMAIN_SERVICE sys.auth.webui
ENV UI_SERVICE_KEY_VERSION 0
ENV ATHENZ_PUBLIC_CERT /var/run/athenz/service.cert.pem
ENV ATHENZ_PRIVATE_KEY /var/run/athenz/service.key.pem
ENV UI_CERT_PATH /home/athenz/tls/tls.crt
ENV UI_CERT_KEY_PATH /home/athenz/tls/tls.key
ENV UI_SESSION_SECRET_PATH /home/athenz/keys/cookie-session

ENV PORT 443
ENV DEBUG ""

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "--trace-atomics-wait", "app.js"]

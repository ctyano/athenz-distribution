ARG BUILDER_IMAGE=docker.io/library/alpine:3
ARG RUNTIME_IMAGE=docker.io/library/alpine:3

#FROM --platform=${BUILDPLATFORM} ${BUILDER_IMAGE} AS builder
FROM --platform=${BUILDPLATFORM} docker.io/library/node:hydrogen-alpine AS builder

#RUN apk add --no-cache ca-certificates net-tools wget unzip curl openssl git jq tzdata tree netcat-openbsd bash make nodejs-current npm
RUN set -eux && apk update && apk add --no-cache --update ca-certificates libstdc++ libgcc tini make git bash

WORKDIR /tmp/work

# dependency cache layer
COPY athenz/ui/package.json .
RUN npm install

COPY athenz/ui /tmp/work

RUN make build

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

#FROM ${RUNTIME_IMAGE}
FROM docker.io/library/node:hydrogen-alpine

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
LABEL org.opencontainers.image.licenses="Private"
LABEL org.opencontainers.image.url="ghcr.io/ctyano/athenz-cli"
LABEL org.opencontainers.image.documentation="https://www.athenz.io/"
LABEL org.opencontainers.image.source="https://github.com/AthenZ/athenz"

ENV APP_NAME athenz

ARG GID=1001
ARG UID=10001

RUN set -eux \
    && apk --no-cache add --virtual build-dependencies ca-certificates unzip curl openssl git jq tzdata tree netcat-openbsd bash nodejs-current npm

RUN cp /usr/share/zoneinfo/Japan /etc/localtime

RUN mkdir -p /var/lib/sia/tokens/msd-api-access && touch /var/lib/sia/tokens/msd-api-access/msd-api-access-token

RUN addgroup -g ${GID} ${APP_NAME} && \
  adduser -S -D -H -s /sbin/nologin -u ${UID} -G ${APP_NAME} ${APP_NAME}
USER ${APP_NAME}:${APP_NAME}

#WORKDIR /home/athenz
WORKDIR /opt/athenz/ui

#COPY --from=builder --chown=${UID}:${GID} /tmp/work /home/athenz

#RUN npm install
#RUN npm run build
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /sbin/tini /sbin/tini
COPY --from=builder --chown=${UID}:${GID} /tmp/work /opt/athenz/ui

#ENTRYPOINT ["npm", "run", "dev"]
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["npm", "start"]

# ENV for healthcheck
ENV PORT=443

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -O - --quiet --tries=1 --no-check-certificate \
  "https://127.0.0.1:${PORT}/" \
  || exit 1

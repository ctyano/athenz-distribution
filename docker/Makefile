clean-certificates:
	rm -rf admin/{keys,certs}
	rm -rf zms/var/{keys,certs,truststore}
	rm -rf zts/var/{keys,certs,truststore}
	rm -rf ui/tls/*.*

clean-docker:
	docker compose -f docker-compose.yaml down

clean-athenz: clean-docker clean-certificates

copy-to-compose:
	mkdir -p admin zms/truststore zts/truststore zms/truststore zts/keystore ||:
	cp -r ../keys ../certs admin/
	cp -r ../keys ../certs zms/var/
	cp -r ../keys ../certs zts/var/
	cp -r ../keys/*.* ../certs/*.* ui/tls/
	chmod -R a+r admin zms/var/keys zms/var/certs zts/var/keys zts/var/certs ui/tls
	chmod -R a+rw zms/truststore zts/truststore zms/keystore zts/keystore zts/conf zts/var
	cp ../athenz/servers/zms/schema/zms_server.sql db/schema/zms_server.sql
	cp ../athenz/servers/zts/schema/zts_server.sql db/schema/zts_server.sql

build-setup-athenz:
	docker compose -f docker-compose-build.yaml up --pull always --no-start -d

setup-athenz:
	docker compose -f docker-compose.yaml up --pull always --no-start -d

build-deploy-athenz: copy-to-compose build-setup-athenz start-db start-zms start-zts check-athenz start-ui

deploy-athenz: copy-to-compose setup-athenz start-db start-zms start-zts check-athenz start-ui

start-db:
	docker compose start athenz-db
	SLEEP_SECONDS=10; \
WAITING_THRESHOLD=60; \
i=0; \
while [ $$(( $$(docker compose -f docker-compose.yaml ps athenz-db | grep -E "Up " | grep -vE "unhealthy|health:" | wc -l) )) -ne $$(( $$(docker compose -f docker-compose.yaml ps athenz-db | grep -E "Up " | wc -l) )) ]; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		docker compose -f docker-compose.yaml logs athenz-db; \
		exit 1; \
	fi; \
done
	docker compose -f docker-compose.yaml ps athenz-db
	@echo ""
	@echo "*************************************"
	@echo "*****  DB Deployed Successfully *****"
	@echo "*************************************"
	@echo ""

start-zms:
	docker compose start athenz-auth-core ||:
	docker compose start athenz-zms-server
	SLEEP_SECONDS=10; \
WAITING_THRESHOLD=60; \
i=0; \
while [ $$(( $$(docker compose -f docker-compose.yaml ps athenz-zms-server | grep -E "Up " | grep -vE "unhealthy|health:" | wc -l) )) -ne $$(( $$(docker compose -f docker-compose.yaml ps athenz-zms-server | grep -E "Up " | wc -l) )) ]; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		docker compose -f docker-compose.yaml logs athenz-zms-server; \
		exit 1; \
	fi; \
done
	docker compose -f docker-compose.yaml ps athenz-zms-server
	@echo ""
	@echo "*************************************"
	@echo "***** ZMS Deployed Successfully *****"
	@echo "*************************************"
	@echo ""

start-zts:
	docker compose start athenz-auth-core ||:
	docker compose start athenz-cli
	docker compose exec -T athenz-cli \
zms-cli \
	-c /var/run/athenz/certs/ca.cert.pem \
	-key /var/run/athenz/keys/athenz_admin.private.pem \
	-cert /var/run/athenz/certs/athenz_admin.cert.pem \
	-z https://athenz-zms-server:4443/zms/v1 \
	-d sys.auth \
	add-service zts "0" /var/zts/keys/zts.public.pem
	docker compose exec -T athenz-cli \
zms-cli \
	-c /var/run/athenz/certs/ca.cert.pem \
	-key /var/run/athenz/keys/athenz_admin.private.pem \
	-cert /var/run/athenz/certs/athenz_admin.cert.pem \
	-z https://athenz-zms-server:4443/zms/v1 \
	-d sys.auth \
	set-service-endpoint zts class://com.yahoo.athenz.instance.provider.impl.InstanceZTSProvider
	docker compose exec -T athenz-cli \
athenz-conf \
	-c /var/run/athenz/certs/ca.cert.pem \
	-svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
	-svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
	-z https://athenz-zms-server:4443/zms/v1 \
	-t https://athenz-zts-server:8443/zts/v1 \
	-o /conf/zts/athenz.conf
	docker compose start athenz-zts-server
	SLEEP_SECONDS=10; \
WAITING_THRESHOLD=60; \
i=0; \
while [ $$(( $$(docker compose -f docker-compose.yaml ps athenz-zts-server | grep -E "Up " | grep -vE "unhealthy|health:" | wc -l) )) -ne $$(( $$(docker compose -f docker-compose.yaml ps athenz-zts-server | grep -E "Up " | wc -l) )) ]; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		docker compose -f docker-compose.yaml logs athenz-zts-server; \
		exit 1; \
	fi; \
done
	docker compose -f docker-compose.yaml ps athenz-zts-server
	@echo ""
	@echo "*************************************"
	@echo "***** ZTS Deployed Successfully *****"
	@echo "*************************************"
	@echo ""

start-ui:
	docker compose start athenz-ui
	SLEEP_SECONDS=10; \
WAITING_THRESHOLD=60; \
i=0; \
while [ $$(( $$(docker compose -f docker-compose.yaml ps athenz-ui | grep -E "Up " | grep -vE "unhealthy|health:" | wc -l) )) -ne $$(( $$(docker compose -f docker-compose.yaml ps athenz-ui | grep -E "Up " | wc -l) )) ]; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		docker compose -f docker-compose.yaml logs athenz-ui; \
		exit 1; \
	fi; \
done
	docker compose -f docker-compose.yaml ps athenz-ui
	@echo ""
	@echo "*************************************"
	@echo "*****  UI Deployed Successfully *****"
	@echo "*************************************"
	@echo ""

start-ghostunnel:
	docker compose start ghostunnel
	SLEEP_SECONDS=10; \
WAITING_THRESHOLD=60; \
i=0; \
while [ $$(( $$(docker compose -f docker-compose.yaml ps ghostunnel | grep -E "Up " | grep -vE "unhealthy|health:" | wc -l) )) -ne $$(( $$(docker compose -f docker-compose.yaml ps ghostunnel | grep -E "Up " | wc -l) )) ]; do \
	printf "\n***** Waiting for ghostunnel($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		docker compose -f docker-compose.yaml logs ghostunnel; \
		exit 1; \
	fi; \
done
	docker compose -f docker-compose.yaml ps ghostunnel
	@echo ""
	@echo "*************************************"
	@echo "* Ghosttunnel Deployed Successfully *"
	@echo "*************************************"
	@echo ""

check-athenz:
	SLEEP_SECONDS=10; \
WAITING_THRESHOLD=60; \
i=0; \
while [ $$(( $$(docker compose -f docker-compose.yaml ps -a | grep -E "Up " | grep -vE "unhealthy|health:" | wc -l) )) -ne $$(( $$(docker compose -f docker-compose.yaml ps --services | wc -l) )) ]; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		docker compose -f docker-compose.yaml logs; \
		exit 1; \
	fi; \
done
	docker compose -f docker-compose.yaml ps -a
	@echo ""
	@echo "*************************************"
	@echo "***  Athenz Deployed Successfully ***"
	@echo "*************************************"
	@echo ""

test-athenz-zms-server:
	docker compose exec -T athenz-cli \
curl \
	-sf \
	-H"Content-type: application/json" \
	-H"X-Auth-Request-Preferred-Username: user.athenz_admin" \
	--cacert /var/run/athenz/certs/ca.cert.pem \
	https://athenz-zms-server:4443/zms/v1/domain
	@echo

test-athenz-zts-server:
	docker compose exec -T athenz-cli \
curl \
	-sf \
	-H"Content-type: application/json" \
	-H"X-Auth-Request-Preferred-Username: user.athenz_admin" \
	--cacert /var/run/athenz/certs/ca.cert.pem \
	https://athenz-zts-server:8443/zts/v1/domain/sys.auth/service
	@echo

test-athenz-ui:
	docker compose exec -T athenz-ui \
curl \
	-sf \
	-H"Content-type: application/json" \
	-H"X-Auth-Request-Preferred-Username: athenz_admin" \
	-H"X-Auth-Request-Email: athenz_admin@www.athenz.io" \
	--cacert /home/athenz/tls/ca.cert.pem \
	--resolve athenz-ui:443:127.0.0.1 \
	https://athenz-ui:443/ \
| grep -E "<title>Athenz</title>" >/dev/null \
&& echo "Athenz UI sccessfully displayed"

test-zms-cli:
	docker compose exec -T athenz-cli \
zms-cli \
	-z https://athenz-zms-server:4443/zms/v1 \
	-c /var/run/athenz/certs/ca.cert.pem \
	-key /var/run/athenz/keys/athenz_admin.private.pem \
	-cert /var/run/athenz/certs/athenz_admin.cert.pem \
	show-domain sys.auth

test-zts-roletoken:
	docker compose exec -T athenz-cli \
zts-roletoken \
	-zts https://athenz-zts-server:8443/zts/v1 \
	-svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
	-svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
	-svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
	-domain sys.auth \
	-role admin \
| rev | cut -d';' -f2- | rev \
| tr ';' '\n'

test-zts-accesstoken:
	docker compose exec -T athenz-cli \
zts-accesstoken \
	-zts https://athenz-zts-server:8443/zts/v1 \
	-svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
	-svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
	-svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
	-domain sys.auth \
	-roles admin \
| jq -r .access_token \
| jq -Rr 'split(".") | .[0,1] | @base64d' \
| jq -r .

test-jwks:
	docker compose exec -T athenz-cli \
curl \
	-sf \
	-H"Content-type: application/json" \
	--cacert /var/run/athenz/certs/ca.cert.pem \
	--key /var/run/athenz/keys/athenz_admin.private.pem \
	--cert /var/run/athenz/certs/athenz_admin.cert.pem \
	"https://athenz-zts-server:8443/zts/v1/oauth2/keys?rfc=true" \
| tee ./jwks.json \
| jq -r .

test-policies:
	docker compose exec -T athenz-cli \
curl \
	-sfXPOST \
	-H "Content-type: application/json" \
	-d"{\"policyVersions\":{\"\":\"\"}}" \
	--cacert /var/run/athenz/certs/ca.cert.pem \
	--key /var/run/athenz/keys/athenz_admin.private.pem \
	--cert /var/run/athenz/certs/athenz_admin.cert.pem \
	"https://athenz-zts-server:8443/zts/v1/domain/sys.auth/policy/signed" \
| jq -r '[.protected,.payload,.signature] | join(".")' \
| jq -Rr 'split(".") | .[0,1] | @base64d' \
| jq -r .

test-verify: test-jwks
	docker compose exec -T athenz-cli \
zts-accesstoken \
	-zts https://athenz-zts-server:8443/zts/v1 \
	-svc-cacert-file /var/run/athenz/certs/ca.cert.pem \
	-svc-key-file /var/run/athenz/keys/athenz_admin.private.pem \
	-svc-cert-file /var/run/athenz/certs/athenz_admin.cert.pem \
	-domain sys.auth \
	-roles admin \
| jq -r .access_token \
| step crypto jws verify --jwks=jwks.json \
&& printf "\nValid Access Token\n" || printf "\nInvalid Access Token\n"
	@echo ""
	docker compose exec -T athenz-cli \
curl \
	-sfXPOST \
	-H "Content-type: application/json" \
	-d"{\"policyVersions\":{\"\":\"\"}}" \
	--cacert /var/run/athenz/certs/ca.cert.pem \
	--key /var/run/athenz/keys/athenz_admin.private.pem \
	--cert /var/run/athenz/certs/athenz_admin.cert.pem \
	"https://athenz-zts-server:8443/zts/v1/domain/sys.auth/policy/signed" \
| jq -r '[.protected,.payload,.signature] | join(".")' \
| step crypto jws verify --jwks=jwks.json \
&& printf "\nValid Policy\n" || printf "\nInvalid Policy\n"

test-athenz-servers: test-athenz-zms-server test-athenz-zts-server
	@echo ""
	@echo "*************************************"
	@echo "**** Athenz APIs are functioning ****"
	@echo "*************************************"
	@echo ""

test-athenz: test-athenz-servers test-zms-cli test-athenz-ui test-zts-accesstoken test-policies test-verify

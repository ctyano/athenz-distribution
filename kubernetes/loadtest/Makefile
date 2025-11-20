ifeq ($(DOCKER_REGISTRY),)
DOCKER_REGISTRY := ghcr.io/ctyano/
endif
ifeq ($(PUSH),)
PUSH := false
endif
ifeq ($(PUSH),true)
REPORT_OPTION := -reporter=plot
else
REPORT_OPTION :=
endif

debug:
	@echo $(PUSH)

clean-athenz-loadtest:
	kubectl delete -k kustomize

kustomize-edit-athenz-loadtest-image:
	if [ "$(DOCKER_REGISTRY)" != "ghcr.io/ctyano/" ]; then \
	( \
	cd kustomize \
	&& kustomize edit set image ghcr.io/ctyano/docker-vegeta:latest=$(DOCKER_REGISTRY)docker-vegeta:latest \
	) \
	fi

deploy-athenz-loadtest: kustomize-edit-athenz-loadtest-image
	kubectl apply -k kustomize

test-athenz-loadtest:
	SLEEP_SECONDS=5; \
WAITING_THRESHOLD=60; \
i=0; \
while true; do \
	printf "\n***** Waiting for athenz($$(( $$i * $${SLEEP_SECONDS} ))s/$${WAITING_THRESHOLD}s) *****\n"; \
	( \
	test $$(( $$(kubectl -n athenz get all | grep -E "0/1" | wc -l) )) -eq 0 \
	) \
	&& break \
	|| echo "Waiting for the Pod to be ready..."; \
	sleep $${SLEEP_SECONDS}; \
	i=$$(( i + 1 )); \
	if [ $$i -eq $$(( $${WAITING_THRESHOLD} / $${SLEEP_SECONDS} )) ]; then \
		printf "\n\n** Waiting ($$(( $$i * $${SLEEP_SECONDS} ))s) reached to threshold($${WAITING_THRESHOLD}s) **\n\n"; \
		kubectl -n athenz get all; \
		exit 1; \
	fi; \
done
	kubectl -n athenz get all
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest was deployed successfully *"
	@echo "**************************************"
	@echo ""

run-athenz-envoy-loadtest:
	CASE=client2echoserver; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=client2extauthz; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=client2extauthzmtls; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=client2filterauthzmtls; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=client2filterauthzjwt; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=client2filterauthzmtlsjwt; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=client2webhookauthzmtls; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=client2webhookauthzjwt; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=client2webhookauthzmtlsjwt; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=client2authzproxy; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	@echo ""
	@echo "**************************************"
	@echo "**  Loadtest completed successfully **"
	@echo "**************************************"
	@echo ""

report-athenz-envoy-loadtest:
	CASE=client2echoserver; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=client2extauthz; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=client2extauthzmtls; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=client2filterauthzmtls; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=client2filterauthzjwt; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=client2filterauthzmtlsjwt; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=client2webhookauthzmtls; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=client2webhookauthzjwt; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=client2webhookauthzmtlsjwt; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=client2authzproxy; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest result is printed to html *"
	@echo "**************************************"
	@echo ""

run-athenz-sidecar-loadtest:
	CASE=tokensidecar; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/$$CASE\" | vegeta attack -header \"X-Athenz-Domain: athenz\" -header \"X-Athenz-Role: envoyclients\" -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	accesstoken=$$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken" | xargs echo -n); \
	CASE=authorizationsidecar; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://authorizer.athenz.svc.cluster.local/$$CASE\" | vegeta attack -header \"Authorization: Bearer $${accesstoken}\" -header \"X-Athenz-Action: get\" -header \"X-Athenz-Resource: /extauthz\" -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	@echo ""
	@echo "**************************************"
	@echo "**  Loadtest completed successfully **"
	@echo "**************************************"
	@echo ""

report-athenz-sidecar-loadtest:
	CASE=tokensidecar; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=authorizationsidecar; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest result is printed to html *"
	@echo "**************************************"
	@echo ""

run-athenz-envoyfilter-loadtest:
	accesstoken=$$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken" | xargs echo -n); \
	CASE=envoyjwtfilter; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://authzenvoy.athenz.svc.cluster.local/jwtauthn\" | vegeta attack -header \"Authorization: Bearer $${accesstoken}\" -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	@echo ""
	@echo "**************************************"
	@echo "**  Loadtest completed successfully **"
	@echo "**************************************"
	@echo ""

report-athenz-envoyfilter-loadtest:
	CASE=envoyjwtfilter; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest result is printed to html *"
	@echo "**************************************"
	@echo ""

run-athenz-envoywebhook-loadtest:
	accesstoken=$$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken" | xargs echo -n); \
	CASE=envoywebhook; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://authzwebhook.athenz.svc.cluster.local/jwtauthn\" | vegeta attack -header \"Authorization: Bearer $${accesstoken}\" -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	@echo ""
	@echo "**************************************"
	@echo "**  Loadtest completed successfully **"
	@echo "**************************************"
	@echo ""

report-athenz-envoywebhook-loadtest:
	CASE=envoywebhook; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest result is printed to html *"
	@echo "**************************************"
	@echo ""

run-athenz-authzproxy-loadtest:
	accesstoken=$$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: authorization-proxy-clients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken" | xargs echo -n); \
	CASE=authzproxy; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://$$CASE.athenz.svc.cluster.local/server/test\" | vegeta attack -header \"Authorization: Bearer $${accesstoken}\" -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	@echo ""
	@echo "**************************************"
	@echo "**  Loadtest completed successfully **"
	@echo "**************************************"
	@echo ""

report-athenz-authzproxy-loadtest:
	CASE=authzproxy; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest result is printed to html *"
	@echo "**************************************"
	@echo ""

run-athenz-echoserver-loadtest:
	CASE=echoserver.client; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/echoserver\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=echoserver.authorizer; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://authorizer.athenz.svc.cluster.local/echoserver\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=echoserver.authzenvoy; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://authzenvoy.athenz.svc.cluster.local/echoserver\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	@echo ""
	@echo "**************************************"
	@echo "**  Loadtest completed successfully **"
	@echo "**************************************"
	@echo ""

report-athenz-echoserver-loadtest:
	CASE=echoserver.client; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=echoserver.authorizer; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=echoserver.authzenvoy; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest result is printed to html *"
	@echo "**************************************"
	@echo ""

run-athenz-loadtest:
	CASE=zms; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/zms/v1/domain/sys.auth/service\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	CASE=zts; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "echo \"GET https://client.athenz.svc.cluster.local/zts/v1/domain/sys.auth/service\" | vegeta attack -workers=300 -rate=300 -duration=30s -keepalive false | tee /data/$$CASE.bin | vegeta report"
	@echo ""
	@echo "**************************************"
	@echo "**  Loadtest completed successfully **"
	@echo "**************************************"
	@echo ""

report-athenz-loadtest:
	CASE=zms; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	CASE=zts; kubectl -n athenz exec deployment/vegeta -- /bin/sh -c "cat /data/$$CASE.bin | vegeta report -reporter=plot" > ../../$$CASE.html
	@echo ""
	@echo "**************************************"
	@echo "* Loadtest result is printed to html *"
	@echo "**************************************"
	@echo ""

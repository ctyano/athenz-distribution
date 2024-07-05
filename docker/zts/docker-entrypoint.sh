#!/usr/bin/env bash

if [ -z "${ROOT}" ]; then
    BINDIR=$(dirname "$0")
    export ROOT=$(cd $BINDIR/..;pwd)
    echo "Setting ZTS root directory to ${ROOT}"
fi

ZTS_STOP_TIMEOUT=${ZTS_STOP_TIMEOUT:-30}
ZTS_PID_DIR=${ZTS_PID_DIR:-$ROOT/var/zts_server}
ZTS_LOG_DIR=${ZTS_LOG_DIR:-$ROOT/logs/zts_server}

# make sure our pid and log directories exist

mkdir -p "${ZTS_PID_DIR}"
mkdir -p "${ZTS_LOG_DIR}"

# any environment variables starting with ATHENZ__ will be converted to java system properties with converting __ as to . and ___ as to -
if [ $(printenv | grep -E "^ATHENZ__") ]; then
    printenv | grep -E "^ATHENZ__" | tr '[:upper:]' '[:lower:]' | sed -e 's/\(__\)/./g' | sed -e 's/\(___\)/-/g' | tee -a ${CONF_PATH}/zts.properties | xargs printf "%s was added to ${CONF_PATH}/zts.properties\n"
fi

JAVA_OPTS="${JAVA_OPTS} -Dathenz.root_dir=."
JAVA_OPTS="${JAVA_OPTS} -Dathenz.zts.root_dir=."
JAVA_OPTS="${JAVA_OPTS} -Dathenz.prop_file=${CONF_PATH}/athenz.properties"
JAVA_OPTS="${JAVA_OPTS} -Dathenz.zts.prop_file=${CONF_PATH}/zts.properties"
JAVA_OPTS="${JAVA_OPTS} -Dlogback.configurationFile=${CONF_PATH}/logback.xml"
# system properties for passwords
[ ! -z "${ZTS_DB_ADMIN_PASS}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.zts.cert_jdbc_password=${ZTS_DB_ADMIN_PASS}"
[ ! -z "${ZTS_TRUSTSTORE_PASS}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.ssl_trust_store_password=${ZTS_TRUSTSTORE_PASS}"
if [ ! -z "${ZTS_SIGNER_TRUSTSTORE_PASS}" ]; then
    JAVA_OPTS="${JAVA_OPTS} -Dathenz.zts.ssl_trust_store_password=${ZTS_SIGNER_TRUSTSTORE_PASS}"
    JAVA_OPTS="${JAVA_OPTS} -Djavax.net.ssl.trustStorePassword=${ZTS_SIGNER_TRUSTSTORE_PASS}"
fi
if [ ! -z "${ZMS_CLIENT_TRUSTSTORE_PASS}" ]; then
    JAVA_OPTS="${JAVA_OPTS} -Dathenz.zms.client.truststore_password=${ZMS_CLIENT_TRUSTSTORE_PASS}"
fi
[ ! -z "${ZTS_KEYSTORE_PASS}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.ssl_key_store_password=${ZTS_KEYSTORE_PASS}"
[ ! -z "${ZMS_CLIENT_KEYSTORE_PASS}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.zms.client.keystore_password=${ZMS_CLIENT_KEYSTORE_PASS}"
[ ! -z "${ZTS_SIGNER_KEYSTORE_PASS}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.zts.keystore_signer.keystore_password=${ZTS_SIGNER_KEYSTORE_PASS}"
[ ! -z "${ZTS_SIGNER_KEYSTORE_PASS}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.zts.ssl_key_store_password=${ZTS_SIGNER_KEYSTORE_PASS}"
if [ ! -z "${ZTS_TRUSTSTORE_PEM_PATH}" ]; then
    keytool -import -noprompt -file ${ZTS_TRUSTSTORE_PEM_PATH} -alias ssl_trust_store -keystore $(cat ${CONF_PATH}/athenz.properties | grep -E "^athenz.ssl_trust_store=" | cut -d= -f2) -storepass ${ZTS_TRUSTSTORE_PASS:-athenz}
fi
if [ ! -z "${ZTS_SIGNER_TRUSTSTORE_PEM_PATH}" ]; then
    keytool -import -noprompt -file ${ZTS_SIGNER_TRUSTSTORE_PEM_PATH} -alias ssl_trust_store -keystore $(cat ${CONF_PATH}/athenz.properties | grep -E "^athenz.ssl_trust_store=" | cut -d= -f2) -storepass ${ZTS_SIGNER_TRUSTSTORE_PASS:-athenz}
fi
if [ ! -z "${ZMS_CLIENT_TRUSTSTORE_PEM_PATH}" ]; then
    keytool -import -noprompt -file ${ZMS_CLIENT_TRUSTSTORE_PEM_PATH} -alias ssl_trust_store -keystore $(cat ${CONF_PATH}/zts.properties | grep -E "^athenz.zms.client.truststore_path=" | cut -d= -f2) -storepass ${ZMS_CLIENT_TRUSTSTORE_PASS:-athenz}
fi
if [ ! -z "${ZTS_KEYSTORE_CERT_PEM_PATH}" -a ! -z "${ZTS_KEYSTORE_KEY_PEM_PATH}" ]; then
    openssl pkcs12 -export -noiter -out $(cat ${CONF_PATH}/athenz.properties | grep -E "^athenz.ssl_key_store=" | cut -d= -f2) -in ${ZTS_KEYSTORE_CERT_PEM_PATH} -inkey ${ZTS_KEYSTORE_KEY_PEM_PATH} -password pass:${ZTS_KEYSTORE_PASS:-athenz}
fi
if [ ! -z "${ZMS_CLIENT_KEYSTORE_CERT_PEM_PATH}" -a ! -z "${ZMS_CLIENT_KEYSTORE_KEY_PEM_PATH}" ]; then
    openssl pkcs12 -export -noiter -out $(cat ${CONF_PATH}/zts.properties | grep -E "^athenz.zms.client.keystore_path=" | cut -d= -f2) -in ${ZMS_CLIENT_KEYSTORE_CERT_PEM_PATH} -inkey ${ZMS_CLIENT_KEYSTORE_KEY_PEM_PATH} -password pass:${ZMS_CLIENT_KEYSTORE_PASS:-athenz}
fi
if [ ! -z "${ZTS_SIGNER_KEYSTORE_CERT_PEM_PATH}" -a ! -z "${ZTS_SIGNER_KEYSTORE_KEY_PEM_PATH}" ]; then
    openssl pkcs12 -export -noiter -out $(cat ${CONF_PATH}/zts.properties | grep -E "^athenz.zts.ssl_key_store=" | cut -d= -f2) -in ${ZTS_SIGNER_KEYSTORE_CERT_PEM_PATH} -inkey ${ZTS_SIGNER_KEYSTORE_KEY_PEM_PATH} -password pass:${ZTS_SIGNER_TRUSTSTORE_PASS:-athenz}
    openssl pkcs12 -export -noiter -out $(cat ${CONF_PATH}/zts.properties | grep -E "^athenz.zts.keystore_signer.keystore_path=" | cut -d= -f2) -in ${ZTS_SIGNER_KEYSTORE_CERT_PEM_PATH} -inkey ${ZTS_SIGNER_KEYSTORE_KEY_PEM_PATH} -password pass:${ZTS_SIGNER_KEYSTORE_PASS:-athenz}
fi
# system properties for private keys
[ ! -z "${ZTS_PRIVATE_KEY}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_key=${ZTS_PRIVATE_KEY}"
[ ! -z "${ZTS_PRIVATE_KEY_ID}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_key_id=${ZTS_PRIVATE_KEY_ID}"
[ ! -z "${ZTS_RSA_PRIVATE_KEY}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_rsa_key=${ZTS_RSA_PRIVATE_KEY}"
[ ! -z "${ZTS_RSA_PRIVATE_KEY_ID}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_rsa_key_id=${ZTS_RSA_PRIVATE_KEY_ID}"
[ ! -z "${ZTS_EC_PRIVATE_KEY}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_ec_key=${ZTS_EC_PRIVATE_KEY}"
[ ! -z "${ZTS_EC_PRIVATE_KEY_ID}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_ec_key_id=${ZTS_EC_PRIVATE_KEY_ID}"
[ ! -z "${ZTS_SELF_SIGNER_PRIVATE_KEY}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.zts.self_signer_private_key_fname=${ZTS_SELF_SIGNER_PRIVATE_KEY}"

ZTS_CLASSPATH="${CLASSPATH}:${USER_CLASSPATH}"
ZTS_BOOTSTRAP_CLASS="com.yahoo.athenz.container.AthenzJettyContainer"

### !!! P.S. cannot quote JAVA_OPTS !!!
### reference: https://github.com/koalaman/shellcheck/wiki/SC2086
java -classpath "${ZTS_CLASSPATH}" ${JAVA_OPTS} ${ZTS_BOOTSTRAP_CLASS} > "${ZTS_LOG_DIR}/zts.out" 2>&1 < /dev/null &
PID=$!

sleep 2;
if ! kill -0 "${PID}" > /dev/null 2>&1; then
    exit 1
fi

force_shutdown() {
    echo 'Will forcefully stopping ZTS...'
    kill -9 ${PID} >/dev/null 2>&1
    echo 'Forcefully stopped ZTS success'
    exit 1
}
shutdown() {
    if [ -z ${PID} ]; then
        echo 'ZTS is not running'
        exit 1
    else
        if ! kill -0 ${PID} > /dev/null 2>&1; then
            echo 'ZTS is not running'
            exit 1
        else
            # start shutdown
            echo 'Will stopping ZTS...'
            kill ${PID}

            # wait for shutdown
            count=0
            while [ -d "/proc/${PID}" ]; do
                echo 'Shutdown is in progress... Please wait...'
                sleep 1
                count="$((count + 1))"
    
                if [ "${count}" = "${ZTS_STOP_TIMEOUT}" ]; then
                    break
                fi
            done
            if [ "${count}" != "${ZTS_STOP_TIMEOUT}" ]; then
                echo 'Shutdown completed.'
            fi

            # if not success, force shutdown
            if kill -0 ${PID} > /dev/null 2>&1; then
                force_shutdown
            fi
        fi
    fi

    # confirm ZTS stopped
    if ! kill -0 ${PID} > /dev/null 2>&1; then
        exit 0
    fi
}

# SIGINT
trap shutdown 2

# SIGTERM
trap shutdown 15

# stream logs
echo 'Initilizing ZTS logs...'
touch ${ZTS_LOG_DIR}/zts.out ${ZTS_LOG_DIR}/server.log ${ZTS_LOG_DIR}/access.log ${ZTS_LOG_DIR}/audit.log
echo 'Start printing ZTS logs...'
tail -f ${ZTS_LOG_DIR}/zts.out ${ZTS_LOG_DIR}/server.log ${ZTS_LOG_DIR}/access.log ${ZTS_LOG_DIR}/audit.log &

# wait
wait ${PID}

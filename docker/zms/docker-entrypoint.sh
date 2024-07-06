#!/usr/bin/env bash
set -x

if [ -z "${ROOT}" ]; then
    BINDIR=$(dirname "$0")
    export ROOT=$(cd $BINDIR/..;pwd)
    echo "Setting ZMS root directory to ${ROOT}"
fi

ZMS_STOP_TIMEOUT=${ZMS_STOP_TIMEOUT:-30}
ZMS_PID_DIR=${ZMS_PID_DIR:-$ROOT/var/zms_server}
ZMS_LOG_DIR=${ZMS_LOG_DIR:-$ROOT/logs/zms_server}

# make sure our pid and log directories exist

mkdir -p "${ZMS_PID_DIR}"
mkdir -p "${ZMS_LOG_DIR}"

# any environment variables starting with ATHENZ__ will be converted to java system properties with converting __ as to . and ___ as to -
if [ $(printenv | grep -E "^ATHENZ__") ]; then
    printenv | grep -E "^ATHENZ__" | tr '[:upper:]' '[:lower:]' | sed -e 's/\(__\)/./g' | sed -e 's/\(___\)/-/g' | tee -a ${CONF_PATH}/zms.properties | xargs printf "%s was added to ${CONF_PATH}/zms.properties\n"
fi

JAVA_OPTS="${JAVA_OPTS} -Dathenz.root_dir=."
JAVA_OPTS="${JAVA_OPTS} -Dathenz.prop_file=${CONF_PATH}/athenz.properties"
JAVA_OPTS="${JAVA_OPTS} -Dathenz.zms.prop_file=${CONF_PATH}/zms.properties"
JAVA_OPTS="${JAVA_OPTS} -Dlogback.configurationFile=${CONF_PATH}/logback.xml"
# system properties for passwords
[ ! -z "${ZMS_DB_ADMIN_PASS}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.zms.jdbc_password=${ZMS_DB_ADMIN_PASS}"
[ ! -z "${ZMS_RODB_ADMIN_PASS}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.zms.jdbc_ro_password=${ZMS_RODB_ADMIN_PASS}"
if [ ! -z "${ZMS_TRUSTSTORE_PASS}" ]; then
    JAVA_OPTS="${JAVA_OPTS} -Dathenz.ssl_trust_store_password=${ZMS_TRUSTSTORE_PASS}"
fi
[ ! -z "${ZMS_KEYSTORE_PASS}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.ssl_key_store_password=${ZMS_KEYSTORE_PASS}"
if [ ! -z "${ZMS_TRUSTSTORE_PEM_PATH}" ]; then
    keytool --list -keystore $(cat ${CONF_PATH}/athenz.properties | grep -E "^athenz.ssl_trust_store=" | cut -d= -f2) -storepass ${ZMS_TRUSTSTORE_PASS:-athenz} | grep ssl_trust_store || \
      keytool -import -noprompt -file ${ZMS_TRUSTSTORE_PEM_PATH} -alias ssl_trust_store -keystore $(cat ${CONF_PATH}/athenz.properties | grep -E "^athenz.ssl_trust_store=" | cut -d= -f2) -storepass ${ZMS_TRUSTSTORE_PASS:-athenz}
fi
if [ ! -z "${ZMS_KEYSTORE_CERT_PEM_PATH}" -a ! -z "${ZMS_KEYSTORE_KEY_PEM_PATH}" ]; then
    openssl pkcs12 -export -noiter -in $(cat ${CONF_PATH}/athenz.properties | grep -E "^athenz.ssl_key_store=" | cut -d= -f2) -password pass:${ZMS_KEYSTORE_PASS:-athenz} || \
      openssl pkcs12 -export -noiter -out $(cat ${CONF_PATH}/athenz.properties | grep -E "^athenz.ssl_key_store=" | cut -d= -f2) -in ${ZMS_KEYSTORE_CERT_PEM_PATH} -inkey ${ZMS_KEYSTORE_KEY_PEM_PATH} -password pass:${ZMS_KEYSTORE_PASS:-athenz}
fi
# system properties for private keys
[ ! -z "${ZMS_PRIVATE_KEY}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_key=${ZMS_PRIVATE_KEY}"
[ ! -z "${ZMS_PRIVATE_KEY_ID}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_key_id=${ZMS_PRIVATE_KEY_ID}"
[ ! -z "${ZMS_RSA_PRIVATE_KEY}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_rsa_key=${ZMS_RSA_PRIVATE_KEY}"
[ ! -z "${ZMS_RSA_PRIVATE_KEY_ID}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_rsa_key_id=${ZMS_RSA_PRIVATE_KEY_ID}"
[ ! -z "${ZMS_EC_PRIVATE_KEY}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_ec_key=${ZMS_EC_PRIVATE_KEY}"
[ ! -z "${ZMS_EC_PRIVATE_KEY_ID}" ] && JAVA_OPTS="${JAVA_OPTS} -Dathenz.auth.private_key_store.private_ec_key_id=${ZMS_EC_PRIVATE_KEY_ID}"

ZMS_CLASSPATH="${CLASSPATH}:${USER_CLASSPATH}"
ZMS_BOOTSTRAP_CLASS="com.yahoo.athenz.container.AthenzJettyContainer"

### !!! P.S. cannot quote JAVA_OPTS !!!
### reference: https://github.com/koalaman/shellcheck/wiki/SC2086
java -classpath "${ZMS_CLASSPATH}" ${JAVA_OPTS} ${ZMS_BOOTSTRAP_CLASS} > "${ZMS_LOG_DIR}/zms.out" 2>&1 < /dev/null &
PID=$!

sleep 2;
if ! kill -0 "${PID}" > /dev/null 2>&1; then
    exit 1
fi

force_shutdown() {
    echo 'Will forcefully stopping ZMS...'
    kill -9 ${PID} >/dev/null 2>&1
    echo 'Forcefully stopped ZMS success'
    exit 1
}
shutdown() {
    if [ -z ${PID} ]; then
        echo 'ZMS is not running'
        exit 1
    else
        if ! kill -0 ${PID} > /dev/null 2>&1; then
            echo 'ZMS is not running'
            exit 1
        else
            # start shutdown
            echo 'Will stopping ZMS...'
            kill ${PID}

            # wait for shutdown
            count=0
            while [ -d "/proc/${PID}" ]; do
                echo 'Shutdown is in progress... Please wait...'
                sleep 1
                count="$((count + 1))"
    
                if [ "${count}" = "${ZMS_STOP_TIMEOUT}" ]; then
                    break
                fi
            done
            if [ "${count}" != "${ZMS_STOP_TIMEOUT}" ]; then
                echo 'Shutdown completed.'
            fi

            # if not success, force shutdown
            if kill -0 ${PID} > /dev/null 2>&1; then
                force_shutdown
            fi
        fi
    fi

    # confirm ZMS stopped
    if ! kill -0 ${PID} > /dev/null 2>&1; then
        exit 0
    fi
}

# SIGINT
trap shutdown 2

# SIGTERM
trap shutdown 15

# stream logs
echo 'Initilizing ZMS logs...'
touch ${ZMS_LOG_DIR}/zms.out ${ZMS_LOG_DIR}/server.log ${ZMS_LOG_DIR}/access.log ${ZMS_LOG_DIR}/audit.log
echo 'Start printing ZMS logs...'
tail -f ${ZMS_LOG_DIR}/zms.out ${ZMS_LOG_DIR}/server.log ${ZMS_LOG_DIR}/access.log ${ZMS_LOG_DIR}/audit.log &

# wait
wait ${PID}

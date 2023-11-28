'use strict';

const config = {
    authProxy: {
        timeZone: 'Asia/Tokyo',
        language: 'ja-JP',
        zms: process.env.ZMS_SERVER_URL || 'https://localhost:4443/zms/v1/',
        zmsLoginUrl:
            process.env.ZMS_LOGIN_URL || 'https://localhost:4443/zms/v1/',
        zmsConnectSrcUrl:
            process.env.ZMS_CONNECT_SRC_URL || 'https://localhost:4443',
        msd: process.env.MSD_LOGIN_URL || 'https://localhost:4443/msd/v1/',
        zts: process.env.ZTS_LOGIN_URL || 'https://localhost:4443/zts/v1/',
        ums: process.env.UMS_LOGIN_URL || 'https://localhost:4443/ums/v1/',
        authHeader: 'Athenz-Principal-Auth',
        strictSSL: true,
        userData: (user) => {
            return {
                userIcon: '/static/athenz-logo.png',
                userMail: '',
                userLink: {
                    title: 'GitHub User Profile',
                    url: `https://github.com/${user}`,
                    target: '_blank',
                },
            };
        },
        headerLinks: [
            {
                title: 'Website',
                url: 'https://www.athenz.io/',
                target: '_blank',
            },
            {
                title: 'Getting Started',
                url: 'https://athenz.github.io/athenz/',
                target: '_blank',
            },
            {
                title: 'Documentation',
                url: 'https://github.com/AthenZ/athenz/blob/master/README.md',
                target: '_blank',
            },
            {
                title: 'GitHub',
                url: 'https://github.com/ctyano/athenz-distribution',
                target: '_blank',
            },
            {
                title: 'Contribute',
                url: 'https://github.com/ctyano/athenz-distribution/pulls',
                target: '_blank',
            },
            {
                title: 'Contact Us',
                url: 'https://github.com/ctyano/',
                target: '_blank',
            },
            {
                title: 'Logout',
                url: '/login',
                target: ''
            },
        ],
        productMasterLink: {
            title: 'Product ID',
            url: '',
            target: '_blank',
        },
        servicePageConfig: {
            keyCreationLink: {
                title: 'Service Identity Registration',
                url: 'https://athenz.github.io/athenz/reg_service_guide/#service-identity-registration',
                target: '_blank',
            },
            keyCreationMessage:
                'Instances bootstrapped using Athenz Identity Providers can get Service Identity X.509 certificates automatically.',
        },
        userDomain: 'user',
        userDomains: 'user',
        templates: ['zts_instance_launch_provider'],
        allProviders: [
            {
                id: 'zts_instance_launch_provider',
                name: 'Athenz ZTS to issue a X.509 identity certificate for the workload',
            },
        ],
        allPrefixes: [
            {
                name: 'ZTS Identity Provisioning - Copper Argos',
                prefix: ':role.zts_instance_launch_provider',
            },
        ],
        staticUserName: process.env.STATIC_USER_NAME || '',
        cookieSession: process.env.UI_SESSION_SECRET_PATH || 'keys/cookie-session',
        statusPath: process.env.UI_SESSION_SECRET_PATH || 'keys/cookie-session',
        featureFlag: false,
        // https://github.com/AthenZ/athenz/pull/2252
        serverCipherSuites:
            'TLS_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_DHE_RSA_WITH_AES_128_GCM_SHA256:TLS_DHE_RSA_WITH_AES_256_GCM_SHA384:TLS_DHE_RSA_WITH_CHACHA20_POLY1305_SHA256',
        // extended config
        athenzPublicCert: process.env.ATHENZ_PUBLIC_CERT || '/var/run/athenz/service.cert.pem',
        athenzPrivateKey: process.env.ATHENZ_PRIVATE_KEY || '/var/run/athenz/service.key.pem',
        uiCertPath: process.env.UI_CERT_PATH || 'keys/tls.crt',
        uiKeyPath: process.env.UI_CERT_KEY_PATH || 'keys/tls.key',
        authUserNameHeader: 'X-Auth-Request-Preferred-Username',
        authUserEmailHeader: 'X-Auth-Request-Email',
    },
    unittest: {
        timeZone: 'Asia/Tokyo',
        language: 'ja-JP',
        zms: process.env.ZMS_SERVER_URL || 'https://localhost:4443/zms/v1/',
        zmsLoginUrl:
            process.env.ZMS_LOGIN_URL || 'https://localhost:4443/zms/v1/',
        zmsConnectSrcUrl:
            process.env.ZMS_CONNECT_SRC_URL || 'https://localhost:4443',
        msd: process.env.MSD_LOGIN_URL || 'https://localhost:4443/msd/v1/',
        zts: process.env.ZTS_LOGIN_URL || 'https://localhost:4443/zts/v1/',
        ums: process.env.UMS_LOGIN_URL || 'https://localhost:4443/ums/v1/',
        strictSSL: false,
        userDomain: 'user',
        userDomains: 'user',
        cookieSession: process.env.UI_SESSION_SECRET_PATH || 'keys/cookie-session',
        statusPath: process.env.UI_SESSION_SECRET_PATH || 'keys/cookie-session',
        featureFlag: false,
        // extended config
        athenzPublicCert: process.env.ATHENZ_PUBLIC_CERT || '/var/run/athenz/service.cert.pem',
        athenzPrivateKey: process.env.ATHENZ_PRIVATE_KEY || '/var/run/athenz/service.key.pem',
        uiCertPath: process.env.UI_CERT_PATH || 'keys/tls.crt',
        uiKeyPath: process.env.UI_CERT_KEY_PATH || 'keys/tls.key',
        authUserNameHeader: 'X-Auth-Request-Preferred-Username',
        authUserEmailHeader: 'X-Auth-Request-Email',
    },
};

module.exports = function () {
    let env = process.env.APP_ENV ? process.env.APP_ENV : 'authProxy';
    const c = config[env];
    c.env = env;
    return c;
};

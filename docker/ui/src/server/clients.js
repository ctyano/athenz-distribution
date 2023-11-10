const https = require('https');
const debug = require('debug')('AthenzUI:server:clients');

const rdlRest = require('../rdl-rest');
const CLIENTS = {};

const certRefreshTime = 24 * 60 * 60 * 1000; // refresh cert and key once a day

const fs = require('fs')

function refreshCertClients(config, options) {
    debug('refreshing clients with config: %o', config);

    // Disabling mTLS untill Copper Argos support is complete
//    const cert = fs.readFileSync(config.athenzPublicCert, 'ascii');
//    const key = fs.readFileSync(config.athenzPrivateKey, 'ascii');
//
//    const requestOpts = {
//        strictSSL: config.strictSSL,
//        httpsAgent: new https.Agent({
//            cert,
//            key
//        })
//    };
    const requestOpts = {};
    
    CLIENTS.zms = rdlRest({
        apiHost: config.zms,
        rdl: require('../config/zms.json'),
        requestOpts
    });

    CLIENTS.zts = rdlRest({
        apiHost: config.zts,
        rdl: require('../config/zts.json'),
        requestOpts
    });

    CLIENTS.msd = rdlRest({
        apiHost: config.msd,
        rdl: require('../config/msd.json'),
        requestOpts
    });

    CLIENTS.ums = rdlRest({
        apiHost: config.ums,
        rdl: require('../config/ums.json'),
        requestOpts
    });

    return Promise.resolve();
}

function setCookieinClients(req) {
    req.cookiesForwardCheck = {};
    return {
        cookie: function (currentReq) {
            /*jshint sub: true */
            if (currentReq.cookiesForwardCheck[currentReq.currentMethod]) {
                return currentReq.headers.cookie;
            }
            return null;
        },
        [req.authUserNameHeader]: function (currentReq) {
            if (currentReq.authUserNameHeader) {
                debug(`Authenticated user principal was: [${req.authUserNameHeader}: ${currentReq.authUserName}]`);
                return currentReq.authUserName;
            }
            return null;
        },
    };
}

module.exports.load = function load(config, options) {
    setInterval(() => refreshCertClients(config, options), certRefreshTime);

    return refreshCertClients(config, options);
};

module.exports.middleware = function middleware() {
    return (req, res, next) => {
        req.clients = {
            zms: CLIENTS.zms(req, setCookieinClients(req)),
            msd: CLIENTS.msd(req, setCookieinClients(req)),
            zts: CLIENTS.zts(req, setCookieinClients(req)),
            ums: CLIENTS.ums(req, setCookieinClients(req)),
        };
        next();
    };
};

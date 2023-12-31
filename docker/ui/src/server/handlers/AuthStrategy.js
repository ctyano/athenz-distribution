const passport = require('passport-strategy');
const util = require('util');
const debug = require('debug')('AthenzUI:AuthStrategy');

/**
 * `Strategy` constructor.
 *
 * @param expressApp
 * @param config
 * @param secrets
 * @param timeout
 * @api public
 */
function Strategy(expressApp, config, secrets) {
    // initial set up with config
    passport.Strategy.call(this);
    this.name = 'ui-auth';

    this.userDomain = config.userDomain;

    // username must be set in request header. (e.g. X-Auth-Request-Preferred-Username
    // email must be set in request header. (e.g. X-Auth-Request-Email
    if (!config.authUserNameHeader || !config.authUserEmailHeader) {
        throw new Error('config.authUserNameHeader and config.authUserEmailHeader are required');
    }

    this.authUserNameHeader = config.authUserNameHeader.toLowerCase();
    this.authUserEmailHeader = config.authUserEmailHeader.toLowerCase();
    this.staticUserName = config.staticUserName;
}

/**
 * Inherit from `passport.Strategy`.
 */
util.inherits(Strategy, passport.Strategy);

/**
 * Authenticate request with HTTP request headers passed from frot reverse proxy
 *
 * @param {Object} req
 * @param {Object} options
 * @api protected
 */
Strategy.prototype.authenticate = function (req, options) {

    debug(`Authenticating with username: [${this.authUserNameHeader}: ${req.headers[this.authUserNameHeader]}]`);
    debug(`Authenticating with email: [${this.authUserEmailHeader}: ${req.headers[this.authUserEmailHeader]}]`);

    // username e.g. athenz_admin
    const username = req.headers[this.authUserNameHeader] ? req.headers[this.authUserNameHeader] : this.staticUserName;
    const email = req.headers[this.authUserEmailHeader] ? req.headers[this.authUserEmailHeader] : `${this.staticUserName}@www.athenz.io`;
    // req.username e.g. athenz_admin
    req.username = username;
    // shortId e.g. athenz_admin
    req.session.shortId = username;
    req.user = {
        // req.user.userDomain e.g. athenz_admin
        userDomain: `${this.userDomain}.${username}`,
        // req.user.login e.g. athenz_admin@www.athenz.io
        login: email,
    };
    // req.name e.g. athenz_admin
    req.name = username;

    // these parameters are used in clients.js
    req.authUserNameHeader = this.authUserNameHeader;
    req.authUserEmailHeader = this.authUserEmailHeader;
    req.authUserName = username;

    debug(`Authenticated with authUserName: ${req.authUserName}`);

    this.success && this.success();
};

/**
 * Register a function used to configure the strategy.
 * not being used
 *
 * @api public
 * @param identifier
 * @param done
 */
Strategy.prototype.configure = function (identifier, done) {
    done();
};

module.exports = Strategy;

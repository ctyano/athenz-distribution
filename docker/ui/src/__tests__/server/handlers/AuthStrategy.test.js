const config = require('../../../config/config')();

describe('AuthStrategy Test', () => {
    test('should be able to create Strategy object', () => {
        const AuthStrategy = require('../../../server/handlers/AuthStrategy');
        let authStrategy = new AuthStrategy({}, config, {});
        expect(authStrategy).not.toBeNull();
    });

    test('should return an error when the required header user is missing', () => {
        const AuthStrategy = require('../../../server/handlers/AuthStrategy');
        let authStrategy = new AuthStrategy({}, config, {});
        expect(authStrategy).not.toBeNull();
        const mockUsername = 'test_user';
        const mockEmail = 'user@www.athenz.io';
        let req = {
          session: [],
          headers: [],
        };
        req.headers[config.authUserNameHeader.toLowerCase()] = mockUsername;
        authStrategy.authenticate(req);

        // username
        expect(req.username).toEqual(`${mockUsername}`);
        expect(req.session.shortId).toEqual(`${mockUsername}`);
        expect(req.user.userDomain).toEqual(`${config.userDomain}.${mockUsername}`);

        // email
        expect(req.user.login).toEqual(undefined);

        // header
        expect(req.authUserNameHeader).toEqual(`${config.authUserNameHeader.toLowerCase()}`);
        expect(req.authUserEmailHeader).toEqual(`${config.authUserEmailHeader.toLowerCase()}`);
    });

    test('should return an error when the required header email is missing', () => {
        const AuthStrategy = require('../../../server/handlers/AuthStrategy');
        let authStrategy = new AuthStrategy({}, config, {});
        expect(authStrategy).not.toBeNull();
        const mockUsername = 'test_user';
        const mockEmail = 'user@www.athenz.io';
        let req = {
          session: [],
          headers: [],
        };
        req.headers[config.authUserEmailHeader.toLowerCase()] = mockEmail;
        authStrategy.authenticate(req);

        // username
        expect(req.username).toEqual(undefined);
        expect(req.session.shortId).toEqual(undefined);
        expect(req.user.userDomain).toEqual("user.undefined");

        // email
        expect(req.user.login).toEqual(`${mockEmail}`);

        // header
        expect(req.authUserNameHeader).toEqual(`${config.authUserNameHeader.toLowerCase()}`);
        expect(req.authUserEmailHeader).toEqual(`${config.authUserEmailHeader.toLowerCase()}`);
    });

    test('should extract username and token from headers', () => {
        const AuthStrategy = require('../../../server/handlers/AuthStrategy');
        let authStrategy = new AuthStrategy({}, config, {});
        expect(authStrategy).not.toBeNull();

        const mockUsername = 'test_user';
        const mockEmail = 'user@www.athenz.io';
        let req = {
          session: [],
          headers: [],
        };
        req.headers[config.authUserNameHeader.toLowerCase()] = mockUsername;
        req.headers[config.authUserEmailHeader.toLowerCase()] = mockEmail;
        authStrategy.authenticate(req);

        // username
        expect(req.username).toEqual(`${mockUsername}`);
        expect(req.session.shortId).toEqual(`${mockUsername}`);
        expect(req.user.userDomain).toEqual(`${config.userDomain}.${mockUsername}`);

        // email
        expect(req.user.login).toEqual(`${mockEmail}`);

        // header
        expect(req.authUserNameHeader).toEqual(`${config.authUserNameHeader.toLowerCase()}`);
        expect(req.authUserEmailHeader).toEqual(`${config.authUserEmailHeader.toLowerCase()}`);
    });
});

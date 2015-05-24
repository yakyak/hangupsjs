Cookie   = require('tough-cookie').Cookie
request  = require 'request'
log      = require 'bog'
Q        = require 'q'
fs       = require 'fs'

{plug, req, NetworkError} = require './util'

# this CLIENT_ID and CLIENT_SECRET are whitelisted at google and
# turns up as "iOS device". access can be revoked a this page:
# https://security.google.com/settings/security/permissions
OAUTH2_CLIENT_ID     = '936475272427.apps.googleusercontent.com'
OAUTH2_CLIENT_SECRET = 'KWsJlkaMn1jGLxQpWxMnOox-'

OAUTH2_SCOPE         = 'https://www.google.com/accounts/OAuthLogin'

OAUTH2_PARAMS =
    client_id:    OAUTH2_CLIENT_ID
    scope:        OAUTH2_SCOPE
    redirect_uri: 'urn:ietf:wg:oauth:2.0:oob'
    response_type:'code'

OAUTH2_QUERY = ("&#{k}=#{encodeURIComponent(v)}" for k, v of OAUTH2_PARAMS).join('')
OAUTH2_LOGIN_URL = "https://accounts.google.com/o/oauth2/auth?#{OAUTH2_QUERY}"
OAUTH2_TOKEN_REQUEST_URL = 'https://accounts.google.com/o/oauth2/token'

UBERAUTH = 'https://accounts.google.com/accounts/OAuthLogin?source=hangups&issueuberauth=1'
MERGE_SESSION = 'https://accounts.google.com/MergeSession'
MERGE_SESSION_MAIL = "https://accounts.google.com/MergeSession?service=mail" +
    "&continue=http://www.google.com&uberauth="

class AuthError extends Error then constructor: -> super

setCookie = (jar) -> (cookie) -> Q.Promise (rs, rj) ->
    jar.setCookie cookie, OAUTH2_LOGIN_URL, plug(rs,rj)

cookieStrToJar = (jar, str) -> setCookie(jar)(Cookie.parse(str))

clone = (o) -> JSON.parse JSON.stringify o

module.exports = class Auth

    constructor: (@jar, @jarstore, @creds, @opts) ->

    # get authentication cookies on the form [{key:<cookie name>, value:<value>}, {...}, ...]
    # first checks the database if we already have cookies, or else proceeds with login
    getAuth: =>
        log.debug 'getting auth...'
        Q().then =>
            Q.Promise (rs, rj) => @jar.getCookies OAUTH2_LOGIN_URL, plug(rs, rj)
        .then (cookies) =>
            if cookies.length
                log.debug 'using cached cookies'
                Q()
            else
                log.debug 'proceeding to login'
                @login()
        .then ->
            # result
            log.debug 'getAuth done'
        .fail (err) ->
            log.error 'getAuth failed', err
            Q.reject err

    login: ->
        Q().then =>
            # fetch creds to inspect what we got to work with
            @creds()
        .then (creds) =>
            if creds.auth
                @oauthLogin(creds)
            else if creds.cookies
                @providedCookies(creds)
            else
                throw new Error("No acceptable creds provided")


    # An array of cookie strings to put into the jar
    providedCookies: ({cookies}) =>
        proms = for cookie in cookies
            cookieStrToJar @jar, cookie
        Q.all proms


    oauthLogin: ({auth}) =>
        Q().then =>
            # load the refresh-token from disk, and if found
            # use to get an authentication token.
            @loadRefreshToken().then (rtoken) =>
                @authWithRefreshToken(rtoken) if rtoken
        .then (atoken) =>
            if atoken
                # token from refresh-token. just use it.
                atoken
            else
                # no loaded refresh-token. request auth code.
                @requestAuthCode auth
        .then (atoken) =>
            # one way or another we have an atoken now
            @getSessionCookies atoken


    loadRefreshToken: =>
        path = @opts.rtokenpath
        Q().then ->
            Q.Promise (rs, rj) -> fs.readFile path, 'utf-8', plug(rs,rj)
        .fail (err) ->
            # ENOTFOUND is ok, we just return null and deal with
            # oauthLogin()
            return null if err.code == 'ENOENT'
            Q.reject err


    saveRefreshToken: (rtoken) =>
        path = @opts.rtokenpath
        Q().then ->
            Q.Promise (rs, rj) -> fs.writeFile path, rtoken, plug(rs,rj)

    authWithRefreshToken: (rtoken) =>
        log.debug 'auth with refresh token'
        Q().then ->
            opts =
                method: 'POST'
                uri: OAUTH2_TOKEN_REQUEST_URL
                form:
                    client_id:     OAUTH2_CLIENT_ID
                    client_secret: OAUTH2_CLIENT_SECRET
                    grant_type:    'refresh_token'
                    refresh_token: rtoken
            req(opts)
        .then (res) ->
            if res.statusCode == 200
                log.debug 'refresh token success'
                body = JSON.parse(res.body)
                body.access_token
            else
                Q.reject NetworkError.forRes(res)


    requestAuthCode: (auth) =>
        log.debug 'request auth code from user'
        Q().then ->
            auth()
        .then (code) ->
            log.debug 'requesting refresh token'
            opts =
                method: 'POST'
                uri: OAUTH2_TOKEN_REQUEST_URL
                form:
                    client_id:     OAUTH2_CLIENT_ID
                    client_secret: OAUTH2_CLIENT_SECRET
                    code:          code
                    grant_type:    'authorization_code'
                    redirect_uri:  'urn:ietf:wg:oauth:2.0:oob'
            req(opts)
        .then (res) =>
            if res.statusCode == 200
                log.debug 'auth with code success'
                body = JSON.parse(res.body)
                # save it and then return the access token
                @saveRefreshToken(body.refresh_token).then ->
                    body.access_token
            else



    getSessionCookies: (atoken) =>
        log.debug 'attempt to get session cookies', atoken
        uberauth = null
        headers = Authorization: "Bearer #{atoken}"
        jarstore = @jarstore
        Q().then ->
            log.debug 'requesting uberauth'
            req
                method: 'GET'
                uri: UBERAUTH
                jar: request.jar jarstore
                headers: headers
        .then (res) ->
            return Q.reject NetworkError.forRes(res) unless res.statusCode == 200
            log.debug 'got uberauth'
            uberauth = res.body
        .then ->
            # not sure what this is. some kind of cookie warmup call?
            log.debug 'request merge session 1/2'
            req
                method: 'GET'
                uri: MERGE_SESSION
                jar: request.jar jarstore
        .then (res) ->
            return Q.reject NetworkError.forRes(res) unless res.statusCode == 200
            log.debug 'request merge session 2/2'
            req
                method: 'GET'
                uri: MERGE_SESSION_MAIL + uberauth
                jar: request.jar jarstore
                header: headers
        .then (res) ->
            return Q.reject NetworkError.forRes(res) unless res.statusCode == 200
            log.debug 'got session cookies'


    authStdin: ->
        process.stdout.write "\nTo log in, open the following link in a browser
            and paste the provided authorization code below:\n\n"
        process.stdout.write OAUTH2_LOGIN_URL
        Q().then ->
            process.stdout.write "\n\nAuthorization Token: "
            process.stdin.setEncoding 'utf8'
            Q.Promise (rs) -> process.stdin.on 'readable', fn = ->
                chunk = process.stdin.read()
                if chunk != null
                    rs chunk
                    process.stdin.removeListener 'on', fn

# Expose this to Client
Auth.OAUTH2_LOGIN_URL = OAUTH2_LOGIN_URL

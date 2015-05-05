Cookie   = require('tough-cookie').Cookie
log      = require 'bog'
Q        = require 'q'

LOGIN_URL = 'https://accounts.google.com/ServiceLogin'

plug = (rs, rj) -> (err, val) -> if err then rj(err) else rs(val)

class AuthError extends Error then constructor: -> super

tryreq = (p) ->
    try
        require p
    catch err
        if err.code == 'MODULE_NOT_FOUND' then null else throw err

cookieStrToJar = (jar, str) -> Q.Promise (rs, rj) ->
    jar.setCookie Cookie.parse(str), LOGIN_URL, plug(rs,rj)

module.exports = class Auth

    constructor: (@jar, @creds) ->

    # get authentication cookies on the form [{key:<cookie name>, value:<value>}, {...}, ...]
    # first checks the database if we already have cookies, or else proceeds with login
    getAuth: ->
        log.debug 'getting auth...'
        Q().then =>
            Q.Promise (rs, rj) => @jar.getCookies LOGIN_URL, plug(rs, rj)
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

    # attempts login by either zombie/browser or provided cookies
    login: ->
        Q().then =>
            # fetch creds to inspect what we got to work with
            @creds()
        .then (creds) =>
            if creds.email and creds.pass
                @browserLogin(creds)
            else if creds.cookies
                @providedCookies(creds)
            else
                throw new Error("No acceptable creds provided")


    browserLogin: ({email, pass}) ->
        Browser = tryreq 'zombie'
        unless Browser
            log.error "Missing optional dependency 'zombie' required for browser
                login using email/pass"
            log.error "Fix this with: npm install -S zombie@3"
            process.exit(-1)
        browser = new Browser maxRedirects:10
        Q().then ->
            log.debug 'start google login...'
            browser.visit LOGIN_URL
        .then =>
            unless st = browser.resources[0].response.statusCode == 200
                throw new AuthError "Login page response code #{st}"
        .then ->
            log.debug 'logging in...'
            browser
                .fill 'Email',  email
                .fill 'Passwd', pass
                .pressButton 'signIn'
        .then =>
            # put cookies in the jar
            proms = for c in browser.cookies
                unless c.domain.match /google.com$/
                    Q()
                else
                    cookieStrToJar @jar, c.toString()
            Q.all proms
        .fail (err) ->
            log.error 'login failed', err
            Q.reject err


    # An array of cookie strings to put into the jar
    providedCookies: ({cookies}) =>
        proms = for cookie in cookies
            cookieStrToJar @jar, cookie
        Q.all proms

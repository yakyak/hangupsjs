Browser = require 'zombie'
Cookie  = require('tough-cookie').Cookie
log     = require 'bog'
Q       = require 'q'

LOGIN_URL = 'https://accounts.google.com/ServiceLogin'

plug = (rs, rj) -> (err, val) -> if err then rj(err) else rs(val)

class AuthError extends Error then constructor: -> super

module.exports = class Auth

    constructor: (@jar, @creds) ->


    # returns an array of cookies from the login
    login: ->
        browser = new Browser maxRedirects:10
        Q().then ->
            log.debug 'start google login...'
            browser.visit LOGIN_URL
        .then =>
            unless st = browser.resources[0].response.statusCode == 200
                throw new AuthError "Login page response code #{st}"
            log.debug 'requesting credentials'
            @creds()
        .then ({email, pass}) ->
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
                    Q.Promise (rs, rj) =>
                        @jar.setCookie Cookie.parse(c.toString()), LOGIN_URL, plug(rs,rj)
            Q.all proms
        .fail (err) ->
            log.error 'login failed', err
            Q.reject err


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

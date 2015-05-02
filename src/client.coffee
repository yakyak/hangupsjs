require('fnuc').expose global
FileCookieStore = require 'tough-cookie-filestore'
CookieJar       = require('tough-cookie').CookieJar
syspath  = require 'path'
log      = require 'bog'
Q        = require 'q'

Auth    = require './auth'
Init    = require './init'
Channel = require './channel'

DEFAULTS =
    cookiepath: syspath.normalize syspath.join __dirname, '../cookie.json'

module.exports = class Client

    constructor: (opts) ->
        o = mixin DEFAULTS, opts
        @jar = new CookieJar (@jarstore = new FileCookieStore o.cookiepath)
        @channel = new Channel @jarstore
        @init = new Init @jarstore

    connect: (creds) ->
        @auth = new Auth @jar, creds
        # getAuth does a login and stored the cookies
        # of the login into the db. the cookies are
        # cached.
        @auth.getAuth().then =>
            # fetch the 'pvt' token, which is required for the
            # initialization request (otherwise it will return 400)
            @channel.fetchPvt()
        .then (pvt) =>
            # now intialize the chat using the pvt
            @init.initChat pvt
        .then =>
            process.exit(0)
        #.then =>
        #    @channel.fetchSid()

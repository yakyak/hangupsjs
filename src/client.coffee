require('fnuc').expose global
FileCookieStore = require 'file-cookie-store'
CookieJar       = require('tough-cookie').CookieJar
syspath  = require 'path'
log      = require 'bog'
Q        = require 'q'

Auth    = require './auth'
Channel = require './channel'

DEFAULTS =
    cookiepath: syspath.normalize syspath.join __dirname, '../cookie.txt'

module.exports = class Client

    constructor: (opts) ->
        o = mixin DEFAULTS, opts
        @jar = new CookieJar new FileCookieStore o.cookiepath
        @channel = new Channel @jar

    connect: (creds) ->
        @auth = new Auth @jar, creds
        # getAuth does a login and stored the cookies
        # of the login into the db. the cookies are
        # cached.
        @auth.getAuth().then =>
            process.exit(0)
            # fetch the 'pvt' token, which is required for the
            # initialization request (otherwise it will return 400)
            @channel.fetchPvt()
        #.then =>
        #    @channel.fetchSid()

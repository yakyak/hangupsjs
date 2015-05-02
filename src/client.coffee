require('fnuc').expose global
{EventEmitter}  = require 'events'
FileCookieStore = require 'tough-cookie-filestore'
{CookieJar}     = require 'tough-cookie'
syspath  = require 'path'
log      = require 'bog'
fs       = require 'fs'
Q        = require 'q'

Auth    = require './auth'
Init    = require './init'
Channel = require './channel'
MessageParser = require './messageparser'

DEFAULTS =
    cookiepath: syspath.normalize syspath.join __dirname, '../cookie.json'

# ensure path exists
touch = (path) ->
    try
        fs.statSync(path)
    catch err
        if err.code == 'ENOENT'
            fs.writeFileSync(path, '')

module.exports = class Client extends EventEmitter

    constructor: (opts) ->
        o = mixin DEFAULTS, opts
        touch o.cookiepath
        @jar = new CookieJar (@jarstore = new FileCookieStore o.cookiepath)
        @channel = new Channel @jarstore
        @init = new Init @jarstore
        @messageParser = new MessageParser(this)
        @on 'clientid', (@clientId) =>

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
            do poller = =>
                @channel.getLines().then (lines) =>
                    @messageParser.parsePushLines lines
                    poller()
                .done()
            null

    # debug each event emitted
    emit: (ev, data) ->
        log.debug 'emit', ev, (data ? '')
        super

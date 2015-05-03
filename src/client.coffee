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
ChatReq = require './chatreq'

{ActiveClientState,
CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE} = require './schema'

DEFAULTS =
    cookiepath: syspath.normalize syspath.join __dirname, '../cookie.json'

# ensure path exists
touch = (path) ->
    try
        fs.statSync(path)
    catch err
        if err.code == 'ENOENT'
            fs.writeFileSync(path, '')

# Minimum time between setactive calls
SETACTIVE_LIMIT = 60 * 1000

None = undefined

module.exports = class Client extends EventEmitter

    constructor: (opts) ->
        o = mixin DEFAULTS, opts
        touch o.cookiepath
        @jar = new CookieJar (@jarstore = new FileCookieStore o.cookiepath)
        @channel = new Channel @jarstore
        @init = new Init @jarstore
        @chatreq = new ChatReq @jarstore, @init, @channel
        @messageParser = new MessageParser(this)
        @lastActive = 0
        @activeState = false

        # clientid comes as part of pushdata
        @on 'clientid', (clientid) => @init.clientid = clientid

    loglevel: (lvl) -> log.level lvl

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
            @running = true
            do poller = =>
                return unless @running
                @channel.getLines().then (lines) =>
                    @messageParser.parsePushLines lines
                    poller()
                .done()
            null

    # debug each event emitted
    emit: (ev, data) ->
        log.debug 'emit', ev, (data ? '')
        super


    disconnect: ->
        @running = false
        @channel.stop()


    isInited: =>
        # checks that we have all init stuff
        !!(@init.apikey and @init.email and @init.headerdate and @init.headerversion and
        @init.headerid and @init.clientid)


    isActive: -> @activeState == ActiveClientState.IS_ACTIVE_CLIENT


    # Utility method to throttle calls to @setactiveclient to happen
    # at most once every 60 seconds.
    setActive: ->
        timedOut = Date.now() - @lastActive > SETACTIVE_LIMIT
        if timedOut or not @isActive()
            @activeState = ActiveClientState.IS_ACTIVE_CLIENT
            @lastActive = Date.now()
            @setactiveclient true, 120


    # The active client receives notifications. This marks the client as active.
    #
    #
    # api: clients/setactiveclient
    setactiveclient: (active, timeoutsecs) ->
        @chatreq.req 'clients/setactiveclient', [
            @_requestBodyHeader()
            active
            "#{@init.email}/#{@init.clientid}"
            timeoutsecs
        ]


    # List all events occuring at or after timestamp. Timestamp can be
    # a date or long millis.
    #
    # This method requests protojson rather than json so we have one
    # chat message parser rather than two.
    #
    # timestamp: date instance specifying the time after which to
    # return all events occuring in.
    #
    # returns a parsed CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE
    syncallnewevents: (timestamp) ->
        time = mul 1000, if typeis timestamp, 'date' then timestamp.getTime() else timestamp
        @chatreq.req('conversations/syncallnewevents', [
            @_requestBodyHeader()
            time
            [], None, [], false, []
            1048576 # max_response_size_bytes
        ], false).then (body) -> # receive as protojson
            CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE.parse body


    _requestBodyHeader: ->
        [
            [6, 3, @init.headerversion, @init.headerdate],
            [@init.clientid, @init.headerid],
            None,
            "en"
        ]


    # syncallnewevents(self, timestamp)
    # sendchatmessage
    # upload_image(self, thefile, extension_hint="jpg")
    # setactiveclient(self, is_active, timeout_secs)
    # removeuser(self, conversation_id)
    # deleteconversation(self, conversation_id)
    # settyping(self, conversation_id, typing=schemas.TypingStatus.TYPING)
    # updatewatermark(self, conv_id, read_timestamp)
    # getselfinfo(self)
    # setfocus(self, conversation_id)
    # searchentities(self, search_string, max_results)
    # setpresence(self, online, mood=None)
    # querypresence(self, chat_id)
    # getentitybyid(self, chat_id_list)
    # getconversation(self, conversation_id, event_timestamp, max_events=50)
    # syncrecentconversations(self)
    # setchatname(self, conversation_id, name)
    # sendeasteregg(self, conversation_id, easteregg)
    # createconversation(self, chat_id_list, force_group = False)
    # adduser(self, conversation_id, chat_id_list)

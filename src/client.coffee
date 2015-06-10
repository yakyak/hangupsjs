require('fnuc').expose global
FileCookieStore = require 'tough-cookie-filestore'
{CookieJar}     = require 'tough-cookie'
{EventEmitter}  = require 'events'
syspath         = require 'path'
log             = require 'bog'
fs              = require 'fs'
Q               = require 'q'

{plug, fmterr, wait} = require './util'

MessageBuilder  = require './messagebuilder'
MessageParser   = require './messageparser'
ChatReq         = require './chatreq'
Channel         = require './channel'
Auth            = require './auth'
Init            = require './init'

{OffTheRecordStatus, TypingStatus,
ClientNotificationLevel,
CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE,
CLIENT_GET_CONVERSATION_RESPONSE
CLIENT_GET_ENTITY_BY_ID_RESPONSE} = require './schema'

IMAGE_UPLOAD_URL = 'http://docs.google.com/upload/photos/resumable'

DEFAULTS =
    rtokenpath:  syspath.normalize syspath.join __dirname, '../refreshtoken.txt'
    cookiespath: syspath.normalize syspath.join __dirname, '../cookies.json'

# the max amount of time we will wait between seeing some sort of
# activity from the server.
ALIVE_WAIT = 45000

# ensure path exists
touch = (path) ->
    try
        fs.statSync(path)
    catch err
        if err.code == 'ENOENT'
            fs.writeFileSync(path, '')

rm = (path) -> Q.Promise((rs, rj) -> fs.unlink(path, plug(rs, rj))).fail (err) ->
    if err.code == 'ENOENT' then null else Q.reject(err)

None = undefined

randomid = -> Math.round Math.random() * Math.pow(2,32)
datetolong = (d) -> if typeis d, 'date' then d.getTime() else d
togoogtime = sequence datetolong, mul(1000)

# token indicating abort in connect-loop
ABORT = {abort:true}

module.exports = class Client extends EventEmitter

    constructor: (opts) ->
        @opts = mixin DEFAULTS, opts
        @doInit()
        @messageParser = new MessageParser(this)

        # clientid comes as part of pushdata
        @on 'clientid', (clientid) =>
            @init.clientid = clientid
            @emit 'connected' if @isInited()

    loglevel: (lvl) -> log.level lvl

    connect: (creds) ->
        # tell the world what we're doing
        @emit 'connecting'
        # create a new auth instance
        @auth = new Auth @jar, @jarstore, creds, @opts
        # getAuth does a login and stores the cookies
        # of the login into the db. the cookies are
        # cached.
        @auth.getAuth().then =>
            # fetch the 'pvt' token, which is required for the
            # initialization request (otherwise it will return 400)
            @channel.fetchPvt()
        .then (pvt) =>
            # see https://github.com/algesten/hangupsjs/issues/6
            unless pvt
                # clear state and start reconnecting
                @logout().then => @connect(creds)
                return Q.reject ABORT
            # now intialize the chat using the pvt
            @init.initChat @jarstore, pvt
        .then =>
            @running = true
            # ensure we have a fresh timestamp
            @lastActive = Date.now()
            @ensureConnected()
            do poller = =>
                return unless @running
                @channel.getLines().then (lines) =>
                    @messageParser.parsePushLines lines
                    poller()
                .fail (err) =>
                    log.debug err.stack if err.stack
                    log.debug err
                    log.info 'poller stopped', fmterr(err)
                    @running = false
                    @emit 'connect_failed', err
            # wait for connected event to release promise
            Q.Promise (rs) => @once 'connected', -> rs()
        .fail (err) =>
            @running = false
            if err == ABORT
                return null
            else
                # tell everyone we didn't connect
                @emit 'connect_failed', err
                return Q.reject(err)


    doInit: ->
        touch @opts.cookiespath
        @jar = new CookieJar (@jarstore = new FileCookieStore @opts.cookiespath)
        @channel = new Channel @jarstore
        @init = new Init()
        @chatreq = new ChatReq @jarstore, @init, @channel


    # clears entire auth state, removing cached cookies and refresh
    # token.
    logout: =>
        # stop client
        @disconnect()
        # remove saved state
        rpath = @opts.rtokenpath
        cpath = @opts.cookiespath
        Q().then ->
            log.info 'removing refresh token'
            rm rpath
        .then ->
            log.info 'removing cookie store'
            rm cpath
        .then =>
            @doInit()

    emit: (ev, data) ->
        # record when we last emitted
        @lastActive = Date.now() unless ev is 'connect_failed'
        # debug it
        log.debug 'emit', ev, (data ? '')
        # and do it
        super


    # we get at least a "noop" event every 20-30 secs, if we have no
    # event after 45 secs, we must suspect a network interruption
    ensureConnected: =>
        # if there's a running timeout, stop it
        clearTimeout @ensureTimer if @ensureTimer
        # and no ensuring unless we're connected
        return unless @running
        # check whether we got an event within the threshold we see
        # noop 20-30 secs, so 45 should be ok
        Q().then =>
            if (Date.now() - @lastActive) > ALIVE_WAIT
                log.debug 'activity wait timeout after 45 secs'
                @disconnect()
                @emit 'connect_failed', new Error("Connection timeout")
        .then =>
            return unless @running # it may have changed
            waitFor = @lastActive + ALIVE_WAIT - Date.now()
            @ensureTimer = setTimeout @ensureConnected, waitFor


    disconnect: ->
        log.debug 'disconnect'
        @running = false
        clearTimeout @ensureTimer if @ensureTimer
        @channel?.stop?()


    isInited: =>
        # checks that we have all init stuff
        !!(@init.apikey and @init.email and @init.headerdate and @init.headerversion and
        @init.headerid and @init.clientid)


    # makes the header required at the start of each api call body.
    _requestBodyHeader: ->
        [
            [6, 3, @init.headerversion, @init.headerdate],
            [@init.clientid, @init.headerid],
            None,
            "en"
        ]


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
        @chatreq.req('conversations/syncallnewevents', [
            @_requestBodyHeader()
            togoogtime(timestamp)
            [], None, [], false, []
            1048576 # max_response_size_bytes
        ], false).then (body) -> # receive as protojson
            CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE.parse body


    # Send a chat message to a conversation.
    #
    # conversation_id must be a valid conversation ID. segments must be a
    # list of message segments to send, in pblite format.
    #
    # image_id is an optional ID of an image retrieved from
    # @uploadimage(). If provided, the image will be attached to the
    # message.
    #
    # otr_status determines whether the message will be saved in the server's
    # chat history. Note that the OTR status of the conversation is
    # irrelevant, clients may send messages with whatever OTR status they
    # like.
    #
    # client_generated_id is an identifier that is kept in the event
    # both in the result of this call and the following chat_event.
    # it can be used to tie together a client send with the update
    # from the server. The default is `null` which makes
    # the client generate a random id.
    sendchatmessage: (conversation_id, segments, image_id=None,
        otr_status=OffTheRecordStatus.ON_THE_RECORD,client_generated_id=null) ->
        client_generated_id = randomid() unless client_generated_id
        @chatreq.req 'conversations/sendchatmessage', [
            @_requestBodyHeader(),
            None, None, None, []
            [
                segments, []
            ],
            (if image_id then [[image_id, false]] else None)
            [
                [conversation_id]
                client_generated_id
                otr_status
            ],
            None, None, None, []
        ]

    # Return information about your account.
    getselfinfo: ->
        @chatreq.req 'contacts/getselfinfo', [
            @_requestBodyHeader()
            [], []
        ]


    # Set focus (occurs whenever you give focus to a client).
    setfocus: (conversation_id) ->
        @chatreq.req 'conversations/setfocus', [
            @_requestBodyHeader()
            [conversation_id]
            1
            20
        ]


    # Send typing notification.
    #
    # conversation_id must be a valid conversation ID. typing must be
    # a TypingStatus enum.
    settyping: (conversation_id, typing=TypingStatus.TYPING) ->
        @chatreq.req 'conversations/settyping', [
            @_requestBodyHeader()
            [conversation_id]
            typing
        ]


    # Set the presence or mood of this client.
    setpresence: (online, mood=None) ->
        @chatreq.req 'presence/setpresence', [
            @_requestBodyHeader()
            [
                # timeout_secs timeout in seconds for this presence
                720
                # client_presence_state:
                # 40 => DESKTOP_ACTIVE
                # 30 => DESKTOP_IDLE
                # 1 => NONE
                if online then 1 else 40
            ]
            None
            None
            # true if going offline, false if coming online
            [not online]
            # UTF-8 smiley like 0x1f603
            [mood]
        ]

    # Check someone's presence status.
    querypresence: (chat_id) ->
        @chatreq.req 'presence/querypresence', [
            @_requestBodyHeader()
            [
                [chat_id]
            ],
            [1, 2, 5, 7, 8]
        ]

    # Leave group conversation.
    #
    # conversation_id must be a valid conversation ID.
    removeuser: (conversation_id) ->
        client_generated_id = randomid()
        @chatreq.req 'conversations/removeuser', [
            @_requestBodyHeader()
            None, None, None,
            [
                [conversation_id], client_generated_id, 2
            ],
        ]


    # Delete one-to-one conversation.
    #
    # conversation_id must be a valid conversation ID.
    deleteconversation: (conversation_id) ->
        @chatreq.req 'conversations/deleteconversation', [
            @_requestBodyHeader()
            [conversation_id],
            # Not sure what timestamp should be there, last time I have tried it
            # Hangouts client in GMail sent something like now() - 5 hours
            Date.now() * 1000
            None, [],
        ]


    # Update the watermark (read timestamp) for a conversation.
    #
    # conversation_id must be a valid conversation ID.
    #
    # timestamp is a date or long millis
    updatewatermark: (conversation_id, timestamp) ->
        @chatreq.req 'conversations/updatewatermark', [
            @_requestBodyHeader()
            # conversation_id
            [conversation_id],
            # latest_read_timestamp
            togoogtime(timestamp)
        ]


    # Add user to existing conversation.
    #
    # conversation_id must be a valid conversation ID.
    #
    # chat_ids is an array of chat_id which should be invited to
    # conversation.
    adduser: (conversation_id, chat_ids) ->
        client_generated_id = randomid()
        @chatreq.req 'conversations/adduser', [
            @_requestBodyHeader()
            None,
            [chat_id, None, None, "unknown", None, []] for chat_id in chat_ids,
            None,
            [
                [conversation_id], client_generated_id, 2, None, 4
            ]
        ]


    # Set the name of a conversation.
    renameconversation: (conversation_id, name) ->
        client_generated_id = randomid()
        @chatreq.req 'conversations/renameconversation', [
            @_requestBodyHeader()
            None,
            name,
            None,
            [[conversation_id], client_generated_id, 1]
        ]


    # Create a new conversation.
    #
    # chat_ids is an array of chat_id which should be invited to
    # conversation (except yourself).
    #
    # force_group set to true if you invite just one chat_id, but
    # still want a group.
    #
    # New conversation ID is returned as res['conversation']['id']['id']
    createconversation: (chat_ids, force_group=false) ->
        client_generated_id = randomid()
        @chatreq.req 'conversations/createconversation', [
            @_requestBodyHeader()
            if chat_ids.length == 1 and not force_group then 1 else 2
            client_generated_id
            None
            [chat_id, None, None, "unknown", None, []] for chat_id in chat_ids
        ]


    # Return conversation events.
    #
    # This is mainly used for retrieving conversation
    # scrollback. Events occurring before timestamp are returned, in
    # order from oldest to newest.
    getconversation: (conversation_id, timestamp, max_events=50) ->
        @chatreq.req('conversations/getconversation', [
            @_requestBodyHeader()
            [[conversation_id], [], []],  # conversationSpec
            false,                        # includeConversationMetadata
            true,                         # includeEvents
            None,                         # ???
            max_events,                   # maxEventsPerConversation
            # eventContinuationToken (specifying timestamp is sufficient)
            [
                None,  # eventId
                None,  # storageContinuationToken
                togoogtime(timestamp),  # eventTimestamp
            ]
        ], false).then (body) -> # as protojson
            CLIENT_GET_CONVERSATION_RESPONSE.parse body


    # List the contents of recent conversations, including messages.
    # Similar to syncallnewevents, but appears to return a limited
    # number of conversations (20) rather than all conversations in a
    # given date range.
    #
    # returns a parsed CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE (same structure)
    syncrecentconversations: ->
        @chatreq.req('conversations/syncrecentconversations', [
            @_requestBodyHeader()
        ], false).then (body) -> # receive as protojson
            CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE.parse body


    # Search for people.
    searchentities: (search_string, max_results=10) ->
        @chatreq.req 'contacts/searchentities', [
            @_requestBodyHeader()
            []
            search_string
            max_results
        ]


    # Return information about a list of chat_ids
    getentitybyid: (chat_ids) ->
        @chatreq.req('contacts/getentitybyid', [
            @_requestBodyHeader()
            None
            [String(chat_id)] for chat_id in chat_ids
        ], false).then (body) ->
            CLIENT_GET_ENTITY_BY_ID_RESPONSE.parse body


    # Send a easteregg to a conversation.
    #
    # easteregg may not be empty. should be one of
    # 'ponies', 'pitchforks', 'bikeshed', 'shydino'
    sendeasteregg: (conversation_id, easteregg) ->
        @chatreq.req 'conversations/easteregg', [
            @_requestBodyHeader()
            [conversation_id]
            [easteregg, None, 1]
        ]


    # Set the notification level of a conversation.
    #
    # Pass Client.NotificationLevel.QUIET to disable notifications,
    # or Client.NotificationLevel.RING to enable them.
    setconversationnotificationlevel: (conversation_id, level) ->
        @chatreq.req 'conversations/setconversationnotificationlevel', [
            @_requestBodyHeader()
            [conversation_id],
            level
        ]


    # Uploads an image that can be later attached to a chat message.
    #
    # imagefile is a string path
    #
    # filename can optionally be provided otherwise the path name is
    # used.
    #
    # returns an image_id that can be used in sendchatmessage
    uploadimage: (imagefile, filename=null, timeout=30000) =>
        # either use provided or from path
        filename = filename ? syspath.basename(imagefile)
        size = null
        puturl = null
        chatreq = @chatreq
        Q().then -> Q.Promise (rs, rj) ->
            # figure out file size
            fs.stat imagefile, plug(rs, rj)
        .then (st) ->
            size = st.size
        .then ->
            log.debug 'image resume upload prepare'
            chatreq.baseReq IMAGE_UPLOAD_URL, 'application/x-www-form-urlencoded;charset=UTF-8'
            , {
                protocolVersion: "0.8"
                createSessionRequest:
                    fields: [{
                        external: {
                            filename,
                            size,
                            put: {},
                            name: 'file'
                        }
                    }]
            }
        .then (body) ->
            puturl = body?.sessionStatus?.externalFieldTransfers?[0]?.putInfo?.url
            log.debug 'image resume upload to:', puturl
        .then -> Q.Promise (rs, rj) ->
            fs.readFile imagefile, plug(rs, rj)
        .then (buf) ->
            log.debug 'image resume uploading'
            chatreq.baseReq puturl, 'application/octet-stream', buf, true, timeout
        .then (body) ->
            log.debug 'image resume upload finished'
            body?.sessionStatus?.additionalInfo?['uploader_service.GoogleRupioAdditionalInfo']?.completionInfo?.customerSpecificInfo?.photoid






# Expose these as part of publich API
Client.OffTheRecordStatus = OffTheRecordStatus
Client.TypingStatus       = TypingStatus
Client.MessageBuilder     = MessageBuilder
Client.authStdin          = Auth::authStdin
Client.NotificationLevel  = ClientNotificationLevel
Client.OAUTH2_LOGIN_URL   = Auth.OAUTH2_LOGIN_URL

require('fnuc').expose global
FileCookieStore = require 'tough-cookie-file-store'
{CookieJar}     = require 'tough-cookie'
{EventEmitter}  = require 'events'
syspath         = require 'path'
log             = require 'bog'
fs              = require 'fs'
Q               = require 'q'
moment          = require('moment')

{plug, fmterr, wait} = require './util'

MessageBuilder  = require './messagebuilder'
MessageParser   = require './messageparser'
ChatReq         = require './chatreq'
Channel         = require './channel'
Auth            = require './auth'
Init            = require './init'

{OffTheRecordStatus,
FocusStatus,
TypingStatus,
MessageActionType,
ClientDeliveryMediumType,
ClientNotificationLevel,
CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE,
CLIENT_GET_CONVERSATION_RESPONSE,
CLIENT_GET_ENTITY_BY_ID_RESPONSE,
CLIENT_CREATE_CONVERSATION_RESPONSE,
CLIENT_SEARCH_ENTITIES_RESPONSE} = require './schema'

IMAGE_UPLOAD_URL = 'https://docs.google.com/upload/photos/resumable'

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
        super()
        @opts = mixin DEFAULTS, opts
        @doInit()
        @messageParser = new MessageParser(this)

        # clientid comes as part of pushdata
        self = @
        @on 'clientid', (clientid) => self.init.clientid = clientid

    loglevel: (lvl) -> log.level lvl

    connect: (creds) ->
        # tell the world what we're doing
        @emit 'connecting'
        # create a new auth instance
        @auth = new Auth @jar, @jarstore, creds, @opts
        # getAuth does a login and stores the cookies
        # of the login into the db. the cookies are
        # cached.
        self = @
        @auth.getAuth().then =>
            # fetch the 'pvt' token, which is required for the
            # initialization request (otherwise it will return 400)
            self.channel.fetchPvt()
        .then (pvt) =>
            # see https://github.com/algesten/hangupsjs/issues/6
            unless pvt
                # clear state and start reconnecting
                log.debug 'no pvt token, logout and then reconnect'
                self.logout().then => self.connect(creds)
                return Q.reject ABORT
            # now intialize the chat using the pvt
            self.init.initChat self.jarstore, pvt
        .then =>
            log.debug 'initializing recent conversations'
            self.initrecentconversations self.init
        .then =>
            self.running = true
            self.connected = false
            # ensure we have a fresh timestamp
            self.lastActive = Date.now()
            self.ensureConnected()
            do poller = =>
                return unless self.running
                self.channel.getLines().then (lines) =>
                    # wait until we receive first data to emit a
                    # 'connected' event.
                    if not self.connected and self.running
                        self.connected = true
                        self.emit 'connected'
                    # when disconnecting, no more lines to parse.
                    if self.running
                        self.messageParser.parsePushLines lines
                        poller()
                .fail (err) =>
                    log.debug err.stack if err.stack
                    log.debug err
                    log.info 'poller stopped', fmterr(err)
                    self.running = false
                    self.connected = false
                    self.emit 'connect_failed', err
            # wait for connected event to release promise
            Q.Promise (rs) => self.once 'connected', -> rs()
        .fail (err) =>
            self.running = false
            self.connected = false
            if err == ABORT
                return null
            else
                # tell everyone we didn't connect
                self.emit 'connect_failed', err
                return Q.reject(err)


    doInit: ->
        touch @opts.cookiespath unless @opts.jarstore
        @jarstore = @opts.jarstore
        unless @jarstore?
            try
                @jarstore = new FileCookieStore(@opts.cookiespath)
            catch error
                if !fs.existsSync @opts.cookiespath
                    throw error
                log.error 'Error while reading cookie store, clearing cookie file'
                fs.unlinkSync @opts.cookiespath
                @jarstore = new FileCookieStore(@opts.cookiespath)
        @jar = new CookieJar @jarstore
        @channel = new Channel @jarstore, @opts.proxy
        @init = new Init @opts.proxy
        @chatreq = new ChatReq @jarstore, @init, @channel, @opts.proxy


    # clears entire auth state, removing cached cookies and refresh
    # token.
    logout: =>
        # stop client
        @disconnect()
        # remove saved state
        rpath = @opts.rtokenpath
        cpath = @opts.cookiespath
        self = @
        Q().then ->
            log.info 'removing refresh token'
            rm rpath
        .then ->
            log.info 'removing cookie store'
            rm cpath
        .then =>
            self.doInit()

    emit: (ev, data) ->
        # record when we last emitted
        @lastActive = Date.now() unless ev is 'connect_failed'
        # debug it
        log.debug 'emit', ev, (data ? '')
        # and do it
        super ev, data


    # we get at least a "noop" event every 20-30 secs, if we have no
    # event after 45 secs, we must suspect a network interruption
    ensureConnected: =>
        # if there's a running timeout, stop it
        clearTimeout @ensureTimer if @ensureTimer
        # and no ensuring unless we're connected
        return unless @running
        # check whether we got an event within the threshold we see
        # noop 20-30 secs, so 45 should be ok
        self = @
        Q().then =>
            if (Date.now() - self.lastActive) > ALIVE_WAIT
                log.debug 'activity wait timeout after 45 secs'
                self.disconnect() # this also sets self.connected to false
                self.emit 'connect_failed', new Error("Connection timeout")
        .then =>
            return unless self.running # it may have changed
            waitFor = self.lastActive + ALIVE_WAIT - Date.now()
            self.ensureTimer = setTimeout self.ensureConnected, waitFor


    disconnect: ->
        log.debug 'disconnect'
        @running = false
        @connected = false
        clearTimeout @ensureTimer if @ensureTimer
        @channel?.stop?()


    isInited: =>
        # checks that we have all init stuff
        !!(@init.apikey and @init.email and @init.headerdate and @init.headerversion and
        @init.headerid and @init.clientid)

    syncCookies: (sess) ->
        @jarstore.getAllCookies (e, cookies) ->
            cookies.forEach (cookie) ->
                schema = if cookie.secure then "https" else "http"
                host = if cookie?.domain?[0] is "." then cookie.domain.substr(1) else cookie.domain
                p = {url: schema + '://' + host, name: cookie.key, value: cookie.value, domain: host, path: cookie.path, secure: cookie.secure, httpOnly: cookie.httpOnly, expirationDate: moment(cookie.expires).unix(), sameSite: cookie.sameSite}
                sess.cookies.set(p)
                .catch (e) ->
                    return

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
    #
    # message_action_type determines if the message is a simple text message
    # or if the message is an action like `/me`.
    sendchatmessage: (conversation_id,
                      segments,
                      image_id = None,
                      otr_status = OffTheRecordStatus.ON_THE_RECORD,
                      client_generated_id = null,
                      delivery_medium = [ClientDeliveryMediumType.BABEL],
                      message_action_type = [[MessageActionType.NONE, ""]]) ->
        client_generated_id = randomid() unless client_generated_id
        @chatreq.req 'conversations/sendchatmessage', [
            @_requestBodyHeader(),
            None, None, None, message_action_type
            [
                segments, []
            ],
            (if image_id then [[image_id, false]] else None)
            [
                [conversation_id]
                client_generated_id
                otr_status
                delivery_medium
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
    #
    # focus must be a FocusStatus enum.
    setfocus: (conversation_id, focus=FocusStatus.FOCUSED, timeoutsecs=20) ->
        @chatreq.req 'conversations/setfocus', [
            @_requestBodyHeader()
            [conversation_id]
            focus
            timeoutsecs
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
    querypresence: (chat_ids) ->
        if not Array.isArray chat_ids
            chat_ids = [chat_ids]
            opts = [1, 2, 3, 5, 7, 8, 10]
        else
            opts = [2, 3, 10]

        @chatreq.req 'presence/querypresence', [
            @_requestBodyHeader()
            [chat_id] for chat_id in chat_ids,
            opts
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

    # Mark event observed for a conversation.
    #
    # conversation_id must be a valid conversation ID.
    # event_id must be a valid event ID.
    #
    # timestamp is a date or long millis
    markeventobserved: (conversation_id, event_id) ->
        @chatreq.req 'conversations/markeventobserved', [
            @_requestBodyHeader()
            # conversation_id
            [[[conversation_id], [event_id]]]
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
    # New conversation ID is returned as res['conversation']['conversation_id']['id']
    createconversation: (chat_ids, force_group=false) ->
        client_generated_id = randomid()
        @chatreq.req('conversations/createconversation', [
            @_requestBodyHeader()
            if chat_ids.length == 1 and not force_group then 1 else 2
            client_generated_id
            None
            [chat_id, None, None, "unknown", None, []] for chat_id in chat_ids
        ], false).then (body) ->
            CLIENT_CREATE_CONVERSATION_RESPONSE.parse body


    # Return conversation events.
    #
    # This is mainly used for retrieving conversation
    # scrollback. Events occurring before timestamp are returned, in
    # order from oldest to newest.
    getconversation: (conversation_id, timestamp, max_events=50, include_metadata = false) ->
        @chatreq.req('conversations/getconversation', [
            @_requestBodyHeader()
            [[conversation_id], [], []],  # conversationSpec
            include_metadata,             # includeConversationMetadata
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
    # Similar to syncallnewevents, but returns a limited
    # number of conversations (20) rather than all conversations in a
    # given date range.
	#
	# To get older conversations, use the timestamp_since parameter.
    #
    # returns a parsed CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE (same structure)
    syncrecentconversations: (timestamp_since=null) ->
        @chatreq.req('conversations/syncrecentconversations', [
            @_requestBodyHeader(),
            timestamp_since         # timestamp that controls pagination
        ], false).then (body) -> # receive as protojson
            CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE.parse body

    # Initializes the recent conversations.
    initrecentconversations: (init) ->
        @chatreq.req('conversations/syncrecentconversations', [
            @_requestBodyHeader(),
            null
        ], false).then (body) -> # receive as protojson
            data = CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE.parse body
            init.conv_states = data.conversation_state if Array.isArray data.conversation_state

    # Search for people.
    searchentities: (search_string, max_results=10) ->
        @chatreq.req('contacts/searchentities', [
            @_requestBodyHeader()
            []
            search_string
            max_results
        ], false).then (body) ->
            CLIENT_SEARCH_ENTITIES_RESPONSE.parse body


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

    # Set the OTR status of a conversation
    #
    # Pass Client.OffTheRecordStatus.OFF_THE_RECORD to disable history
    # or Client.OffTheRecordStatus.ON_THE_RECORD to turn it on
    modifyotrstatus: (conversation_id, otr=OffTheRecordStatus.ON_THE_RECORD) ->
        client_generated_id = randomid()
        @chatreq.req 'conversations/modifyotrstatus', [
            @_requestBodyHeader(),
            None,
            otr,
            None,
            [
                [conversation_id], client_generated_id, otr, None, 9
            ]
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
        filename = filename ? (if Buffer.isBuffer imagefile then "image.jpg" else syspath.basename(imagefile))
        size = null
        puturl = null
        chatreq = @chatreq
        Q().then -> Q.Promise (rs, rj) ->
            # figure out file size
            if Buffer.isBuffer(imagefile) then rs({ size: imagefile.length }) else fs.stat imagefile, plug(rs, rj)
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
            if Buffer.isBuffer(imagefile) then rs(imagefile) else fs.readFile imagefile, plug(rs, rj)
        .then (buf) ->
            log.debug 'image resume uploading'
            chatreq.baseReq puturl, 'application/octet-stream', buf, {}, true, timeout
        .then (body) ->
            log.debug 'image resume upload finished'
            body?.sessionStatus?.additionalInfo?['uploader_service.GoogleRupioAdditionalInfo']?.completionInfo?.customerSpecificInfo?.photoid

    getvideoinformation: (user_id, photo_id) ->
        @chatreq.userMediaReq 'videoinformation', {
            'mediaItemId.legacyPhotoId.obfuscatedUserId': user_id,
            'mediaItemId.legacyPhotoId.photoId': photo_id
        }

# aliases list
aliases = [
    'logLevel',
    'sendChatMessage',
    'setActiveClient',
    'syncAllNewEvents',
    'getSelfInfo',
    'setConversationNotificationLevel',
    'modifyOtrStatus',
    'setFocus',
    'setTyping',
    'setPresence',
    'queryPresence',
    'removeUser',
    'deleteConversation',
    'updateWatermark',
    'addUser',
    'renameConversation',
    'createConversation',
    'getConversation',
    'syncRecentConversations',
    'searchEntities',
    'getEntityById',
    'sendEasteregg',
    'uploadImage'
]

# set aliases
aliases.forEach((alias) ->
  Client.prototype[alias] = Client.prototype[alias.toLowerCase()])




# Expose these as part of publich API
Client.OffTheRecordStatus = OffTheRecordStatus
Client.ClientDeliveryMediumType = ClientDeliveryMediumType
Client.FocusStatus        = FocusStatus
Client.TypingStatus       = TypingStatus
Client.MessageActionType  = MessageActionType
Client.MessageBuilder     = MessageBuilder
Client.authStdin          = Auth::authStdin
Client.NotificationLevel  = ClientNotificationLevel
Client.OAUTH2_LOGIN_URL   = Auth.OAUTH2_LOGIN_URL
Client.VERSION            = JSON.parse(fs.readFileSync(syspath.normalize syspath.join(__dirname, '..', 'package.json'))).version

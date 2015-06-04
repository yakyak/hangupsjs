require('fnuc').expose global
{CookieJar} = require 'tough-cookie'
request = require 'request'
crypto  = require 'crypto'
log     = require 'bog'
Q       = require 'q'

{req, find, wait, NetworkError, fmterr} = require './util'
PushDataParser = require './pushdataparser'

ORIGIN_URL = 'https://talkgadget.google.com'
CHANNEL_URL_PREFIX = 'https://0.client-channel.google.com/client-channel'

UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36
      (KHTML, like Gecko) Chrome/41.0.2272.118 Safari/537.36'

op  = (o) -> "#{CHANNEL_URL_PREFIX}/#{o}"

isUnknownSID = (res) -> res.statusCode == 400 and res.statusMessage == 'Unknown SID'

# error token
ABORT = {}

# typical long poll
#
# 2015-05-02 14:44:19 DEBUG found sid/gsid 5ECBB7A224ED4276 XOqP3EYTfy6z0eGEr9OD5A
# 2015-05-02 14:44:19 DEBUG long poll req
# 2015-05-02 14:44:19 DEBUG long poll response 200 OK
# 2015-05-02 14:44:19 DEBUG got msg [[[2,["noop"]]]]
# 2015-05-02 14:44:19 DEBUG got msg [[[3,[{"p":"{\"1\":{\"1\":{\"1\":{\"1\":1,\"2\":1}},\"4\":\"1430570659159\",\"5\":\"S1\"},\"3\":{\"1\":{\"1\":1},\"2\":\"lcsw_hangouts881CED94\"}}"}]]]]
# 2015-05-02 14:44:49 DEBUG got msg [[[4,["noop"]]]]
# 2015-05-02 14:45:14 DEBUG got msg [[[5,["noop"]]]]
# ...
# 2015-05-02 14:47:56 DEBUG got msg [[[11,["noop"]]]]
# 2015-05-02 14:48:21 DEBUG got msg [[[12,["noop"]]]]
# 2015-05-02 14:48:21 DEBUG long poll end
# 2015-05-02 14:48:21 DEBUG long poll req
# 2015-05-02 14:48:21 DEBUG long poll response 200 OK
# 2015-05-02 14:48:21 DEBUG got msg [[[13,["noop"]]]]
# ...
# 2015-05-02 15:31:39 DEBUG long poll error { [Error: ESOCKETTIMEDOUT] code: 'ESOCKETTIMEDOUT' }
# 2015-05-02 15:31:39 DEBUG poll error { [Error: ESOCKETTIMEDOUT] code: 'ESOCKETTIMEDOUT' }
# 2015-05-02 15:31:39 DEBUG backing off for 2 ms
# 2015-05-02 15:31:39 DEBUG long poll end
# 2015-05-02 15:31:39 DEBUG long poll req
# 2015-05-02 15:31:39 DEBUG long poll response 200 OK
# 2015-05-02 15:31:39 DEBUG got msg [[[121,["noop"]]]]

authhead = (sapisid, msec, origin) ->
    auth_string = "#{msec} #{sapisid} #{origin}"
    auth_hash = crypto.createHash('sha1').update(auth_string).digest 'hex'
    return {
        authorization: "SAPISIDHASH #{msec}_#{auth_hash}"
        'x-origin': origin
        'x-goog-authuser': '0'
    }

sapisidof = (jarstore) ->
    jar = new CookieJar jarstore
    cookies = jar.getCookiesSync ORIGIN_URL
    cookie = find cookies, (cookie) -> cookie.key == 'SAPISID'
    return cookie?.value

MAX_RETRIES = 5


module.exports = class Channel

    constructor: (@jarstore) ->
        @pushParser = new PushDataParser()

    fetchPvt: =>
        log.debug 'fetching pvt'
        opts =
            method: 'GET'
            uri: "#{ORIGIN_URL}/talkgadget/_/extension-start"
            jar: request.jar @jarstore
        req(opts).then (res) =>
            data = JSON.parse res.body
            log.debug 'found pvt token', data[1]
            data[1]
        .fail (err) ->
            log.info 'fetchPvt failed', fmterr(err)
            Q.reject err

    authHeaders: ->
        sapisid = sapisidof @jarstore
        unless sapisid
            log.warn 'no SAPISID cookie'
            return null
        authhead sapisid, Date.now(), ORIGIN_URL

    fetchSid: =>
        auth = @authHeaders()
        return Q.reject new Error("No auth headers") unless auth
        Q().then =>
            opts =
                method: 'POST'
                uri: op 'channel/bind'
                jar: request.jar @jarstore
                qs:
                    VER: 8
                    RID: 81187
                    ctype: 'hangouts'
                form:
                    count: 0
                headers: auth
                encoding: null # get body as buffer
            req(opts).then (res) ->
                # Example format (after parsing JS):
                # [   [0,["c","SID_HERE","",8]],
                #     [1,[{"gsid":"GSESSIONID_HERE"}]]]
                if res.statusCode == 200
                    p = new PushDataParser(res.body)
                    line = p.pop()
                    [_,[_,sid]]  = line[0]
                    [_,[{gsid}]] = line[1]
                    log.debug 'found sid/gsid', sid, gsid
                    return {sid,gsid}
                else
                    log.warn 'failed to get sid', res.statusCode, res.body
        .fail (err) ->
            log.info 'fetchSid failed', fmterr(err)
            Q.reject err


    # get next messages from channel
    getLines: =>
        @start() unless @running
        @pushParser.allLines()


    # start polling
    start: =>
        retries = MAX_RETRIES
        @running = true
        @sid = null   # ensures we get a new sid
        @gsid = null
        @subscribed = false
        run = =>
            # graceful stop of polling
            return unless @running
            @poll(retries).then ->
                # XXX we only reset to MAX_RETRIES after a full ended
                # poll. this means in bad network conditions we get an
                # edge case where retries never reset despite getting
                # (interrupted) good polls. perhaps move retries to
                # instance var?
                retries = MAX_RETRIES # reset on success
                run()
            .fail (err) =>
                # abort token is not an error
                return if err == ABORT
                retries--
                log.debug 'poll error', err
                if retries > 0
                    run()
                else
                    @running = false
                    # resetting with error makes pushParser.allLines()
                    # resolve with that error, which in turn makes
                    # @getLines() propagate the error out.
                    @pushParser.reset(err)
        run()
        return null


    # gracefully stop polling
    stop: =>
        log.debug 'channel stop'
        # stop looping
        @running = false
        # this releases the @getLines() promise
        @pushParser?.reset?()
        # abort current request
        @currentReq?.abort?()


    poll: (retries) =>
        Q().then ->
            backoffTime = 2 * (MAX_RETRIES - retries) * 1000
            log.debug 'backing off for', backoffTime, 'ms' if backoffTime
            wait backoffTime
        .then =>
            Q.reject ABORT unless @running
        .then =>
            unless @sid
                @fetchSid().then (o) =>
                    merge this, o # set on this
                    @pushParser.reset() # ensure no half data
        .then =>
            @reqpoll()


    # long polling
    reqpoll: => Q.Promise (rs, rj) =>
        log.debug 'long poll req'
        opts =
            method: 'GET'
            uri: op 'channel/bind'
            jar: request.jar @jarstore
            qs:
                VER: 8
                gsessionid: @gsid
                RID: 'rpc'
                t: 1
                SID: @sid
                CI: 0
                ctype: 'hangouts'
                TYPE: 'xmlhttp'
            headers: @authHeaders()
            encoding: null # get body as buffer
            timeout: 30000 # 30 seconds timeout in connect attempt
        ok = false
        @currentReq = request(opts).on 'response', (res) =>
            log.debug 'long poll response', res.statusCode, res.statusMessage
            if res.statusCode == 200
                return ok = true
            else if isUnknownSID(res)
                ok = false
                log.debug 'sid became invalid'
                @sid = null
                @gsid = null
                @subscribed = false
            rj NetworkError.forRes(res)
        .on 'data', (chunk) =>
            if ok
#                log.debug 'long poll chunk\n' + require('hexy').hexy(chunk)
                @pushParser.parse chunk
            # subscribe on first data received
            @subscribe() unless @subscribed
        .on 'error', (err) =>
            log.debug 'long poll error', err
            rj err
        .on 'end', ->
            log.debug 'long poll end'
            rs()


    # Subscribes the channel to receive relevant events. Only needs to
    # be called when a new channel (SID/gsessionid) is opened.
    subscribe: =>
        return if @subscribed
        @subscribed = true
        Q().then ->
            wait(1000) # https://github.com/tdryer/hangups/issues/58
        .then =>
            timestamp = Date.now() * 1000
            opts =
                method: 'POST'
                uri: op 'channel/bind'
                jar: request.jar @jarstore
                qs:
                    VER: 8
                    RID: 81188
                    ctype: 'hangouts'
                    gsessionid: @gsid
                    SID: @sid
                headers: @authHeaders()
                timeout: 30000 # 30 seconds timeout in connect attempt
                form:
                    count: 3,
                    ofs: 0,
                    req0_p: '{"1":{"1":{"1":{"1":3,"2":2}},"2":{"1":{"1":3,"2":' +
                            '2},"2":"","3":"JS","4":"lcsclient"},"3":' +
                            timestamp + ',"4":0,"5":"c1"},"2":{}}',
                    req1_p: '{"1":{"1":{"1":{"1":3,"2":2}},"2":{"1":{"1":3,"2":' +
                            '2},"2":"","3":"JS","4":"lcsclient"},"3":' +
                            timestamp + ',"4":' + timestamp +
                            ',"5":"c3"},"3":{"1":{"1":"babel"}}}',
                    req2_p: '{"1":{"1":{"1":{"1":3,"2":2}},"2":{"1":{"1":3,"2":' +
                            '2},"2":"","3":"JS","4":"lcsclient"},"3":' +
                            timestamp + ',"4":' + timestamp +
                            ',"5":"c4"},"3":{"1":{"1":"hangout_invite"}}}'
            req(opts)
        .then (res) ->
            if res.statusCode == 200
                return log.debug 'subscribed channel'
            else if isUnknownSID(res)
                ok = false
                log.debug 'sid became invalid'
                @sid = null
                @gsid = null
                @subscribed = false
            Q.reject NetworkError.forRes(res)
        .fail (err) =>
            log.info 'subscribe failed', fmterr(err)
            @subscribed = false
            Q.reject err

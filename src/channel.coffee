require('fnuc').expose global
{CookieJar} = require 'tough-cookie'
request = require 'request'
crypto  = require 'crypto'
log     = require 'bog'
Q       = require 'q'
hexy    = require 'hexy'

{req, find, wait} = require './util'
PushDataParser = require './pushdataparser'

ORIGIN_URL = 'https://talkgadget.google.com'
#ORIGIN_URL = 'https://0.client-channel.google.com'
CHANNEL_URL_PREFIX = 'https://0.client-channel.google.com/client-channel'

UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36
      (KHTML, like Gecko) Chrome/41.0.2272.118 Safari/537.36'

op  = (o) -> "#{CHANNEL_URL_PREFIX}/#{o}"

class NetworkError extends Error then constructor: (@code, @message) -> super

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
    return cookie.value

MAX_RETRIES = 5


module.exports = class Channel

    constructor: (@jarstore) ->
        @pushParser = new PushDataParser()

    fetchPvt: =>
        opts =
            method: 'GET'
            uri: "#{ORIGIN_URL}/talkgadget/_/extension-start"
            jar: request.jar @jarstore
        req(opts).then (res) =>
            data = JSON.parse res.body
            log.debug 'found pvt token', data[1]
            data[1]

    fetchSid: =>
        Q().then =>
            sapisid = sapisidof @jarstore
            headers = authhead sapisid, Date.now(), ORIGIN_URL
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
                headers: headers
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
            log.error 'fetchSid failed', err
            Q.reject err


    # get next messages from channel
    get: =>
        @start() unless @running
        @pushParser.allLines()


    # start polling
    start: =>
        retries = MAX_RETRIES
        @running = true
        @sid = null   # ensures we get a new sid
        @gsid = null
        run = =>
            # graceful stop of polling
            return unless @running
            @poll(retries).then ->
                retries = MAX_RETRIES # reset on success
                run()
            .fail (err) =>
                retries--
                log.debug 'poll error', err
                if retries > 0
                    run()
                else
                    @running = false
                    @pushParser.reset()
                    @pushParser?.def?.reject err
        run()
        return null


    # gracefully stop polling
    stop: =>
        # will stop polling at next loop
        @running = false


    poll: (retries) =>
        Q().then ->
            backoffTime = 2 * (MAX_RETRIES - retries)
            log.debug 'backing off for', backoffTime, 'ms' if backoffTime
            wait backoffTime
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
        sapisid = sapisidof @jarstore
        headers = authhead sapisid, Date.now(), ORIGIN_URL
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
            headers: headers
            encoding: null # get body as buffer
            timeout: 30000 # 30 seconds timeout in connect attempt
        ok = false
        r = request(opts).on 'response', (res) =>
            log.debug 'long poll response', res.statusCode, res.statusMessage
            if res.statusCode == 200
                return ok = true
            else if res.statusCode == 400 and res.statusMessage == 'Unknown SID'
                ok = false
                log.debug 'sid became invalid'
                @sid = null
            rj new NetworkError(res.statusCode, res.statusMessage)
        .on 'data', (chunk) =>
            if ok
#                log.debug 'long poll chunk\n' + hexy.hexy(chunk)
                @pushParser.parse chunk
        .on 'error', (err) =>
            log.error 'long poll error', err
            rj err
        .on 'end', ->
            log.debug 'long poll end'
            rs()

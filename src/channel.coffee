request = require 'request'
crypto  = require 'crypto'
log     = require 'bog'
Q       = require 'q'

{req} = require './util'

PVT_TOKEN_URL = 'https://talkgadget.google.com/talkgadget/_/extension-start'

ORIGIN_URL = 'https://talkgadget.google.com'
#ORIGIN_URL = 'https://0.client-channel.google.com'
CHANNEL_URL_PREFIX = 'https://0.client-channel.google.com/client-channel'
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36
      (KHTML, like Gecko) Chrome/41.0.2272.118 Safari/537.36'

op  = (o) -> "#{CHANNEL_URL_PREFIX}/#{o}"

authhead = (sapisid, msec, origin) ->
    auth_string = "#{msec} #{sapisid} #{origin}"
    auth_hash = crypto.createHash('sha1').update(auth_string).digest 'hex'
    return {
        authorization: "SAPISIDHASH #{msec}_#{auth_hash}"
        'x-origin': origin
        'origin': origin
        'x-goog-authuser': '0'
        'user-agent': UA
    }
authheadof = (jar) ->
    sapisid = cookieval jar, 'SAPISID'
    msec = Date.now()
    authhead sapisid, msec, ORIGIN_URL

#tst = authhead 'm82pRZH0Eh3ue_gP/AQxqUASfcSMfU7tcI', 1428159172194, 'https://0.client-channel.google.com'

#console.log tst
#console.log 'SAPISIDHASH 1428159172194_f216c39fed596f9fa3f67d0c43462da39b9d310e'


module.exports = class Channel

    constructor: (@jarstore) ->

    fetchPvt: =>
        opts =
            method: 'GET'
            uri: PVT_TOKEN_URL
            jar: request.jar @jarstore
        req(opts).then (res) =>
            data = JSON.parse res.body
            log.debug 'found pvt token', data[1]
            data[1]

    fetchSid: =>
        opts =
            method: 'POST'
            uri: op 'channel/bind'
            jar: @jar
            qs:
                VER: 8
                RID: 81187
                ctype: 'hangouts'
            form:
                count: 0
            headers: authheadof @db
        req(opts).then (res) ->
            res

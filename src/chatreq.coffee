log     = require 'bog'
request = require 'request'
Q       = require 'q'

{req, NetworkError, tryparse} = require './util'

#require('request-debug') request

module.exports = class ChatReq

    constructor: (@jarstore, @init, @channel) ->

    # does a request against url.
    # contentype is request Content-Type.
    # body is the body which will be JSON.stringify()
    # json is whether we want a result that is json or protojson
    #
    # These cookies are typically submitted:
    # NID, SID, HSID, SSID, APISID, SAPISID
    baseReq: (url, contenttype, body, json=true, timeout=30000) ->
        headers = @channel.authHeaders()
        return Q.reject new Error("No auth headers") unless headers
        headers['Content-Type'] = contenttype
        params =
            key: @init.apikey
            alt: if json then 'json' else 'protojson'
        opts =
            method: 'POST'
            uri: url
            jar: request.jar @jarstore
            qs: params
            headers: headers
            body: if Buffer.isBuffer body then body else JSON.stringify(body)
            encoding: null # get body as buffer
            timeout: timeout # timeout in connect attempt (default 30 sec)
        req(opts).fail (err) ->
            log.debug 'request failed', err
            Q.reject err
        .then (res) ->
            showBody = if res.statusCode == 200 then '' else res.body?.toString?()
            log.debug 'request for', url, 'result:', res.statusCode, showBody
            if res.statusCode == 200
                if json
                    tryparse res.body.toString()
                else
                    res.body # protojson, return as Buffer
            else
                log.debug 'request for 2', url, 'result:', res.statusCode, res.body?.toString?()
                Q.reject NetworkError.forRes(res)


    # request endpoint by submitting body. json toggles whether we want
    # the result as json or protojson
    req: (endpoint, body, json=true) ->
        url = "https://clients6.google.com/chat/v1/#{endpoint}"
        @baseReq url, 'application/json+protobuf', body, json

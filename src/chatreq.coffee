log     = require 'bog'
request = require 'request'
Q       = require 'q'

{req, NetworkError} = require './util'

#require('request-debug') request

module.exports = class ChatReq

    constructor: (@jarstore, @init, @channel) ->

    # NID, SID, HSID, SSID, APISID, SAPISID
    baseReq: (url, contenttype, body, json=true) ->
        headers = @channel.authHeaders()
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
            body: JSON.stringify(body)
            encoding: null # get body as buffer
            timeout: 30000 # 30 seconds timeout in connect attempt
        req(opts).fail (err) ->
            log.debug 'request failed', err
            Q.reject err
        .then (res) ->
            showBody = if res.statusCode == 200 then '' else res.body?.toString?()
            log.debug 'request for', url, 'result:', res.statusCode, showBody
            if res.statusCode == 200
                res.body
            else
                log.debug 'request for', url, 'result:', res.statusCode, res.body?.toString?()
                Q.reject NetworkError.forRes(res)


    req: (endpoint, body, json=true) ->
        url = "https://clients6.google.com/chat/v1/#{endpoint}"
        @baseReq url, 'application/json+protobuf', body, json

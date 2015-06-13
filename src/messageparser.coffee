log = require 'bog'
Q   = require 'q'

{tryparse} = require './util'
{CLIENT_STATE_UPDATE} = require './schema'

CLIENT_EVENT_PARTS = [
    'chat_message'
    'membership_change'
    'conversation_rename'
    'hangout_event'
]

module.exports = class MessageParser

    constructor: (@emitter) ->

    parsePushLines: (lines) => @parsePushLine(line) for line in lines; null

    parsePushLine: (line) =>
        for sub in line
            data = sub?[1]?[0]
            if data
                if data == 'noop'
                    @emit 'noop'
                else if data.p?
                    obj = tryparse(data.p)
                    if obj?['3']?['2']?
                        @emit 'clientid', obj['3']['2']
                    if obj?['2']?['2']?
                        @parsePayload obj['2']['2']
            else
                log.debug 'failed to parse', line
        null

    parsePayload: (payload) =>
        payload = tryparse(payload) if typeis payload, 'string'
        # XXX when we get a null payload on an incoming hangout_event
        # i wonder whether we *actually* got a null payload, or if we
        # simply misinterpreted what's coming at some step.
        return unless payload
        if payload?[0] == 'cbu'
            for u in payload[1]
                update = CLIENT_STATE_UPDATE.parse u
                @emitUpdateParts update
        else
            log.info 'ignoring payload', payload


    emitUpdateParts: (update) ->
        header = update.state_update_header
        for k, value of update
            [_, eventname] = k.match(/(.*)_notification/) ? []
            continue unless eventname and value
            if eventname == 'event'
                # further split the nebulous "CLIENT_EVENT"
                @emitEventParts header, value.event
            else
                value._header = header
                @emit eventname, value


    emitEventParts: (header, event) ->
        for part in CLIENT_EVENT_PARTS when event[part]
            ks = filter keys(event), (k) ->
                event[k] and (k == part or not contains CLIENT_EVENT_PARTS, k)
            @emit part, pick event, ks


    emit: (ev, data) => @emitter?.emit ev, data

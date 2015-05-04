log = require 'bog'
Q   = require 'q'

{tryparse} = require './util'
{CLIENT_STATE_UPDATE} = require './schema'

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
        if payload[0] == 'cbu'
            for u in payload[1]
                update = CLIENT_STATE_UPDATE.parse u
                @emit 'update', update
        else
            log.info 'ignoring payload with header', payload[0]


    emit: (ev, data) => @emitter?.emit ev, data

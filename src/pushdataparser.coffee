Q   = require 'q'
log = require 'bog'

findNextLf = (buf, start) ->
    i = start
    len = buf.length
    while i < len
        return i if buf[i] == 10
        i++
    return -1

# Parser for format that is
#
# <len spec>\n<data>
# <len spec>\n<data>
#
module.exports = class PushDataParser

    constructor: (data) ->
        @lines = []
        @leftover = null
        @parse data if data

    parse: (newdata) ->
        data = if @leftover then Buffer.concat [@leftover, newdata] else newdata
        @leftover = null
        i = 0
        while (n = findNextLf(data, i)) >= 0
            len = JSON.parse data.slice(i, n).toString()
            start = n + 1
            end = n + 1 + len
            break unless end <= data.length
            line = JSON.parse data.slice(start, end).toString()
            @lines.push line
            i = end
        @leftover = data.slice i if i < data.length
        available = @available()
        if available and @def
            @def.resolve @lines
            @def = null
            @lines = []
        available

    available: -> @lines.length

    pop: -> @lines.pop()

    allLines: ->
        def = @def ? Q.defer()
        if @lines.length
            def.resolve @lines
            @def = null
            @lines = []
        else
            @def = def
        return def.promise

    reset: (err) ->
        log.debug 'PushDataParser reset'
        if @def
            if err then @def.reject(err) else @def.resolve([])
            @def = null
        @lines = []
        @leftover = null

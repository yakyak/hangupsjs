
{SegmentType} = require './schema'

# Helper class to make message segments.
module.exports = class MessageBuilder

    constructor: ->
        @segments = []

    text: (txt, bold=false, italic=false,
        strikethrough=false, underline=false, href=null) ->
            seg = [SegmentType.TEXT, txt]
            if bold or italic or strikethrough or underline
                seg[2] = format = []
                format[0] = if bold then 1 else null
                format[1] = if italic then 1 else null
                format[2] = if strikethrough then 1 else null
                format[3] = if underline then 1 else null
            if href
                seg[2] = null unless seg[2]
                seg[3] = link = []
                link[0] = href
            @segments.push seg
            this

    bold: (txt) -> @text txt, true
    italic: (txt) -> @text txt, false, true
    strikethrough: (txt) -> @text txt, false, false, true
    underline: (txt) -> @text txt, false, false, false, true
    link: (txt, href) -> @text txt, false, false, false, false, href

    linebreak: ->
        seg = [SegmentType.LINE_BREAK, '\n']
        @segments.push seg
        this

    toSegments: -> @segments


{SegmentType} = require './schema'

# Helper class to make message segments.
module.exports = class MessageBuilder

    constructor: ->
        @segments = []
        @segsjson = []

    text: (txt, bold=false, italic=false,
        strikethrough=false, underline=false, href=null) ->
            seg = [SegmentType.TEXT, txt]
            segj =
                text: txt
                type: "TEXT"
            if bold or italic or strikethrough or underline
                seg[2] = format = []
                segj.formatting = {}
                format[0] = if bold then 1 else null
                format[1] = if italic then 1 else null
                format[2] = if strikethrough then 1 else null
                format[3] = if underline then 1 else null
                segj.formatting.bold = 1 if bold
                segj.formatting.italic = 1 if italic
                segj.formatting.strikethrough = 1 if strikethrough
                segj.formatting.underline = 1 if underline
            if href
                seg[0] = SegmentType.LINK
                segj.type = "LINK"
                seg[2] = null unless seg[2]
                seg[3] = link = []
                link[0] = href
                segj.link_data = link_target:href
            @segments.push seg
            @segsjson.push segj
            this

    bold: (txt) -> @text txt, true
    italic: (txt) -> @text txt, false, true
    strikethrough: (txt) -> @text txt, false, false, true
    underline: (txt) -> @text txt, false, false, false, true
    link: (txt, href) -> @text txt, false, false, false, false, href

    linebreak: ->
        seg = [SegmentType.LINE_BREAK, '\n']
        segj = {text:'\n', type:'LINE_BREAK'}
        @segments.push seg
        @segsjson.push segj
        this

    toSegments: -> @segments
    toSegsjson: -> @segsjson

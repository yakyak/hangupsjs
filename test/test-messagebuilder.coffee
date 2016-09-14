{assert} = require('chai')
deql = assert.deepEqual

MessageBuilder = require '../src/messagebuilder'

describe 'MessageBuilder', ->

    mb = null
    beforeEach ->
        mb = new MessageBuilder()

    it 'adds a simple text segment', ->
        deql mb.text('Hello World!').toSegments(), [[0,'Hello World!']]
        deql mb.toSegsjson(), [{text:'Hello World!', type:'TEXT'}]

    it 'adds a bold text segment', ->
        deql mb.bold('Hello World!').toSegments(), [[0,'Hello World!',[1,null,null,null]]]
        deql mb.toSegsjson(), [{formatting:{bold:1}, text:'Hello World!', type:'TEXT'}]

    it 'adds a italic text segment', ->
        deql mb.italic('Hello World!').toSegments(), [[0,'Hello World!',[null,1,null,null]]]
        deql mb.toSegsjson(), [{formatting:{italic:1}, text:'Hello World!', type:'TEXT'}]

    it 'adds a strikethrough text segment', ->
        deql mb.strikethrough('Hello World!').toSegments(), [[0,'Hello World!',[null,null,1,null]]]
        deql mb.toSegsjson(), [{formatting:{strikethrough:1}, text:'Hello World!', type:'TEXT'}]

    it 'adds an underline text segment', ->
        deql mb.underline('Hello World!').toSegments(), [[0,'Hello World!',[null,null,null,1]]]
        deql mb.toSegsjson(), [{formatting:{underline:1}, text:'Hello World!', type:'TEXT'}]

    it 'adds a link', ->
        deql mb.link('linktext', 'http://foo/bar').toSegments(),
            [[0, 'linktext ('], [2,'http://foo/bar',null,['http://foo/bar']], [0, ')']]
        deql mb.toSegsjson(),
            [{type:'TEXT', text:'linktext ('}, {link_data:{link_target:'http://foo/bar'},text:'http://foo/bar', type:'LINK'}, {type:'TEXT', text:')'}]

    it 'adds a plain link', ->
        deql mb.link('http://foo/bar', 'http://foo/bar').toSegments(),
            [[2,'http://foo/bar',null,['http://foo/bar']]]
        deql mb.toSegsjson(),
            [{link_data:{link_target:'http://foo/bar'},text:'http://foo/bar', type:'LINK'}]

    it 'adds a linebreak', ->
        deql mb.linebreak().toSegments(), [[1,'\n']]
        deql mb.toSegsjson(), [{text:'\n', type:'LINE_BREAK'}]

    it 'recognizes the given message_action_type', ->
        mb = new MessageBuilder 4
        deql mb.toMessageActionType(), [[4, ""]]

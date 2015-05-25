{assert} = require('chai')
deql = assert.deepEqual

MessageBuilder = require '../src/messagebuilder'

describe 'MessageBuilder', ->

    mb = null
    beforeEach ->
        mb = new MessageBuilder()

    it 'adds a simple text segment', ->
        deql mb.text('Hello World!').toSegments(), [[0,'Hello World!']]

    it 'adds a bold text segment', ->
        deql mb.bold('Hello World!').toSegments(), [[0,'Hello World!',[1,null,null,null]]]

    it 'adds a italic text segment', ->
        deql mb.italic('Hello World!').toSegments(), [[0,'Hello World!',[null,1,null,null]]]

    it 'adds a strikethrough text segment', ->
        deql mb.strikethrough('Hello World!').toSegments(), [[0,'Hello World!',[null,null,1,null]]]

    it 'adds an underline text segment', ->
        deql mb.underline('Hello World!').toSegments(), [[0,'Hello World!',[null,null,null,1]]]

    it 'adds a link', ->
        deql mb.link('linktext', 'http://foo/bar').toSegments(),
        [[2,'linktext',null,['http://foo/bar']]]

    it 'adds a linebreak', ->
        deql mb.linebreak().toSegments(),
        [[1,'\n']]

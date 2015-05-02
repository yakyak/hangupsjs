{assert} = require('chai')
deql = assert.deepEqual

MessageParser = require '../src/messageparser'

describe 'MessagePaser', ->

    m = null
    beforeEach ->
        m = new MessageParser()

    describe 'parsePushLines', ->

        it 'handles noop', (done) ->
            m.emit = (ev) ->
                deql 'noop', ev
                done()
            m.parsePushLines [[[2,["noop"]]]]

        it 'handles {p:{ with clientid', (done) ->
            m.emit = (ev, data) ->
                deql ev, 'clientid'
                deql data, 'lcsw_hangouts881CED94'
                done()
            m.parsePushLines [[[3,[{"p":"{\"1\":{\"1\":{\"1\":{\"1\":1,\"2\":1}},\"4\":\"1430570659159\",\"5\":\"S1\"},\"3\":{\"1\":{\"1\":1},\"2\":\"lcsw_hangouts881CED94\"}}"}]]]]

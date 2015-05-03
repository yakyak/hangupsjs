fs = require 'fs'
{assert} = require('chai')
deql = assert.deepEqual

{CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE} = require '../src/schema'

describe 'CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE', ->

    it 'parses', ->
        msg = fs.readFileSync './test/syncall.bin'
        x = CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE.parse msg
        deql x.response_header,
            current_server_time: 1430641400746000
            request_trace_id: "-6693534691558475312"
            status: 1
        deql x.sync_timestamp, 1430641100747000
        deql x.conversation_state[0].event[4].chat_message.message_content.segment[0].text,
            'tja bosse'

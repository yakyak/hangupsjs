fs = require 'fs'
{assert} = require('chai')
deql = assert.deepEqual

PushDataParser = require '../src/pushdataparser'

describe 'PushDataParser', ->

    p = null
    beforeEach ->
        p = new PushDataParser()

    it 'parses sid/gsid', ->
        msg = fs.readFileSync './test/sidgsid.bin', null
        lines = p.parse msg
        deql lines, 1
        s = p.pop()
        [_,[_,sid]] = s[0]
        [_,[{gsid}]] = s[1]
        deql sid, '9EB0A0FABFF8FB97'
        deql gsid, 'iMyLjHNOp8jTdYnYP4ophA'

    it 'handles chopped off len specifications', ->
        msg1 = new Buffer('1')
        lines = p.parse msg1
        deql lines, 0
        deql p.leftover, new Buffer('1')
        msg2 = new Buffer('0\n1234567890')
        lines = p.parse msg2
        deql lines, 1
        deql p.leftover, null

    it 'handles chopped off data', ->
        msg1 = new Buffer('10\n1234')
        lines = p.parse msg1
        deql lines, 0
        deql p.leftover, new Buffer('10\n1234')
        msg2 = new Buffer('567890')
        lines = p.parse msg2
        deql lines, 1
        deql p.leftover, null

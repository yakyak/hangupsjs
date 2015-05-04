fs = require 'fs'
{assert} = require('chai')
deql = assert.deepEqual

Init = require '../src/init'

describe 'Init', ->

    init = null
    beforeEach ->
        init = new Init()

    describe 'parseBody', ->

        it 'takes an html body, evals it and extracts data', ->
            body = fs.readFileSync './test/body.html', 'utf-8'
            init.parseBody(body).then ->
                deql init.apikey, 'AIzaSyAfFJCeph-euFSwtmqFZi0kaKk-cZ5wufM'
                deql init.email, 'botenstrom2@gmail.com'
                deql init.headerdate, '1430432585'
                deql init.headerversion, 'chat_wcs_20150428.102048_RC6'
                deql init.headerid, 'D23D46B72872BA87'
                deql init.timestamp, new Date(1430555780826)
                assert.isNotNull init.self_entity
                deql init.conv_states?.length, 2
                assert.isNotNull init.entities

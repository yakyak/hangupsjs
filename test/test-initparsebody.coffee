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
                deql init.email, 'joao.marques.antunes@gmail.com'
                deql init.headerdate, '1480451609'
                deql init.headerversion, 'chat_frontend_20161129.11_p0'
                deql init.headerid, '820F7C523A7BC3A6'
                deql init.timestamp, new Date('2016-12-04T22:40:25.772Z')
                assert.isNotNull init.self_entity
                assert.isNotNull init.entities

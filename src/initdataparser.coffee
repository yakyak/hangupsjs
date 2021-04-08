request = require 'request'
log     = require 'bog'
Q       = require 'q'
fs      = require 'fs'
syspath = require 'path'

{req, find, uniqfn, NetworkError} = require './util'

{CLIENT_GET_SELF_INFO_RESPONSE,
CLIENT_CONVERSATION_STATE_LIST,
INITIAL_CLIENT_ENTITIES} = require './schema'

CHAT_INIT_URL = 'https://hangouts.google.com/webchat/u/0/load'
CHAT_INIT_PARAMS =
    fid:  'gtn-roster-iframe-id',
    ec:   '["ci:ec",true,true,false]',
    pvt:  null,  # Populated later

module.exports = class InitDataParser

    @parse: (body, dict, result) ->
        Q().then ->
            # the structure of the html body is (bizarelly):
            # <script>...</script>
            # <script>...</script>
            # <script>...</script>
            # <!DOCTYPE html><html>...</html>
            # <script>...</script>
            # <script>...</script>

            # first remove the <html> part
            html = body.replace /<!DOCTYPE html><html>*(.|\n)*<\/html>/gm, ''

            # and then the <script> tags
            html = html.replace /<\/?script.*>/gm, ''

            # expose the init chunk queue
            html = html.replace 'var AF_initDataChunkQueue =',
                'var AF_initDataChunkQueue = this.AF_initDataChunkQueue ='

            # eval it.
            # eval is a security risk, google could inject random
            # data into our client right here.
            do (-> eval html).bind(out = {})

            # and return the exposed data
            return out
        .then (out) =>
            # the page has a weird and wonderful javascript structure in
            # out.AF_initDataChunkQueue =
            # [ { key: 'ds:0', isError: false, hash: '2', data: [Function] },
            #   { key: 'ds:1', isError: false, hash: '26', data: [Function] },
            #   { key: 'ds:2', isError: false, hash: '19', data: [Function] },
            #   { key: 'ds:3', isError: false, hash: '5', data: [Function] }...
            for k, spec of dict
                ent = find out.AF_initDataChunkQueue, (e) ->
                    if spec.name? && typeof e.data == 'function'
                        d = e.data()
                        if d? && d.length > 0 && d[0].length > 0 && d[0][0].length > 0
                            return spec.name == d[0][0]
                    else if spec.name? && Array.isArray e.data
                        d = e.data
                        if d? && d.length > 0 && d[0].length > 0 && d[0][0].length > 0
                            return spec.name == d[0][0]
                    spec.key == e.key

                if ent
                    if typeof ent.data == 'function'
                        data = ent.data()
                    else
                        data = ent.data

                    result[k] = d = spec.fn data
                    if d.length
                        log.debug 'init data count', k, d.length
                    else
                        log.debug 'init data', k, d
                else
                    log.warn 'no init data for', k

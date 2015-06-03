request = require 'request'
log     = require 'bog'
Q       = require 'q'
fs      = require 'fs'
syspath = require 'path'

{req, find, uniqfn, NetworkError} = require './util'

{CLIENT_GET_SELF_INFO_RESPONSE,
CLIENT_CONVERSATION_STATE_LIST,
INITIAL_CLIENT_ENTITIES} = require './schema'

CHAT_INIT_URL = 'https://talkgadget.google.com/u/0/talkgadget/_/chat'
CHAT_INIT_PARAMS =
    prop: 'aChromeExtension',
    fid:  'gtn-roster-iframe-id',
    ec:   '["ci:ec",true,true,false]',
    pvt:  null,  # Populated later

module.exports = class Init

    constructor: ->

    initChat: (jarstore, pvt) ->
        params = clone CHAT_INIT_PARAMS
        params.pvt = pvt
        opts =
            method: 'GET'
            uri: CHAT_INIT_URL
            qs: params
            jar: request.jar jarstore
        req(opts).then (res) =>
            if res.statusCode == 200
                @parseBody res.body
            else
                log.warn 'init failed', res.statusCode, res.statusMessage
                Q.reject NetworkError.forRes(res)

    parseBody: (body) ->
        Q().then ->
            # the structure of the html body is (bizarelly):
            # <script>...</script>
            # <script>...</script>
            # <script>...</script>
            # <!DOCTYPE html><html>...</html>
            # <script>...</script>
            # <script>...</script>

            # first remove the <html> part
            html = body.replace /<!DOCTYPE html><html>(.|\n)*<\/html>/gm, ''

            # and then the <script> tags
            html = html.replace /<\/?script>/gm, ''

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
            DICT =
                apikey: { key:'ds:7',  fn: (d) -> d[0][2] }
                email:  { key:'ds:33', fn: (d) -> d[0][2] }
                headerdate:    { key:'ds:2', fn: (d) -> d[0][4] }
                headerversion: { key:'ds:2', fn: (d) -> d[0][6] }
                headerid:      { key:'ds:4', fn: (d) -> d[0][7] }
                timestamp:     { key:'ds:21', fn: (d) -> new Date (d[0][1][4] / 1000) }
                self_entity:   { key:'ds:20', fn: (d) ->
                    CLIENT_GET_SELF_INFO_RESPONSE.parse(d[0]).self_entity
                }
                conv_states: { key:'ds:19', fn: (d) ->
                    CLIENT_CONVERSATION_STATE_LIST.parse(d[0][3])
                }
                entities: { key:'ds:21', fn: (d) ->
                    INITIAL_CLIENT_ENTITIES.parse d[0]
                }

            for k, spec of DICT
                ent = find out.AF_initDataChunkQueue, (e) -> spec.key == e.key
                if ent
                    this[k] = d = spec.fn ent.data()
                    if d.length
                        log.debug 'init data count', k, d.length
                    else
                        log.debug 'init data', k, d
                else
                    log.warn 'no init data for', k

            # massage the entities
            entgroups = (@entities["group#{g}"].entities for g in [1..5])
            allents = map concat(@entities.entities, entgroups...), (e) -> e.entity
            # only keep real entities
            safe = allents.filter (e) -> e?.id?.gaia_id
            deduped = uniqfn safe, (e) -> e.id.gaia_id
            @entities = deduped

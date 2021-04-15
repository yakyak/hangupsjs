request = require 'request'
log     = require 'bog'
Q       = require 'q'
fs      = require 'fs'
syspath = require 'path'

InitDataParser = require './initdataparser'

{req, find, uniqfn, NetworkError} = require './util'

{CLIENT_GET_SELF_INFO_RESPONSE,
CLIENT_CONVERSATION_STATE_LIST,
INITIAL_CLIENT_ENTITIES} = require './schema'

CHAT_INIT_URL = 'https://hangouts.google.com/webchat/u/0/load'
CHAT_INIT_PARAMS =
    fid:  'gtn-roster-iframe-id',
    ec:   '["ci:ec",true,true,false]',
    pvt:  null,  # Populated later

module.exports = class Init

    constructor: (@proxy) ->
        @self_entity = []
        @conv_states = []

    initChat: (jarstore, pvt) ->
        log.debug 'initChat()'
        params = clone CHAT_INIT_PARAMS
        params.pvt = pvt
        opts =
            method: 'GET'
            uri: CHAT_INIT_URL
            qs: params
            jar: request.jar jarstore
            proxy: @proxy
            withCredentials: true
        self = @
        req(opts).then (res) =>
            if res.statusCode == 200
                @parseBody res.body
            else
                log.warn 'init failed', res.statusCode, res.statusMessage
                Q.reject NetworkError.forRes(res)

    parseBody: (body) ->
        DICT =
            apikey: { name:'cin:cac',  fn: (d) -> d[0][2] }
            email:  { name:'cic:vd', fn: (d) -> d[0][2] }
            headerdate:    { name:'cin:acc', fn: (d) -> d[0][4] }
            headerversion: { name:'cin:acc', fn: (d) -> d[0][6] }
            headerid:      { name:'cin:bcsc', fn: (d) -> d[0][7] }
            timestamp:     { name:'cgsirp', fn: (d) -> new Date (d[0][1][4] / 1000) }
            self_entity:   { name:'cgsirp', fn: (d) ->
                CLIENT_GET_SELF_INFO_RESPONSE.parse(d[0]).self_entity
            }
            conv_states: { name:'cgsirp', fn: (d) ->
                # Removed in server-side update
                CLIENT_CONVERSATION_STATE_LIST.parse(d[0][3])
            }

        await InitDataParser.parse body, DICT, this

        # massage the entities
        this.entgroups = []
        this.entities = undefined
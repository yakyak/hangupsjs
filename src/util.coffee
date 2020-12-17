request = require 'request'
Q       = require 'q'

#require('request-debug') request

find = curry (o, fn) ->
    arr = if Array.isArray(o) then o else values(o)
    return a for a in arr when fn(a)
    return null

plug = (rs, rj) -> (err, val) -> if err then rj(err) else rs(val)

class NetworkError extends Error
    constructor: (@code, @message, @body) -> super
NetworkError.forRes = (res) -> new NetworkError(res.statusCode, res.statusMessage, res.body)

req = (as...) -> Q.Promise (rs, rj) -> request as..., plug(rs, rj)

uniqfn = (as, fn) ->
    fned = map as, fn
    as.filter (v, i) -> index(fned, fned[i]) == i

wait = (time) -> Q.Promise (rs) -> setTimeout rs, time

tryparse = (str) -> try JSON.parse(str) catch err then null

fmterr = (err) -> err.code ? err.errno ? err.message ? String(err)

module.exports = {req, plug, find, uniqfn, wait, tryparse, NetworkError, fmterr}

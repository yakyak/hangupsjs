log = require 'bog'
require('fnuc').expose global

# A field can hold any value
class Field
    constructor: ->
        return new Field() unless this instanceof Field
    parse: (input) ->
        @value = if input == undefined then null else input

# An enum field can hold nothing or one of the
# values of a defined enumeration
class EnumField
    constructor: (enms) ->
        return new EnumField(enms) unless this instanceof EnumField
        @enms = enms
    parse: (input) ->
        return k for k, v of @enms when input == v
        return {}

class RepeatedField
    constructor: (field) ->
        return new RepeatedField(field) unless this instanceof RepeatedField
        console.trace() unless typeof field?.parse == 'function'
        @field = field
    parse: (input) ->
        return input unless input
        @field?.parse(a) for a in input

class Message
    # fields is array organised as
    # [name1, val1, name2, val2, name3, val3]
    constructor: (fields) ->
        return new Message(fields) unless this instanceof Message
        @fields = fields
    parse: (input) ->
        return null unless input
        input = input.toString() if input instanceof Buffer
        # we must eval since protojson is not proper json: [1,,""]
        input = eval input if typeis input, 'string'
        out = {}
        for a in [0...@fields.length] by 2
            val = input[a/2]
            k = @fields[a]
            v = @fields[a+1]
            out[k] = v.parse val if k
        out

module.exports = {Field, EnumField, RepeatedField, Message}

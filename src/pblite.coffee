log = require 'bog'
require('fnuc').expose global

# A field can hold any value
class Field
    constructor: ->
        return new Field() unless this instanceof Field
    parse: (input) ->
        @value = if input == undefined then null else input

# A boolean field that parses 0 or non-zero to false or true.
class BooleanField
    constructor: () ->
        return new BooleanField() unless this instanceof BooleanField
    parse: (input) ->
        @value = if input == undefined then false else if parseInt(input) == 0 then false else true

# An enum field can hold nothing or one of the
# values of a defined enumeration
class EnumField
    constructor: (enms) ->
        return new EnumField(enms) unless this instanceof EnumField
        @enms = enms
    parse: (input) ->
        return k for k, v of @enms when input == v
        return {}

class DictField
    constructor: (dict) ->
        return new DictField(dict) unless this instanceof DictField
        @dict = dict
    parse: (input) ->
        return null unless input
        return null if input == undefined
        input = input.toString() if input instanceof Buffer
        try
            obj = if typeis input, 'string' then eval input else input
        catch error
            log.error 'Problem with DICT field', input
            return @value = if input == undefined then null else input
        out = {}
        for prop, val of @dict
            out_prop = prop
            out_val = val
            if val.constructor == Array
                out_val = val[0]
                if val.length > 1
                    out_prop = val[1]
            out[out_prop] = out_val.parse obj[prop] if obj[prop]
        out

# A number field that parses a number or null on failure
class NumberField
    constructor: () ->
        return new NumberField() unless this instanceof NumberField
    parse: (input) ->
        @value = if not Number.isNaN (val = Number.parseInt input) then val else null

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

module.exports = {Field, BooleanField, EnumField, DictField, NumberField, RepeatedField, Message}

hangupsjs
=========

[![Build Status](https://travis-ci.org/algesten/hangupsjs.svg)](https://travis-ci.org/algesten/hangupsjs) [![Gitter](https://d378bf3rn661mp.cloudfront.net/gitter.svg)](https://gitter.im/algesten/hangupsjs)

## Summary

Client library for Google Hangouts in nodejs.

## Disclaimer

This library is in no way affiliated with or endorsed by Google. Use
at your own risk.

## Origins

Port of https://github.com/tdryer/hangups to node js.

I take no credit for the excellent work of Tom Dryer putting together
the original python client library for Google Hangouts. This port is
simply taking his work and porting it to coffeescript step by step.

The library is rather new and needs more tests, error handling etc.

## Usage

```
$ npm install hangupsjs
```

The client is started with `connect()` passing callback function for a
promise for a login object containing the credentials.

```coffee
Client = require 'hangupsjs'
Q      = require 'q'

creds = -> Q
    email: 'login@gmail.com'
    pass:  'mysecret'

client = new Client()

# set more verbose logging
client.loglevel 'debug'

# receive chat message events
client.on 'chat_message', (ev) ->
    console.log ev

client.connect(creds).then ->
    client.sendchatmessage('UgzJilj2Tg_oqk5EhEp4AaABAQ', [
        [0, 'Hello World']
    ])
.done()
```

## API

### High Level

High level API calls that are not doing direct hangouts calls.



#### `Client(opts)` constructor

`opts.cookiepath` (optional) path to store cached login cookies.



#### `connect: (creds) ->`

Attempts to connect the client to hangouts. See
[`isInited`](#isinited) for the steps that connects the client.
Returns a promise for connection. The promise only resolves when init
is completed. On the [`connected`](#connected) event.



#### `disconnect: ->`

Disconnects the client.



#### `isInited`

For Client to be fully inited the following must happen on
[`connect`](#connect):

1. Get login cookies against https://accounts.google.com/ServiceLogin
   or reuse cached cookies.

2. Using the cookies, fetch a PVT token (whatever that is) against
   https://talkgadget.google.com/talkgadget/_/extension-start

3. Load the chat widget HTML + javascript using the PVT token from
   https://talkgadget.google.com/u/0/talkgadget/_/chat

4. From the returned javascript get an `apikey` and some other headers
   used in each api call later.

5. Fetch channel `sid`/`gsid` from
   https://0.client-channel.google.com/client-channel/channel-bind

6. Using the `sid`/`gsid` open a long poll request against the same
   URL as in 5. This is the push data channel.

7. From first data coming through the push data channel, extract a
   `clientid` which also is used in each api call later.

8. Post a subscribe request against same URL as in 5 to make push data
   channel receive chat events.

Only after all these steps are completed will `isInited` return true.



#### `loglevel: (level) ->`

Sets the log level one of `debug`, `info`, `warn` or `error`.

### Low Level

Each API call does a direct operation against hangouts. Each call
returns a promise for the result.


#### `sendchatmessage: (conversation_id, segments, image_id=None, otr_status=OffTheRecordStatus.ON_THE_RECORD) ->`

Send a chat message to a conversation.

`conversation_id`: the conversation to send a message to.

`segments`: array of segments to send. See
[`messagebuilder`](#messagebuilder) for help.

`image_id`: (TODO) is an option ID of an image retrieved from
[`upload_image()`](#upload_image). If provided, the image will be
attached to the # message.

`otr_status`: determines whether the message will be saved in the
server's chat history. Note that the OTR status of the conversation is
irrelevant, clients may send messages with whatever OTR status they
like. One of `Client.OffTheRecordStatus.OFF_THE_RECORD` or
`Client.OffTheRecordStatus.ON_THE_RECORD`.

#### `setactiveclient: (active, timeoutsecs) ->`

The active client receives notifications. This marks the client as active.

`active`: boolean indicating active state

`timeoutsecs`: the length of active in seconds.



#### `syncallnewevents: (timestamp) ->`

List all events occuring at or after timestamp. Timestamp can be a
date or long millis.

`timestamp`: date instance specifying the time after which to return
all events occuring in.



#### `getselfinfo: ->`

Return information about your account.



#### `setfocus: (conversation_id) ->`

Set focus (occurs whenever you give focus to a client).

`conversation_id`: the conversation you are focusing.



#### `settyping: (conversation_id, typing=TypingStatus.TYPING) ->`

Send typing notification.

`conversation_id`: the conversation you want to send typing
notification for.

`typing`: constant indicating typing status. One of
`Client.TypingStatus.TYPING`, `Client.TypingStatus.PAUSED` or
`Client.TypingStatus.STOPPED`



#### `setpresence: (online, mood=None) ->`

Set the presence or mood of this client.

`online`: boolean indicating whether client is online.

`mood`: emoticon UTF-8 smiley like 0x1f603



#### `querypresence: (chat_id) ->`

Check someone's presence status.

`chat_id`: the identifer of the user to check.



#### `removeuser: (conversation_id) ->`

Remove self from chat.

`conversation_id`: the conversation to remove self from.



#### `deleteconversation: (conversation_id) ->`

Delete one-to-one conversation.

`conversation_id`: the conversation to delete.



#### `updatewatermark: (conversation_id, timestamp) ->`

Update the watermark (read timestamp) for a conversation.

`conversation_id`: the conversation to update the read timestamp for.

`timestamp`: the date or long millis to set as read timestamp.



#### `adduser: (conversation_id, chat_ids) ->`

Add user(s) to existing conversation.

`conversation_id`: the conversation to add user(s) to.

`chat_ids`: array of user chat_ids to add.



#### `renameconversation: (conversation_id, name) ->`

Set the name of a conversation.

`conversation_id`: the conversation to change.

`name`: the name to change to.



#### `createconversation: (chat_ids, force_group=false) ->`

Create a new conversation.

`chat_ids`: is an array of chat_id which should be invited to
conversation (except yourself).

`force_group`: set to true if you invite just one chat_id, but still
want a group.

The new conversation ID is returned as `res.conversation.id.id`



#### `getconversation: (conversation_id, timestamp, max_events=50) ->`

Return conversation events.

This is mainly used for retrieving conversation scrollback. Events
occurring before timestamp are returned, in order from oldest to
newest.

`conversation_id`: the conversation to get events in.

`timestamp`: the timestamp as long millis or date to get events
before.

`max_events`: number of events to retrieve.



#### `syncrecentconversations: ->`

List the contents of recent conversations, including messages.
Similar to syncallnewevents, but appears to return a limited number of
conversations (20) rather than all conversations in a given date
range.



#### `searchentities: (search_string, max_results=10) ->`

Search for people.

`search_string`: string to look for.

`max_results`: number of results to return.



#### `getentitybyid: (chat_ids) ->`

Return information about a list of chat_ids.

`chat_ids`: array of user chat ids to get information for.



#### `sendeasteregg: (conversation_id, easteregg) ->`

Send an easteregg to a conversation.

`conversation_id`: conversation to bother.

`easteregg`: may not be empty. could be one of 'ponies', 'pitchforks',
'bikeshed', 'shydino'

## Events




## License

Copyright © 2015 Martin Algesten

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
